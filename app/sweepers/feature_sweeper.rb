require 'rails/observers/action_controller/caching'

class FeatureSweeper < ActionController::Caching::Sweeper
  include InterfaceUtils::SweeperExtensions
  include Rails.application.routes.url_helpers
  include ActionController::Caching::Pages
  include ActionController::Caching::Actions
  
  observe Feature
  FORMATS = ['xml', 'json']
  FIDS_PER_SITEMAP = 50_000
  
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
    # Relevant for solr:
    if record.destroyed?
      if record.class.post_to_index?
        record.remove!
      else
        record.fs_remove
      end # have to deal with deleting records from index.
    elsif record.is_public?
      record.queued_index
    end
    # Feature.commit
    options = {:only_path => true}
    FORMATS.each do |format|
      options[:format] = format
      expire_full_path_page feature_url(record.fid, options)
    end
    expire_sitemap_cache(record)
  end

  def expire_sitemap_cache(record)
    return if record.fid.blank?

    expire_full_path_page features_sitemap_url(page: sitemap_page_for_fid(record.fid), only_path: true)
  end

  def sitemap_page_for_fid(fid)
    (fid.to_i / FIDS_PER_SITEMAP) + 1
  end
end
