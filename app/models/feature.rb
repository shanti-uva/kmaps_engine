# == Schema Information
#
# Table name: features
#
#  id                         :bigint           not null, primary key
#  ancestor_ids               :string
#  fid                        :integer          not null
#  is_blank                   :boolean          default(FALSE), not null
#  is_name_position_overriden :boolean          default(FALSE), not null
#  is_public                  :integer
#  old_pid                    :string
#  position                   :integer          default(0)
#  created_at                 :datetime
#  updated_at                 :datetime
#
# Indexes
#
#  features_ancestor_ids_idx  (ancestor_ids)
#  features_fid               (fid) UNIQUE
#  features_is_public_idx     (is_public)
#

class Feature < ActiveRecord::Base
  #attr_accessor :skip_update
  
  include FeatureExtensionForNamePositioning
  extend IsDateable
  
  validates_presence_of :fid
  validates_uniqueness_of :fid
  validates_numericality_of :position, allow_nil: true
    
  @@associated_models = [FeatureName, FeatureGeoCode, XmlDocument]
  
  # acts_as_solr fields: [:pid]
  
  acts_as_family_tree :node, -> { where(feature_relation_type_id: FeatureRelationType.hierarchy_ids) }, tree_class: 'FeatureRelation'
  acts_as_indexable #{ |f| ShantiIntegration::Indexer.trigger("uid:#{f.uid}") }
  
  # These are distinct from acts_as_family_tree's parent/child_relations, which only include hierarchical parent/child relations.
  has_many :affiliations, dependent: :destroy
  has_many :all_child_relations, class_name: 'FeatureRelation', foreign_key: 'parent_node_id', dependent: :destroy
  has_many :all_parent_relations, class_name: 'FeatureRelation', foreign_key: 'child_node_id', dependent: :destroy
  has_many :association_notes, as: :notable, dependent: :destroy
  has_many :cached_feature_names, dependent: :destroy
  has_many :captions, dependent: :destroy
  has_many :collections, through: :affiliations
  has_many :citations, as: :citable, dependent: :destroy
  has_one  :job, class_name: '::Delayed::Job', as: :reference, dependent: :destroy
  has_many :descriptions, dependent: :destroy
  has_many :essays, dependent: :destroy
  has_many :geo_codes, class_name: 'FeatureGeoCode', dependent: :destroy # naming inconsistency here (see feature_object_types association) ?
  has_many :geo_code_types, through: :geo_codes
  has_one  :illustration, -> { where(is_primary: true) }
  has_many :imports, as: 'item', dependent: :destroy
  has_many :summaries, dependent: :destroy
  has_one  :xml_document, class_name: 'XmlDocument', dependent: :destroy
  
  has_many :illustrations, dependent: :destroy do
    def primary_first
      order('is_primary DESC')
    end
  end
  
  # This fetches root *FeatureNames* (names that don't have parents),
  # within the scope of the current feature
  has_many :names, class_name: 'FeatureName', dependent: :destroy do
    #
    #
    #
    def roots
      # proxy_target, proxy_owner, proxy_reflection - See Rails "Association Extensions"
      pa = proxy_association
      pa.reflection.class_name.constantize.roots.where('feature_names.feature_id' => pa.owner.id) #.sort !!! See the FeatureName.<=> method
    end
    
    def recursive_roots_with_path
      res = []
      self.roots.order('position').collect{ |r| res += r.recursive_roots_with_path }
      res
    end
  end
  
  def parent_by_perspective(perspective)
    parent_relation = FeatureRelation.where(child_node_id: self.id, perspective_id: perspective.id, feature_relation_type_id: FeatureRelationType.hierarchy_ids).select(:parent_node_id).order(:created_at).first
    parent_relation.nil? ? nil : parent_relation.parent_node
  end
  
  def parents_by_perspective(perspective)
    parent_relations = FeatureRelation.where(child_node_id: self.id, perspective_id: perspective.id, feature_relation_type_id: FeatureRelationType.hierarchy_ids).select(:parent_node_id).order(:created_at)
    feature_ids = parent_relations.empty? ? [] : parent_relations.collect{ |pr| pr.parent_node_id }.uniq
    feature_ids.empty? ? [] : feature_ids.collect { |id| Feature.find(id) }
  end
    
  def closest_parent_by_perspective(perspective)
    feature_id = Rails.cache.fetch("features/#{self.fid}/closest_parent_by_perspective/#{perspective.id}", expires_in: 1.day) do
      parent_relation = FeatureRelation.where(child_node_id: self.id, perspective_id: perspective.id, feature_relation_type_id: FeatureRelationType.hierarchy_ids).select(:parent_node_id).order(:created_at).first
      break parent_relation.parent_node.id if !parent_relation.nil?
      parent_relation = FeatureRelation.where(child_node_id: self.id, perspective_id: perspective.id).select(:parent_node_id).order(:created_at).first
      break parent_relation.parent_node.id if !parent_relation.nil?
      parent_relation = FeatureRelation.where(child_node_id: self.id).select(:parent_node_id).order(:created_at).first
      break parent_relation.parent_node.id if !parent_relation.nil?
      nil
    end
    feature_id.nil? ? nil : Feature.find(feature_id)
  end
  
  def closest_parents_by_perspective(perspective)
    feature_ids = Rails.cache.fetch("features/#{self.fid}/closest_parents_by_perspective/#{perspective.id}", expires_in: 1.day) do
      parent_relations = FeatureRelation.where(child_node_id: self.id, perspective_id: perspective.id, feature_relation_type_id: FeatureRelationType.hierarchy_ids).select(:parent_node_id).order(:created_at)
      break parent_relations.collect{ |pr| pr.parent_node_id } if !parent_relations.empty?
      parent_relations = FeatureRelation.where(child_node_id: self.id, perspective_id: perspective.id).select(:parent_node_id).order(:created_at)
      break parent_relations.collect{ |pr| pr.parent_node_id } if !parent_relations.empty?
      parent_relations = FeatureRelation.where(child_node_id: self.id).select(:parent_node_id).order(:created_at)
      break parent_relations.collect{ |pr| pr.parent_node_id } if !parent_relations.empty?
      []
    end
    feature_ids.nil? ? [] : feature_ids.uniq.collect { |id| Feature.find(id) }
  end
  
  def closest_hierarchical_feature_id_by_perspective(perspective)
    Rails.cache.fetch("features/#{self.fid}/closest_hierarchical_feature_by_perspective/#{perspective.id}", expires_in: 1.day) do
      ancestor_ids = self.closest_ancestors_by_perspective(perspective).collect(&:id)
      root_ids = Feature.current_roots_by_perspective(perspective).collect(&:id)
      parent_id = (root_ids & ancestor_ids).first
      break root_ids.first if parent_id.nil?
      ancestor_ids.delete(parent_id)
      relation = FeatureRelation.find_by(perspective_id: perspective.id, parent_node_id: parent_id, child_node_id: ancestor_ids, feature_relation_type_id: FeatureRelationType.hierarchy_ids)
      while !relation.nil?
        ancestor_ids.delete(parent_id)
        parent_id = relation.child_node_id
        relation = FeatureRelation.find_by(perspective_id: perspective.id, parent_node_id: parent_id, child_node_id: ancestor_ids, feature_relation_type_id: FeatureRelationType.hierarchy_ids)
      end
      parent_id
    end
  end

  def ancestors_by_perspective(perspective)
    feature_ids = Rails.cache.fetch("features/#{self.fid}/ancestors_by_perspective/#{perspective.id}", expires_in: 1.day) do
      root_ids = Feature.current_roots_by_perspective(perspective).collect(&:id)
      pending = [[self, [self.id]]]
      goaled = nil
      while !pending.empty?
        current_with_path = pending.shift # Use shift for Breadth First Search. For Depth First Search use pop.
        current = current_with_path.first
        path = current_with_path.last
        if root_ids.include?(current.id)
          goaled = path
          break # Currenty getting shortest path. Comment second condition and turn goaled into an array to keep iterating in order to get all paths
        end
        parents = current.parents_by_perspective(perspective).reject{ |p| path.include?(p.id) }
        pending += parents.collect{ |p| [p, path + [p.id]] }
      end
      goaled.nil? ? [] : goaled.reverse
    end
    feature_ids.collect{|id| Feature.find(id)}
  end
  
  def closest_ancestors_by_perspective(perspective)
    feature_ids = Rails.cache.fetch("features/#{self.fid}/closest_ancestors_by_perspective/#{perspective.id}", expires_in: 1.day) do
      root_ids = Feature.current_roots_by_perspective(perspective).collect(&:id)
      pending = [[self, [self.id]]]
      goaled = nil
      while !pending.empty? && goaled.nil? # Currenty getting shortest path. Comment second condition and turn goaled into an array to keep iterating in order to get all paths
        current_with_path = pending.shift # Use shift for Breadth First Search. For Depth First Search use pop.
        current = current_with_path.first
        path = current_with_path.last
        if root_ids.include?(current.id)
          goaled = path
          break
        end
        parents = current.closest_parents_by_perspective(perspective).reject{ |p| path.include?(p.id) }
        pending += parents.collect{ |p| [p, path + [p.id]] }
      end
      goaled.nil? ? [] : goaled.reverse
    end
    feature_ids.collect{|fid| Feature.find(fid)}
  end

  #
  #
  #
  def current_children(current_perspective, current_view)
    return children.joins([{cached_feature_names: :feature_name}, :parent_relations]).where('cached_feature_names.view_id' => current_view.id).order('feature_names.name').select do |c| # children(include: [:names, :parent_relations])
      c.parent_relations.any? {|cr| cr.perspective==current_perspective}
    end
  end
  
  def descendants_by_perspective_with_parent(perspective)
    Feature.descendants_by_perspective_with_parent([self.fid], perspective)
  end
  
  def descendants_with_parent
    pending = [self]
    des = pending.collect{|f| [f, nil]}
    des_ids = pending.collect(&:id)
    while !pending.empty?
      e = pending.pop
      FeatureRelation.where(parent_node_id: e.id).each do |r|
        c = r.child_node
        if !des_ids.include? c.id
          des_ids << c.id
          des << [c, e, r]
          pending.push(c)
        end
      end
    end
    des
  end
  
  def recursive_descendants_with_depth(level = 0)
    res = [[self, level]]
    FeatureRelation.where(parent_node_id: self.id).joins(:child_node).order('features.position').each do |r|
      c = r.child_node
      res += c.recursive_descendants_with_depth(level+1)
    end
    res
  end
  
  def recursive_descendants_by_perspective_with_depth(perspective, level = 0)
    res = [[self, level]]
    FeatureRelation.where(parent_node_id: self.id, perspective_id: perspective.id).joins(:child_node).order('features.position').each do |r|
      c = r.child_node
      res += c.recursive_descendants_by_perspective_with_depth(perspective, level+1)
    end
    res
  end
  
  def all_descendants
    pending = [self]
    des = []
    des_ids = []
    while !pending.empty?
      e = pending.pop
      FeatureRelation.select('child_node_id').where(parent_node_id: e.id).each do |r|
        c = r.child_node
        if !des_ids.include? c.id
          des_ids << c.id
          des << c
          pending.push(c)
        end
      end
    end
    des
  end
  
  #
  #
  #
  def current_parent(current_perspective, current_view)
    current_parents(current_perspective, current_view).first
  end
  
  #
  #
  #
  def current_parents(current_perspective, current_view)
    return parents.joins(cached_feature_names: :feature_name).where('cached_feature_names.view_id' => current_view.id).order('feature_names.name').select do |c| # parents(include: [:names, :child_relations])
      c.child_relations.any? {|cr| cr.perspective==current_perspective}
    end
  end
  
  #
  #
  #
  def current_siblings(current_perspective, current_view)
    # if this feature doesn't have parent_relations, it's a root node. then return root nodes minus this feature
    # if thie feature DOES have parent relations, get the parent children, minus this feature
    (parent_relations.empty? ? self.class.current_roots(current_perspective, current_view) : current_parents(current_perspective, current_view).map(&:children).flatten.uniq) - [self]
  end
  
  #
  #
  #
  def current_ancestors(current_perspective)
    return ancestors.reverse.select do |c|
      c.child_relations.any? {|cr| cr.perspective==current_perspective}
    end
  end
  
  #
  # This is distinct from acts_as_family_tree's relations method, which only finds hierarchical child and parent relations.
  #
  def all_relations
    FeatureRelation.where(['child_node_id = ? OR parent_node_id = ?', id, id])
  end
      
  #
  #
  #
  def to_s
    self.name
  end
  
  #
  #
  #
  
  def pictures_url
    kmap_path('pictures')
  end

  def videos_url
    kmap_path('videos')
  end

  def documents_url
    kmap_path('documents')
  end
  
  #
  # Find all features that are related through a FeatureRelation
  #
  def related_features
    relations.collect{|relation| relation.parent_node_id == self.id ? relation.child_node : relation.parent_node}
  end
  
  def associated?
    @@associated_models.any?{|model| model.find_by(feature_id: self.id)} || !Shape.find_by(fid: self.fid).nil?
  end
  
  def association_notes_for(association_type, **options)
    conditions = {notable_type: self.class.name, notable_id: self.id, association_type: association_type, is_public: true}
    conditions.delete(:is_public) if !options[:include_private].nil? && options[:include_private] == true
    AssociationNote.where(conditions)
  end
    
  def clone_with_names
    new_feature = Feature.create(fid: Feature.generate_pid, is_blank: false, is_public: false, skip_update: true)
    names = self.names
    names_to_clones = Hash.new
    names.each do |name|
      cloned = name.dup
      cloned.feature = new_feature
      cloned.skip_update = true
      cloned.save
      names_to_clones[name.id] = cloned
    end
    relations = Array.new
    names.each { |name| name.relations.each { |relation| relations << relation if !relations.include? relation } }
    relations.each do |relation|
      new_relation = relation.dup
      new_relation.child_node = names_to_clones[new_relation.child_node.id]
      new_relation.parent_node = names_to_clones[new_relation.parent_node.id]
      new_relation.skip_update = true
      new_relation.save
    end
    new_feature.update_name_positions
    names.each{ |name| name.queued_update_hierarchy }
    return new_feature
  end
  
  def summary
    current_language = Language.current
    current_language.nil? ? nil : self.summaries.find_by(language_id: current_language.id)
  end
  
  def caption
    current_language = Language.current
    current_language.nil? ? nil : self.captions.find_by(language_id: current_language.id)
  end
  
  def affiliations_by_user(user, **options)
    Affiliation.where(**options.merge(feature_id: self.id, collection_id: user.collections.collect(&:id)))
  end
  
  def authorized?(user, **options)
    !affiliations_by_user(user, **options).empty?
  end
  
  def authorized_for_descendants?(user)
    !affiliations_by_user(user, descendants: true).empty?
  end
  
  # Override uid to use fid instead of id
  def uid
    Feature.uid(self.fid)
  end
  
  def uid_i
    Feature.uid_i(self.fid)
  end

  def related_features_count
    response = Feature.search_by("{!child of=block_type:parent}id:#{self.uid}", group: true,
      'group.field': 'block_child_type', 'group.limit': 0)['grouped']['block_child_type']
    response['matches'] > 0 ? response['groups'].select{|group| group['groupValue'] == "related_#{Feature.uid_prefix}"}.first['doclist']['numFound'] : 0
  end
  
  def related_features_counts
    full_response = Feature.search_by("{!child of=block_type:parent}id:#{self.uid}", group: true,
                                 'group.field': 'block_child_type', 'group.limit': 0,
                                 facet: true, 'facet.field': 'related_kmaps_node_type')
    response = full_response['grouped']['block_child_type']
    facet_response = full_response['facet_counts']['facet_fields']['related_kmaps_node_type']
    facet_hash = facet_response.each_slice(2).to_a.to_h
    related_features = 0
    if response['matches'] > 0
      response_related = response['groups'].select{|group| group['groupValue'] == "related_#{Feature.uid_prefix}"}.first
      related_features = response_related['doclist']['numFound'] if !response_related.nil?
    end
    { related_features: related_features,
      parents:          facet_hash['parent'],
      children:         facet_hash['child'] }
  end
  
  def self.associated_models
    @@associated_models
  end
  
  #
  #
  #
  def self.current_roots(current_perspective, current_view)
    feature_ids = Rails.cache.fetch("features/current_roots/#{current_perspective.id if !current_perspective.nil?}/#{current_view.id if !current_view.nil?}", expires_in: 1.day) do
      joins(cached_feature_names: :feature_name).where(is_blank: false, cached_feature_names: {view_id: current_view.id}).order('feature_names.name').roots.find_all do |r|
