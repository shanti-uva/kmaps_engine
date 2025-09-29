class PreferencesController < ApplicationController
  allow_unauthenticated_access
  protect_from_forgery :except => :edit
  
  def edit
    session['name_preferences']['filter'] = params[:name_preferences_filter]
    render plain: ''
  end
end
