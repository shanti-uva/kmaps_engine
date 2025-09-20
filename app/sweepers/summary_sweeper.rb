class SummarySweeper < ActionController::Caching::Sweeper
  include InterfaceUtils::SweeperExtensions
  include Rails.application.routes.url_helpers
  include ActionController::Caching::Pages
  
  observe Summary
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
  
  def expire_cache(summary)
    feature = summary.feature
    options = {:only_path => true}
    FORMATS.each do |format|
      options[:format] = format
      expire_full_path_page feature_summary_url(feature.fid, summary, options)
      expire_full_path_page feature_summaries_url(feature.fid, options)
    end
  end
end