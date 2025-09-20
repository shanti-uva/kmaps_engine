class FeatureRelationSweeper < ActionController::Caching::Sweeper
  include InterfaceUtils::SweeperExtensions
  include Rails.application.routes.url_helpers
  include ActionController::Caching::Pages
  include ActionController::Caching::Actions
  
  observe FeatureRelation, CachedFeatureName
  FORMATS = ['xml', 'json']
  
  def after_save(record)
    expire_cache(record)
  end
  
  def after_touch(record)
    expire_cache(record)
  end
  
  def after_destroy(record)
    expire_cache(record)
  end
  
  def expire_cache(record)
    return if record.skip_update || KmapsEngine::ApplicationSettings.disable_cache_expiration?
    already_reindexed = []
    if record.instance_of? FeatureRelation
      feature = record.child_node
      perspective = record.perspective
      perspective_id = perspective.id
      Rails.cache.delete_matched("features/current_roots/#{perspective_id}/*") if feature.is_public? && feature.ancestors.blank?
      descendants = feature.descendants_by_perspective_with_parent(perspective).collect(&:first) + [record.parent_node]
      descendants.each do |f|
        Rails.cache.delete("features/#{f.fid}/closest_parent_by_perspective/#{perspective_id}")
        Rails.cache.delete("features/#{f.fid}/closest_parents_by_perspective/#{perspective_id}")
        Rails.cache.delete("features/#{f.fid}/closest_hierarchical_feature_by_perspective/#{perspective_id}")
        Rails.cache.delete("features/#{f.fid}/ancestors_by_perspective/#{perspective_id}")
        Rails.cache.delete("features/#{f.fid}/closest_ancestors_by_perspective/#{perspective_id}")
        if !f.skip_update && f.is_public? && !already_reindexed.include?(f.fid)
          f.queued_index
          already_reindexed << f.fid
        end
      end
    elsif record.instance_of?(CachedFeatureName)
      feature = record.feature
    elsif record.instance_of?(Feature)
      feature = record
    end
    return if feature.nil? || feature.skip_update
    feature.parents.each do |f|
      if f.is_public? && !already_reindexed.include?(f.fid)
        f.queued_index
        already_reindexed << f.fid
      end
    end
    feature.children.each do |f|
      if f.is_public? && !already_reindexed.include?(f.fid)
        f.queued_index
        already_reindexed << f.fid
      end
    end
    options = {:only_path => true}
    options[:format] = 'csv'
    ancestors_and_self = feature.ancestors + [feature]
    for f in ancestors_and_self
      expire_full_path_page feature_url(f.fid, options)
    end
  end
end