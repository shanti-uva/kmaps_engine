# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Authentication
  include KmapsEngine::SessionManager
  protect_from_forgery with: :exception
  before_action :set_common_variables #, if: -> { request.format.html? }
  layout :choose_layout
  
  protected
  
  def is_admin_area?
    params[:controller] =~ /^(admin|authenticated_system\/[^s])/
  end
    
  def choose_layout
    return 'admin' if is_admin_area?
    # if request.xhr?
    if ['show', 'feature'].include? params[:action]
      @no_layout = ! params[:no_layout].blank?
      return nil if @no_layout
    end
    'public'
  end

  def set_common_variables
    session['interface'] ||= {}

    # Allow for views and perspectives to be set by GET params.  It might be possible to simplify this code...
    if params[:perspective_id] || params[:view_id]
      session = Session.new
      if params[:perspective_id]
        session.perspective_id = params[:perspective_id]
        self.current_perspective = Perspective.find(params[:perspective_id])
      end
      if params[:view_id]
        session.view_id = params[:view_id]
        self.current_view = View.find(params[:view_id])
      end
    end
    @top_level_nodes = Feature.current_roots(current_perspective, current_view)
    @session = Session.new(perspective_id: self.current_perspective&.id, view_id: self.current_view&.id, language: I18n.locale)
    @perspectives = Perspective.find_all_public
    @views = View.order('name')
  end
  
end
