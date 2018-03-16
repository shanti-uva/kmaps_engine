Rails.application.routes.draw do
  concern :notable_citable do
    resources :notes, :citations
  end
  resource :session do
    get 'change_language/:id', to: 'sessions#change_language', as: :change_language
    get 'change_perspective/:id', to: 'sessions#change_perspective', as: :change_perspective
    get 'change_view/:id', to: 'sessions#change_view', as: :change_view
  end
  namespace :admin do
    concern :add_author do
      get :add_author, on: :collection
    end
    
    concern :citable_notable_dateable do
      resources :notes, concerns: :add_author
      resources :citations
      resources :time_units do
        get :new_form, on: :collection
      end
    end
    
    resources :alt_spelling_systems, :association_notes, :blurbs, :collections, :feature_name_types, :feature_relation_types,
      :feature_types, :geo_code_types, :importation_tasks, :languages, :note_titles, :orthographic_systems, :oral_sources, :perspectives,
      :phonetic_systems, :users, :writing_systems, :xml_documents, :views
    get 'openid_new', to: 'users#openid_new'
    post 'openid_create', to: 'users#create'
    root to: 'default#index'
    resources :citations do
      resources :pages, :web_pages
    end
    resources :descriptions, concerns: :citable_notable_dateable
    resources :feature_geo_codes, concerns: :citable_notable_dateable
    resources :feature_names, concerns: :citable_notable_dateable do
      resources :feature_name_relations
      get :locate_for_relation, on: :member
      post :set_priorities, on: :collection
    end
    resources :feature_name_relations, concerns: :citable_notable_dateable
    resources :feature_relations, concerns: :citable_notable_dateable
    resources :features do
      resources :affiliations
      resources :citations
      resources :time_units do
        get :new_form, on: :collection
      end
      member do
        get :set_primary_description
        get :locate_for_relation
        post :clone
      end
      collection do
        get 'prioritize_feature_names/:id', to: 'feature_names#prioritize', as: :prioritize_feature_names
      end
      resources :captions, :feature_geo_codes, :feature_names, :feature_relations, :illustrations, :summaries
      resources :association_notes, concerns: :add_author
      resources :descriptions, concerns: :add_author
    end
    resources :feature_pids do
      get :available, on: :collection
    end
    resources :notes, concerns: :add_author
    resources :time_units do
      resources :notes, concerns: :add_author
    end
    resources :captions, :summaries do
      resources :citations
    end
  end
  resources :features do
    resources :captions, only: [:index, :show]
    resources :codes, only: [:index]
    resources :summaries, only: [:index, :show]
    resources :association_notes
    resources :names, only: [:index, :show], controller: 'feature_names'
    resources :descriptions do
      member do
        get :expand
        get :show
        get :contract
      end
    end
    member do
      get :all
      get :expanded
      get :children
      get :contracted
      get :descendants
      get :iframe
      get :list
      get :nested
      match 'fancy_nested', to: 'features#fancy_nested', via: [:post, :get]
      match 'fancy_children', to: 'features#fancy_children', via: [:post, :get]
      get :node_tree_expanded
      get :related
      get :related_list
    end
    collection do
      get :all
      get :characteristics_list
      get :list
      match 'fancy_nested', to: 'features#fancy_nested', via: [:post, :get]
      match 'fancy_children', to: 'features#fancy_children', via: [:post, :get]
      get :nested
      match :search, to: 'features#search', via: [:post, :get]
      get 'by_fid/:fids.:format', to: 'features#by_fid'
      get 'by_old_pid/:old_pids', to: 'features#by_old_pid'
      get 'by_geo_code/:geo_code.:format', to: 'features#by_geo_code'
      get 'by_name/:query.:format', to: 'features#by_name', query: /.*?/
      get 'by_fields/:query.:format', to: 'features#by_fields', query: /.*?/
      get 'fids_by_name/:query.:format', to: 'features#fids_by_name', query: /.*?/
      post :set_session_variables
    end
  end
  resources :associated_media, only: :show do
    member do
      get 'pictures'
      get 'videos'
      get 'documents'
    end
  end
  resources :descriptions, concerns: :notable_citable, only: ['show', 'index']
  resources :feature_geo_codes, concerns: :notable_citable
  resources :feature_names, concerns: :notable_citable, only: [:index, :show]
  resources :feature_name_relations, concerns: :notable_citable
  resources :feature_relations, concerns: :notable_citable
  resources :media, only: 'show', path: 'media_objects'
  resources :time_units, concerns: :notable_citable
  root to: 'features#index'
end
