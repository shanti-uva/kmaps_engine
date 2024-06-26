class PerspectiveSweeper < ActionController::Caching::Sweeper
  include InterfaceUtils::Extensions::Sweeper
  include Rails.application.routes.url_helpers
  include ActionController::Caching::Pages
  
  observe Perspective
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
  
  def expire_cache(perspective)
    options = {:only_path => true}
    FORMATS.each do |format|
      options[:format] = format
      expire_full_path_page admin_perspectives_url(options)
    end
  end
end