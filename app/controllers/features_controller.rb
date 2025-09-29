class FeaturesController < ApplicationController
  allow_unauthenticated_access
  caches_page :show, :if => Proc.new { |c| c.request.format.xml? || c.request.format.json? || c.request.format.csv? }
  #
  def index
    @feature = Feature.find(session['interface']['context_id']) unless session['interface'].blank? || session['interface']['context_id'].blank?
    @tab_options = {:entity => @feature}
    @current_tab_id = :home
    
    # In the event that a Blurb with this code doesn't exist, fail gracefully
    @intro_blurb = KmapsEngine::ApplicationSettings.homepage_blurb || Blurb.new
        
    respond_to do |format|
      format.html { update_perspective }
      format.js
      format.xml  #{ render :xml => Feature.current_roots(Perspective.get_by_code(default_perspective_code), View.get_by_code(default_view_code)).to_xml }
      format.json { render json: Hash.from_xml(render_to_string(action: 'index', format: 'xml')) }
    end
  end

  #
  #
  #
  def show
    @feature = Feature.get_by_fid(params[:id])
    respond_to do |format|
      format.html do
        if @feature.nil?
          redirect_to features_url
        else
          session['interface']['context_id'] = @feature.id unless @feature.nil?
          update_perspective
          @tab_options = {:entity => @feature}
          @current_tab_id = :place
        end
      end
      format.xml { render plain: '' if @feature.nil? }
      format.csv do
        @features_with_parents = @feature.descendants_with_parent
      end
      format.js
      format.json { render json: Hash.from_xml(render_to_string(action: 'show', format: 'xml')) }
      # use @feature.document_for_rsolr.to_json to get json designed for solr. Make sure document_for_rsolr is not private!
    end
  end

  #
  #
  #
  def iframe
    @feature = Feature.find(params[:id])
    render :action => 'iframe', :layout => 'iframe'
  end
  
  def by_geo_code
    geo_code_type_str = params[:geo_code_type]
    geo_code_type = GeoCodeType.get_by_code(geo_code_type_str)
    @feature = nil
    if !geo_code_type.nil?
      geo_code = FeatureGeoCode.find_by(geo_code_type_id: geo_code_type.id, geo_code_value: params[:geo_code])
      @feature = geo_code.feature if !geo_code.nil?
    end
    respond_to do |format|
      format.html { render :action => 'show' }
    end
  end
    
  #
  #
  #
  def by_fid
    feature_array = params[:fids].split(/\D+/)
    feature_array.shift if feature_array.size>0 && feature_array.first.blank?
    @features =  feature_array.collect{|feature_id| Feature.get_by_fid(feature_id.to_i)}.find_all{|f| f && f.is_public==1}
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    respond_to do |format|
      format.html { render action: 'staff_show' }
      format.xml  { render action: 'index' }
      format.json { render json: Hash.from_xml(render_to_string(action: 'index', format: 'xml')), callback: params[:callback] }
    end
  end

  #
  #
  #
  def by_old_pid
    @features = params[:old_pids].split(/\D+/).find_all{|p| p && !p.blank?}.collect{|p| Feature.find_by(old_pid: "f#{p}")}.find_all{|f| f}
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    respond_to do |format|
      format.html { render action: 'staff_show' }
      format.xml  { render action: 'index' }
      format.json { render json: Hash.from_xml(render_to_string(action: 'index', format: 'xml')), callback: params[:callback] }
    end
  end
  
  def by_name
    search = Search.new(filter: params[:query], scope: params[:scope] || 'name', match: params[:match])
    conditions = {:is_public => 1}
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    @view ||= View.get_by_code(default_view_code)
    joins = []
    if !params[:feature_type].blank?
      joins << "LEFT JOIN cumulative_category_feature_associations ccfa ON ccfa.feature_id = features.id"
      conditions['ccfa.category_id'] = params[:feature_type].split(',')
      conditions['features.is_public'] = 1
      conditions.delete(:is_public)
    end
    if !params[:characteristic_id].blank?
      joins << "LEFT JOIN category_features cf ON cf.feature_id = features.id"
      conditions['cf.category_id'] = params[:characteristic_id].split(',')
      conditions['cf.type'] = nil
      conditions['features.is_public'] = 1
      conditions.delete(:is_public)
    end
    @features = perform_global_search(search).where(conditions).paginate(:page => params[:page] || 1, :per_page => params[:per_page] || 15)
    @features = @features.joins(joins.join(' ')).select('features.*, DISTINCT feature.id') unless joins.empty?
    respond_to do |format|
      format.html { render :action => 'paginated_show' }
      format.xml  { render :action => 'paginated_show' }
      format.json do
        render json: Hash.from_xml(render_to_string(action: 'paginated_show', format: 'xml')), callback: params[:callback]
      end
    end
  end

  # params accepted: name, summary, caption, descriptions, view_code, callback
  def by_fields
    match = params[:query]
    if match.blank?
      @features = Feature.where('FALSE').paginate(:page => 1, :per_page => 1)
    else
      accepted_fields = {:name =>        {:model => :names       , :field => 'feature_names.name'},
                         :summary =>     {:model => :summaries   , :field => 'summaries.content'},
                         :caption =>     {:model => :captions    , :field => 'captions.content'},
                         :description => {:model => :descriptions, :field => 'descriptions.content'}}
      params[:name] ||= '1'
      params[:id] ||= '0'
      accepted_fields.each_key{|param| params[param] ||= '0' }
      conditions_array = []
      params_array = []
      joins = []
      if params[:id] == '1' && match.to_i.to_s == match
        conditions_array << ['features.fid = ?']
        params_array << [match.to_i]
      end
      @features = Feature.where(:is_public => 1).paginate(:page => params[:page] || 1, :per_page => params[:per_page] || 15)
      accepted_fields.each_pair do |param, param_hash|
        if params[param]=='1'
          joins << param_hash[:model]
          conditions_array << "#{param_hash[:field]} ILIKE ?"
        end
      end
      if !conditions_array.empty?
        @features = @features.select('features.*, DISTINCT feature.id').includes(joins).references(joins) if !joins.empty?
        @features = @features.where([conditions_array.join(' OR ')] + params_array + Array.new(joins.size, "%#{match}%"))
      end
    end
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    @view ||= View.get_by_code(default_view_code)
    
    respond_to do |format|
      format.html { render :action => 'paginated_show' }
      format.xml  { render :action => 'paginated_show' }
      format.json do
        h = Hash.from_xml(render_to_string(action: 'paginated_show', format: 'xml'))
        h[:page] = params[:page] || 1
        h[:total_pages] = @features.total_pages
        render :json => h, :callback => params[:callback]
      end
    end
  end
    
  def children
    feature = Feature.get_by_fid(params[:id])
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    @view ||= View.get_by_code(default_view_code)
    perspective = params[:perspective_code].nil? ? nil : Perspective.get_by_code(params[:perspective_code])
    if perspective.nil?
      @features = feature.children.sort_by{|f| [f.position, f.prioritized_name(@view).name] }
    else
      @features = feature.current_children(perspective, @view).sort_by{|f| [f.position, f.prioritized_name(@view).name]}
    end
    respond_to do |format|
      format.xml
      format.json { render json: Hash.from_xml(render_to_string(action: 'children', format: 'xml')) }
    end
  end
  
  def list
    params_id = params[:id]
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    @view ||= View.get_by_code(default_view_code)
    if params_id.nil?
      @features = Feature.where(:is_public => 1).sort_by do |f|
        n = f.prioritized_name(@view)
        [f.position, n.nil? ? f.pid : n.name]
      end
    else
      feature = Feature.get_by_fid(params_id)
      @features = feature.descendants.sort_by do |f|
        n = f.prioritized_name(@view)
        [f.position, n.nil? ? f.pid : n.name]
      end
    end
    respond_to do |format|
      format.xml
      format.json { render json: Hash.from_xml(render_to_string(action: 'list', format: 'xml')) }
    end
  end
  
  def all
    params_id = params[:id]
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    @view ||= View.get_by_code(default_view_code)
    if params_id.nil?
      @features = Feature.current_roots(Perspective.get_by_code(default_perspective_code), @view)
    else
      @feature = Feature.get_by_fid(params_id)
    end
    respond_to do |format|
      format.xml { render 'all_collection' if params_id.nil? }
      format.json { render json: Hash.from_xml(render_to_string(action: params_id.nil? ? 'all_collection' : 'all', format: 'xml')) }
    end
  end
  
  def nested
    params_id = params[:id]
    @view = params[:view_code].nil? ? nil : View.get_by_code(params[:view_code])
    @view ||= View.get_by_code(default_view_code)
    @perspective = params[:perspective_code].nil? ? nil : Perspective.get_by_code(params[:perspective_code])
    @perspective ||= Perspective.get_by_code(default_perspective_code)
    if params_id.nil?
      @features = Feature.current_roots(@perspective, @view).sort_by{ |f| [f.position, f.prioritized_name(@view).name] }
    else
      @feature = Feature.get_by_fid(params_id)
    end
    respond_to do |format|
      format.xml { render 'nested_collection' if params_id.nil? }
      format.json { render json: Hash.from_xml(render_to_string(action: params_id.nil? ? 'nested_collection' : 'nested', format: 'xml')) }
    end
  end
  
  def descendants
    fids = params[:id].split(/\D+/)
    perspective_code = params[:perspective_code]
    perspective = perspective_code.blank? ? nil : Perspective.get_by_code(perspective_code)
    if fids.size == 1
      feature = Feature.get_by_fid(fids.first)
      @features_with_parents = perspective.nil? ? feature.recursive_descendants_with_depth : feature.recursive_descendants_by_perspective_with_depth(perspective)
    else
      @features_with_parents = perspective.nil? ? Feature.recursive_descendants_with_depth(fids) : Feature.recursive_descendants_by_perspective_with_depth(fids, perspective)
    end
    view_codes_str = params[:view_code]
    view_codes = view_codes_str.blank? ? [] : view_codes_str.split(',')
    if view_codes.empty?
      @view = current_view
    else
      @view = view_codes.collect{ |code| View.get_by_code(code) }
      @view = @view.first if @view.size==1
    end
    respond_to do |format|
      format.txt
    end
  end
  
  def related
    @feature = Feature.get_by_fid(params[:id])
    if @feature.nil?
      redirect_to features_url
    else
      session['interface']['context_id'] = @feature.id unless @feature.nil?
      @tab_options = {:entity => @feature}
      @current_tab_id = :related
    end
    respond_to do |format|
      format.html
      format.xml
      format.js
      format.json { render json: Hash.from_xml(render_to_string(action: 'related', format: 'xml')) }
    end
  end
  
  # The following three methods are used with the Node Tree
  def expanded
    @node = Feature.find(params[:id])
    respond_to do |format|
      format.html { redirect_to @node }
      format.js   { @ancestors = (@node.current_ancestors(current_perspective).collect(&:id) + [@node.id.to_s]).join(',') } # response would be handled by expanded.js.erb
    end
  end

  def contracted
    @node = Feature.find(params[:id])
    redirect_to(feature_url(@node)) if !request.xhr?
    # response would be handled by contracted.js.erb
  end
  
  def node_tree_expanded
    view = current_view
    node = Feature.find(params[:id])
    # @ancestors_for_current = node.closest_ancestors_by_perspective(current_perspective).collect{|a| a.id}
    @ancestors_for_current = node.current_ancestors(current_perspective).collect(&:id)
    @ancestors_for_current << node.id
    top_level_nodes = Feature.current_roots(current_perspective, view).sort_by{ |f| [f.position, f.prioritized_name(view).name] }
    render :partial => 'node_tree', :locals => { :children => top_level_nodes }, :layout => false
  end
      
  def set_session_variables
    defaults = {
      'menu_item' => 'search',
      'advanced_search' => '0'
    }
    valid_keys = defaults.keys
    
    session['interface'] = {} if session['interface'].nil?
    params.each do |key, value|
      session['interface'][key] = value if valid_keys.include?(key)
    end
    render :text => '' 
  end
  
  protected
    
  def api_render(features, **options)
    collection = {}
    collection[:features] = features.collect{|f| api_format_feature(f)}
    collection[:page] = params[:page] || 1
    collection[:total_pages] = features.total_pages
    respond_to do |format|
      format.xml { render :xml => collection.to_xml }
      format.json { render :json => collection.to_json, :callback => params[:callback] }
    end
  end
  
  private
  
  def cache_key_by_params(c, options)
    p = []
    if options[:perspective_code]
      perspective_code = params[:perspective_code]
      perspective_code = default_perspective_code if perspective_code.blank? || Perspective.get_by_code(perspective_code).nil?
      p << "perspective_code=#{perspective_code}"
    end
    if options[:view_code]
      view_code = params[:view_code]
      view_code = default_view_code if view_code.blank? || View.get_by_code(view_code).nil?
      p << "view_code=#{view_code}"
    end
    "#{c.request.path}?#{p.join('&')}"
  end
  
  def update_perspective
    return if @feature.nil?
    perspective_ids = @feature.parent_relations.select(:perspective_id).distinct.collect(&:perspective_id) + @feature.child_relations.select(:perspective_id).distinct.collect(&:perspective_id)
    return if perspective_ids.blank? || perspective_ids.include?(self.current_perspective.id)
    self.current_perspective_id = perspective_ids.first
  end
  
  ActiveSupport.run_load_hooks(:features_controller, FeaturesController)
end