#      self.joins(cached_feature_names: :feature_name).where(is_blank: false, cached_feature_names: {view_id: current_view.id}).order('feature_names.name').scoping do
 #       roots.find_all do |r|
          # if ANY of the child relations are current, return true to nab this Feature
        r.child_relations.any? {|cr| cr.perspective==current_perspective }
      end.collect(&:id)
    #  end
    end
    feature_ids.collect{ |fid| Feature.find(fid) }.sort_by{ |f| [f.position, f.prioritized_name(current_view).name] }
  end

  def self.current_roots_by_perspective(current_perspective)
    return super if defined?(super)
    feature_ids = Rails.cache.fetch("features/current_roots/#{current_perspective.id}", expires_in: 1.day) do
      self.where('features.is_blank' => false).scoping do
        self.roots.select do |r|
          # if ANY of the child relations are current, return true to nab this Feature
          r.child_relations.any? {|cr| cr.perspective==current_perspective }
        end
      end.collect(&:id)
    end
    feature_ids.collect{ |fid| Feature.find(fid) }
  end
  
  # currently only option accepted is 'only_hierarchical'
  def self.descendants_with_parent(fids)
    pending = fids.collect{|fid| Feature.get_by_fid(fid)}
    des = pending.collect{|f| [f, nil]}
    des_ids = pending.collect(&:id)
    while !pending.empty?
      e = pending.pop
      FeatureRelation.where(parent_node_id: e.id).each do |r|
        c = r.child_node
        if !des_ids.include? c.id
          des_ids << c.id
          des << [c, e, r]
          pending.push(c)
        end
      end
    end
    des
  end
  
  def self.recursive_descendants_with_depth(fids)
    res = []
    fids.each do |fid|
      f = Feature.get_by_fid(fid)
      res += f.recursive_descendants_with_depth
    end
    res
  end
  
  def self.recursive_descendants_by_perspective_with_depth(fids, perspective)
    res = []
    fids.each do |fid|
      f = Feature.get_by_fid(fid)
      res += f.recursive_descendants_by_perspective_with_depth(perspective)
    end
    res
  end
  
  # currently only option accepted is 'only_hierarchical'
  def self.descendants_by_perspective_with_parent(fids, perspective, **options)
    pending = fids.collect{|fid| Feature.get_by_fid(fid)}
    des = pending.collect{|f| [f, nil]}
    des_ids = pending.collect(&:id)
    conditions = {perspective_id: perspective.id}
    conditions[:feature_relation_type_id] = FeatureRelationType.hierarchy_ids if options[:only_hierarchical]
    while !pending.empty?
      e = pending.pop
      conditions[:parent_node_id] = e.id
      FeatureRelation.where(conditions).each do |r|
        c = r.child_node
        if !des_ids.include? c.id
          des_ids << c.id
          des << [c, e, r]
          pending.push(c)
        end
      end
    end
    des
  end
  
  def self.generate_pid
    KmapsEngine::FeaturePidGenerator.next
  end
  
  #
  # given a "context_id" (Feature.id), this method only searches
  # the context's descendants. It returns an array
  # where the first element is the context Feature
  # and the second element is the collection of matching descendants.
  #
  # context_id - the id of a Feature
  # filter - any string filter value
  # options - the standard find(:all) options
  #
  def self.contextual_search(string_context_id, filter, **search_options)
    context_id = string_context_id.to_i # for some reason this parameter has been especially susceptible to SQL injection attack payload
    results = self.search(filter, search_options)
    results = results.where(['(features.id = ? OR features.ancestor_ids LIKE ?)', context_id, "%.#{context_id}.%"]) if !context_id.blank?

    # the context feature might not be returned
    # use detect to find a feature.id match against the context_id
    # if it isn't found, just do a standard find:
    context_feature = results.detect {|i| i.id.to_s==context_id} || find(context_id) rescue nil
    [context_feature, results]
  end
  
  # 
  # A basic search method that uses a single value for filtering on multiple columns
  # filter_value is used as the value to filter on
  # options - the standard arguments sent to ActiveRecord::Base.paginate (WillPaginate gem)
  # See http://api.rubyonrails.com/classes/ActiveRecord/Base.html#M001416
  # 
  def self.search(search)
    # Setup the base rules
    if search.scope && search.scope == 'name'
      conditions = build_like_conditions(%W(feature_names.name), search.filter, match: search.match)
      joins = [:names]
    else
      conditions = build_like_conditions(%W(descriptions.content feature_names.name), search.filter, match: search.match)
      joins = [:names, :descriptions]
    end
    if !conditions.blank?
      fid = search.filter.gsub(/[^\d]/, '')
      if !fid.blank?
        conditions[0] << ' OR features.fid = ?'
        conditions << fid.to_i
      end
    end
    search_results = self.where(conditions).joins(joins).order('features.position').distinct
    search_results = search_results.where('descriptions.content IS NOT NULL') if search.has_descriptions
    return search_results
  end
  
  def self.name_search(filter_value)
    Feature.joins(:names).where(['features.is_public = ? AND feature_names.name ILIKE ?', 1, "%#{filter_value}%"]).order('features.position')
  end
  
  def self.blank
    Feature.all.reject{|f| f.associated? }
  end
  
  def self.associated
    Feature.all.select{|f| f.associated? }
  end
  
  def self.get_by_fid(fid)
    key = "features-fid/#{fid}"
    feature_id = Rails.cache.fetch(key, expires_in: 1.day) do
      feature = self.find_by(fid: fid)
      feature.nil? ? nil : feature.id
    end
    # TODO: this won't be necessary when upgrading to rails 6.0 using skip_nil
    if feature_id.nil?
      Rails.cache.delete(key)
      return nil
    else
      return Feature.find(feature_id)
    end
  end
  
  def self.uid(fid)
    "#{self.uid_prefix}-#{fid}"
  end
  
  def self.uid_i(fid)
    fid*100 + Feature.uid_code
  end
  
  def self.solr_filename(fid)
    "#{fid}.json"
  end
  
  def self.blank_document_for_rsolr(fid)
    doc = { id: self.uid(fid), uid_i: self.uid_i(fid), deleted_b: true }
  end
  
  
  def feature
    self
  end
  
  def solr_url
    URI.join(Feature.solr_url.to_s, solr_filename)
  end
  
  def solr_filename
    Feature.solr_filename(self.fid)
  end
  
  def document_for_rsolr
    doc = defined?(super) ? super : nested_documents_for_rsolr
    v = View.get_by_code(KmapsEngine::ApplicationSettings.default_view_code)
    doc[:id] = self.uid
    doc[:uid_i] = self.uid_i
    name = self.prioritized_name(v)
    doc[:header] = name.nil? ? self.pid : name.name
    doc[:position_i] = self.position
    doc[:projects_ss] = self.affiliations.collect{ |a| a.collection.code }
    time_units = self.time_units_ordered_by_date.collect { |t| t.to_s }
    doc[:time_units_ss] = time_units if !time_units.blank?
    self.captions.each do |c|
      if doc["caption_#{c.language.code}"].blank?
        doc["caption_#{c.language.code}"] = [c.content]
      else
        doc["caption_#{c.language.code}"] << c.content
      end
      doc["caption_#{c.language.code}_#{c.id}_content_t"] = c.content
      citations = c.citations
      citation_references = citations.collect { |ci| ci.bibliographic_reference }
      doc["caption_#{c.language.code}_#{c.id}_citation_references_ss"] = citation_references if !citation_references.blank?
      citations.each{ |ci| ci.rsolr_document_tags_for_notes(doc, "caption_#{c.language.code}_#{c.id}") }
    end
    mandala_text_mapping = Language.mandala_text_mappings.invert
    self.essays.each do |e|
      doc["homepage_text_#{mandala_text_mapping[e.language.id]}_s"] = e.text_id
    end
    self.summaries.each do |s|
      if doc["summary_#{s.language.code}"].blank?
        doc["summary_#{s.language.code}"] = [s.content]
      else
        doc["summary_#{s.language.code}"] << s.content
      end
      doc["summary_#{s.language.code}_#{s.id}_content_t"] = s.content
      citations = s.citations
      citation_references = citations.collect { |c| c.bibliographic_reference }
      doc["summary_#{s.language.code}_#{s.id}_citation_references_ss"] = citation_references if !citation_references.blank?
      citations.each{ |ci| ci.rsolr_document_tags_for_notes(doc, "summary_#{s.language.code}_#{s.id}") }
    end
    ils = self.illustrations.primary_first
    if !ils.blank?
      doc[:illustrations_images_thumb_ss] = ils.collect(&:thumb_url)
      doc[:illustrations_images_uid_ss] = ils.collect(&:picture_uid)
    end
    doc[:created_at] = self.created_at.utc.iso8601
    doc[:updated_at] = self.updated_at.utc.iso8601
    Perspective.where(is_public: true).each do |p|  #['cult.reg', 'pol.admin.hier'].collect{ |code| Perspective.get_by_code(code) }
      tag = 'ancestors_'
      id_tag = 'ancestor_ids_'
      uid_tag = 'ancestor_uids_'
      hierarchy = self.ancestors_by_perspective(p)
      if hierarchy.blank?
        hierarchy = self.closest_ancestors_by_perspective(p)
        doc["ancestor_id_closest_#{p.code}_path"] = hierarchy.collect(&:fid).join('/')
        doc["level_closest_#{p.code}_i"] = hierarchy.size
        tag << 'closest_'
        id_tag << 'closest_'
        uid_tag << 'closest_'
        closest_fid = self.closest_hierarchical_feature_id_by_perspective(p)
        closest_ancestor_in_tree = closest_fid.nil? ? nil : Feature.find(closest_fid)
        path = closest_ancestor_in_tree.nil? ? [] : closest_ancestor_in_tree.ancestors_by_perspective(p).collect(&:fid)
      else
        path = hierarchy.collect(&:fid)
        doc["level_#{p.code}_i"] = path.size
      end
      tag << p.code
      id_tag << p.code
      uid_tag << p.code
      doc["ancestor_id_#{p.code}_path"] = path.join('/')
      doc[tag] = hierarchy.collect do |f|
        pn = f.prioritized_name(v)
        pn.nil? ? f.fid : pn.name
      end
      doc[id_tag] = hierarchy.collect{ |f| f.fid }
      doc[uid_tag] = hierarchy.collect{ |f| f.uid }
    end
    #name_ids = []
    #names = self.names
    #names.each do |name|
    View.all.each do |v|
      name = self.prioritized_name(v)
      if !name.nil? #&& !name_ids.include?(name.id)
        #name_ids << name.id
        key_arr = ['name', v.code] #name.language.code]
        #rel_code = name.relationship_code
        #key_arr << rel_code if !rel_code.nil?
        #ws = name.writing_system
        #key_arr << ws.code if !ws.nil?
        key_str = key_arr.join('_')
        #if doc[key_str].blank?
          doc[key_str] = [name.name.s]
        #else
          #doc[key_str] << name.name
        #end
      end
    end
    names = self.names
    names.select(:writing_system_id).distinct.collect(&:writing_system).each do |w|
      next if w.nil?
      key_arr = ['name', w.code] #name.language.code]
      key_str = key_arr.join('_')
      names.where(writing_system: w).each do |name|
        if doc[key_str].blank?
          doc[key_str] = [name.name]
        else
          doc[key_str] << name.name
        end
      end
    end
    geo_codes = self.geo_codes
    geo_codes.each do |c|
      doc["code_#{c.geo_code_type.code}_value_s"] = c.geo_code_value
      citations = c.citations
      citation_references = citations.collect { |c| c.bibliographic_reference }
      doc["code_#{c.geo_code_type.code}_citation_references_ss"] = citation_references if !citation_references.blank?
      citations.each{ |ci| ci.rsolr_document_tags_for_notes(doc, "code_#{c.geo_code_type.code}") }
      time_units = c.time_units_ordered_by_date.collect { |t| t.to_s }
      doc["code_#{c.geo_code_type.code}_time_units_ss"] = time_units if !time_units.blank?
      c.notes.each { |n| n.rsolr_document_tags(doc, "code_#{c.geo_code_type.code}") }
    end
    child_documents = doc['_childDocuments_']
    name_documents = names.recursive_roots_with_path.collect do |np|
      name = np.first
      path = np.second
      uid = "#{FeatureName.uid_prefix}-#{name.id}"
      writing_system = name.writing_system
      prefix = "related_#{FeatureName.uid_prefix}"
      child_document =
      { id: "#{self.uid}_#{uid}",
        origin_uid_s: self.uid,
        block_child_type: ["related_names"],
        #tree: FeatureName.uid_prefix,
        "#{prefix}_id_s" => uid,
        "#{prefix}_header_s" => name.name,
        "#{prefix}_path_s" => path.join('/'),
        "#{prefix}_level_i" => path.size,
        "#{prefix}_language_s" => name.language.name,
        "#{prefix}_relationship_s" => name.pp_display_string,
        block_type: ['child']
      }
      citations = name.citations
      citation_references = citations.collect { |c| c.bibliographic_reference }
      child_document["#{prefix}_citation_references_ss"] = citation_references if !citation_references.blank?
      citations.each{ |ci| ci.rsolr_document_tags_for_notes(child_document, prefix) }
      time_units = name.time_units_ordered_by_date.collect { |t| t.to_s }
      child_document["#{prefix}_time_units_ss"] = time_units if !time_units.blank?
      name.notes.each { |n| n.rsolr_document_tags(child_document, prefix) }
      name.parent_relations.each do |r|
        next if r.nil?
        citations = r.citations
        citation_references = citations.collect { |c| c.bibliographic_reference }
        child_document["#{prefix}_relationship_#{r.id}_citation_references_ss"] = citation_references if !citation_references.blank?
        citations.each{ |ci| ci.rsolr_document_tags_for_notes(child_document, "#{prefix}_relationship_#{r.id}") }
        r.notes.each { |n| n.rsolr_document_tags(child_document, "#{prefix}_relationship_#{r.id}") }
      end
      etymology = name.etymology
      child_document["#{prefix}_etymology_s"] = etymology if !etymology.blank?
      if !writing_system.nil?
        child_document["#{prefix}_writing_system_s"] = writing_system.name
        child_document["#{prefix}_writing_system_code_s"] = writing_system.code
      end
      child_document
    end
    child_documents += name_documents
    doc['_childDocuments_'] = child_documents
    doc
  end
  
  def skip_update=(value)
    @skip_update=value
    Rails.cache.write("features/#{self.fid}/skip_update", @skip_update, expires_in: 1.hour)
  end

  def skip_update
    Rails.cache.fetch("features/#{self.fid}/skip_update", expires_in: 1.hour) do
      if defined?(@skip_update)
        @skip_update
      else
        @skip_update = false
      end
    end
  end
  
  private
  
  def nested_documents_for_rsolr
    per = Perspective.get_by_code(KmapsEngine::ApplicationSettings.default_perspective_code)
    v = View.get_by_code(KmapsEngine::ApplicationSettings.default_view_code)
    hierarchy = self.closest_ancestors_by_perspective(per)
    prefix = "related_#{Feature.uid_prefix}"
    doc = { tree: Feature.uid_prefix,
      block_type: ['parent'],
      '_childDocuments_'  =>  self.all_parent_relations.collect do |pr|
        name = pr.parent_node.prioritized_name(v)
        name_str = name.nil? ? pr.parent_node.pid : name.name
        parent = pr.parent_node
        relation_type = pr.feature_relation_type
        relation_tag = { id: "#{self.uid}_#{relation_type.code}_#{parent.fid}",
          related_uid_s: parent.uid,
          origin_uid_s: self.uid,
          block_child_type: [prefix],
          "#{prefix}_id_s" => parent.uid,
          "#{prefix}_header_s" => name_str,
          "#{prefix}_path_s" => pr.parent_node.closest_ancestors_by_perspective(per).collect(&:fid).join('/'),
          "#{prefix}_relation_label_s" => relation_type.is_symmetric ? relation_type.label : relation_type.asymmetric_label,
          "#{prefix}_relation_code_s" => relation_type.code,
          related_kmaps_node_type: 'parent',
          block_type: ['child']
        }
        citations = pr.citations
        p_rel_citation_references = citations.collect { |c| c.bibliographic_reference }
        relation_tag["#{prefix}_relation_citation_references_ss"] = p_rel_citation_references if !p_rel_citation_references.blank?
        citations.each{ |ci| ci.rsolr_document_tags_for_notes(relation_tag, "#{prefix}_relation") }
        time_units = pr.time_units_ordered_by_date.collect { |t| t.to_s }
        relation_tag["#{prefix}_relation_time_units_ss"] = time_units if !time_units.blank?
        pr.notes.each { |n| n.rsolr_document_tags(relation_tag, prefix) }
        relation_tag
      end + self.all_child_relations.collect do |pr|
        name = pr.child_node.prioritized_name(v)
        name_str = name.nil? ? pr.child_node.pid : name.name
        child = pr.child_node
        relation_type = pr.feature_relation_type
        code = relation_type.is_symmetric ? relation_type.code : relation_type.asymmetric_code
        relation_tag = { id: "#{self.uid}_#{code}_#{child.fid}",
          related_uid_s: child.uid,
          origin_uid_s: self.uid,
          block_child_type: [prefix],
          "#{prefix}_id_s" => "#{Feature.uid_prefix}-#{child.fid}",
          "#{prefix}_header_s" => name_str,
          "#{prefix}_path_s" => pr.child_node.closest_ancestors_by_perspective(per).collect(&:fid).join('/'),
          "#{prefix}_relation_label_s" => relation_type.label,
          "#{prefix}_relation_code_s" => code,
          related_kmaps_node_type: 'child',
          block_type: ['child']
        }
        citations = pr.citations
        p_rel_citation_references = citations.collect { |c| c.bibliographic_reference }
        relation_tag["#{prefix}_relation_citation_references_ss"] = p_rel_citation_references if !p_rel_citation_references.blank?
        citations.each{ |ci| ci.rsolr_document_tags_for_notes(relation_tag, "#{prefix}_relation") }
        time_units = pr.time_units_ordered_by_date.collect { |t| t.to_s }
        relation_tag["#{prefix}_relation_time_units_ss"] = time_units if !time_units.blank?
        pr.notes.each { |n| n.rsolr_document_tags(relation_tag, prefix) }
        relation_tag
      end }
    doc
  end
  
  def self.name_search_options(filter_value, **options)
  end
  
  ActiveSupport.run_load_hooks(:feature, Feature)
end
