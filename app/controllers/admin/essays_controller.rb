class Admin::EssaysController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  belongs_to :feature
  protected

  new_action.before do
    @languages = Language.available_as_locales
  end

  edit.before do
    @languages = Language.available_as_locales
  end
  
  create.before do
    @languages = Language.available_as_locales
  end
  
  update.before do
    @languages = Language.available_as_locales
  end

  # Only allow a trusted parameter "white list" through.
  def essay_params
    params.require(:essay).permit(:feature_id, :text_id, :language_id)
  end
end
