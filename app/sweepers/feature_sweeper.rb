class FeatureSweeper < ActionController::Caching::Sweeper
  include InterfaceUtils::Extensions::Sweeper
  include Rails.application.routes.url_helpers
  include ActionController::Caching::Pages
  include ActionController::Caching::Actions
  
  observe Feature, FeatureName, FeatureRelation
  FORMATS = ['xml', 'json']
  
  def after_save(record)
    expire_cache(record) #if record.is_a?(Feature)
  end
  
  def after_destroy(record)
    expire_cache(record) #if record.is_a?(Feature)
  end
  
  def default_static_extension
    #Rails.configuration.default_static_extension
  end

  def expire_cache(record)
    if record.instance_of? Feature
      feature = record
      return if feature.ancestor_ids_changed?
    elsif record.instance_of?(FeatureRelation)
      feature = record.child_node
    else #if record.instance_of? FeatureName
      feature = record.feature
    end
    options = {:only_path => true}
    FORMATS.each do |format|
      options[:format] = format
      if record.instance_of?(Feature)
        expire_full_path_page feature_url(feature.fid, options)
        expire_full_path_page related_feature_url(feature.fid, options)
      elsif record.instance_of?(FeatureName)
        expire_full_path_page feature_url(feature.fid, options)
        expire_full_path_page feature_names_url(feature.fid, options)
        expire_full_path_page feature_name_url(feature.fid, record.id, options)
        expire_full_path_page related_feature_url(feature.fid, options)
        views = CachedFeatureName.where(:feature_name_id => record.id).select('view_id').collect(&:view)
        perspectives = feature.parent_relations.joins(:perspective).where('perspectives.is_public' => true).select(:perspective_id).uniq.collect(&:perspective)
        for view in views
          params = "?view_code=#{view.code}"
          expire_action "#{all_features_url(options)}#{params}"
          expire_action "#{list_features_url(options)}#{params}"
          ancestors_and_self = feature.ancestors + [feature]
          for f in ancestors_and_self
            expire_action "#{all_feature_url(f.fid, options)}#{params}"
            expire_action "#{list_feature_url(f.fid, options)}#{params}"
          end
          for perspective in perspectives
            params = "?perspective_code=#{perspective.code}&view_code=#{view.code}"
            expire_action "#{fancy_nested_features_path(options)}#{params}"
            expire_action "#{nested_features_path(options)}#{params}"
            parents = feature.current_parents(perspective, view)
            for f in parents
              expire_action "#{children_feature_url(f.fid, options)}#{params}"
            end
            for f in ancestors_and_self
              expire_action "#{fancy_nested_feature_path(f.fid, options)}#{params}"
              expire_action "#{nested_feature_path(f.fid, options)}#{params}"
            end
          end
        end
      elsif record.instance_of?(FeatureRelation)
        expire_full_path_page feature_url(record.parent_node.fid, options)
        child_node = record.child_node
        expire_full_path_page related_feature_url(child_node.fid, options)
        perspective = record.perspective
        views = View.all
        params = "?perspective_code=#{perspective.code}"
        feature = record.parent_node
        for view in views
          params1 = "?view_code=#{view.code}"
          expire_action "#{all_features_url(options)}#{params}"
          expire_action "#{list_features_url(options)}#{params}"
          ancestors_and_self = feature.ancestors + [feature]
          for f in ancestors_and_self
            expire_action "#{all_feature_url(f.fid, options)}#{params}"
            expire_action "#{list_feature_url(f.fid, options)}#{params}"
          end
          params = "?perspective_code=#{perspective.code}&view_code=#{view.code}"
          expire_action "#{fancy_nested_features_path(options)}#{params}"
          expire_action "#{nested_features_path(options)}#{params}"
          expire_action "#{children_feature_url(feature.fid, options)}#{params}"
          for f in ancestors_and_self
            expire_action "#{fancy_nested_feature_path(f.fid, options)}#{params}"
            expire_action "#{nested_feature_path(f.fid, options)}#{params}"
          end
        end
      end
    end
    options[:format] = 'csv'
    ancestors_and_self = feature.ancestors + [feature]
    for f in ancestors_and_self
      expire_full_path_page feature_url(f.fid, options)
    end
  end
end
