class FeatureSweeper < ActionController::Caching::Sweeper
  observe Feature, FeatureName, FeatureRelation
  FORMATS = ['xml', 'json']
  
  def after_save(record)
    expire_cache(record) if record.is_a?(Feature)
  end
  
  def after_destroy(record)
    expire_cache(record) if record.is_a?(Feature)
  end
  
  def expire_cache(feature)
    options = {:skip_relative_url_root => true, :only_path => true}
    FORMATS.each do |format|
      options[:format] = format
      expire_page feature_url(feature.fid, options)
      expire_page all_feature_url(feature.fid, options)
      expire_page all_features_url(options)
      expire_page children_feature_url(feature.fid, options)
      expire_page list_feature_url(feature.fid, options)
      expire_page nested_feature_url(feature.fid, options)
      expire_page nested_features_url(options)
    end
  end
  
  #def after_commit(record)
  #  reheat_cache
  #end
  
  #def reheat_cache
  #  node_id = Rails.cache.read('tree_tmp') rescue nil
  #  unless node_id.nil?
  #    Rails.cache.delete('tree_tmp')
  #    spawn(:method => :thread, :nice => 3) do  
  #      KmapsEngine::TreeCache.reheat(node_id)
  #    end
  #  end
  #end
end