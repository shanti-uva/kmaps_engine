class Admin::SummariesController < ApplicationController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  cache_sweeper :summary_sweeper, :only => [:update, :destroy]
  belongs_to :feature
  
  new_action.before do
    used_languages = parent_object.summaries.collect(&:language_id)
    english = Language.get_by_code('eng')
    query = Language.order('name')
    @languages = used_languages.empty? ? query : query.where(['id NOT IN (?)', used_languages])
    object.language = english if !used_languages.include? english.id
    @authors = AuthenticatedSystem::Person.order('fullname')
    object.author = AuthenticatedSystem::Current.user.person
  end
  
  edit.before do
    @languages = Language.order('name')
    @authors = AuthenticatedSystem::Person.order('fullname')
  end
  
  create.before do
    @languages = Language.order('name')
    @authors = AuthenticatedSystem::Person.order('fullname')
  end
  
  update.before do
    @languages = Language.order('name')
    @authors = AuthenticatedSystem::Person.order('fullname')
  end
  
  def parent_association
    parent_object.summaries
  end
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def summary_params
    params.require(:summary).permit(:author_id, :content, :feature_id, :language_id)
  end
end
