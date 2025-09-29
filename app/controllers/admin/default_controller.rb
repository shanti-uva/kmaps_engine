class Admin::DefaultController < ApplicationController
  def index
    @intro_blurb = Blurb.find_by(code: (AuthenticatedSystem::Current.user.admin? ? 'homepage.admin' : 'homepage.edit'))
  end

  def help
  end
  
end