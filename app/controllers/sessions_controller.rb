# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  def new
    reset_session
    redirect_to root_url
  end
  
  # GET /session/edit
  def edit
    @session = Session.new(
      :perspective_id => self.current_perspective.id,
      :view_id => self.current_view.id,
      :show_feature_details => self.current_show_feature_details,
      :show_advanced_search => self.current_show_advanced_search)
    @views = View.order('name')
  end
    
  # PUT /session
  def update
    session = Session.new(params[:session])
    self.current_perspective_id = session.perspective_id
    self.current_view_id = session.view_id
    self.current_show_advanced_search = session.show_advanced_search
    self.current_show_feature_details = session.show_feature_details
    redirect_to request.env["HTTP_REFERER"].blank? ? root_path : :back
  end
  
  def change_perspective
    perspective = Perspective.find(params[:id])
    self.current_perspective_id = perspective.id if !perspective.nil?
    session['interface']['context_id'] = nil
    redirect_to root_url
    #redirect_back fallback_location: root_url
  end
  
  def change_view
    view = View.find(params[:id])
    self.current_view_id = view.id if !view.nil?
    redirect_back fallback_location: root_url
  end
  
  ActiveSupport.run_load_hooks(:sessions_controller, SessionsController)
end