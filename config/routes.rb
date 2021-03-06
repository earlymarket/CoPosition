Rails.application.routes.draw do
  use_doorkeeper do
    controllers applications: "oauth/applications",
                authorizations: "oauth/authorizations",
                tokens: "oauth/tokens"
  end

  ActiveAdmin.routes(self)
  mount ActionCable.server => "/cable"
  root to: "welcome#index"

  # Specified routes

  get "/api", to: "welcome#api"
  get "/help", to: "welcome#help"
  get "/devs/setup", to: "welcome#setup"
  get "/terms", to: "welcome#terms"
  get "/devs", to: "welcome#devs"
  get "/add_friend", to: "users/approvals#add"
  get "/apps", to: "users/approvals#apps"
  get "/friends", to: "users/approvals#friends"
  get "/devices", to: "users/devices#devices"

  # Devise

  devise_for :users, controllers: {
    registrations: "users/devise/registrations",
    sessions: "users/devise/sessions"
  }
  devise_scope :user do
    get "/account", to: "users/devise/registrations#edit"
  end
  devise_for :developers, controllers: {
    registrations: "developers/devise/registrations",
    sessions: "developers/devise/sessions"
  }

  # Attachinary
  mount Attachinary::Engine => "/attachinary"

  # API

  env_constraint = Constraints::EnvironmentConstraint.new

  namespace :api, path: env_constraint.path, constraints: env_constraint.constraints, defaults: { format: "json" } do
    scope module: :v1, constraints: Constraints::ApiConstraint.new(version: 1, default: true) do
      resources :subscriptions, only: [:create, :destroy]
      resources :release_notes, only: :index
      resources :configs, only: [:index, :show, :update]
      resource :uuid, only: [:show]
      resources :checkins, only: [:create] do
        collection do
          post :batch_create
        end
      end
      resources :developers, only: [:index, :show]
      resources :demo do
        collection do
          get :reset_approvals
          get :demo_user_approves_demo_dev
        end
      end
      resources :users, only: [:show, :index] do
        collection do
          get :auth
        end
        resources :approvals, only: [:create, :index, :update, :destroy], module: :users do
          collection do
            get :status
            post :email
          end
        end
        resources :email_requests, only: [:index, :destroy], module: :users
        resources :checkins, only: [:index] do
          collection do
            get :last
          end
        end
        resources :requests, only: [:index], module: :users do
          collection do
            get :last
          end
        end
        resources :devices, only: [:index, :create, :show, :update], module: :users do
          resources :permissions, only: [:update, :index]
          put "/permissions", to: "permissions#update_all"
        end
      end
      namespace :mobile_app do
        resources :sessions, only: [:create, :destroy]
      end
    end
    match "*path", to: -> (_env) { [404, {}, ["{'error': 'route_not_found'}"]] }, via: :all
  end

  # Users
  resources :users, only: [:show], module: :users do
    resource :dashboard, only: [:show]
    resources :devices, except: :edit do
      member do
        get :download
        get :shared, :info
        post :remote_checkin
      end
      resources :checkins, only: [:index, :show, :create, :new, :update, :destroy] do
        collection { post :import }
      end
      delete "/checkins/", to: "checkins#destroy_all"
      resources :permissions, only: [:update, :index]
    end
    resources :checkins, only: [:show, :index, :update, :destroy]
    resources :approvals, only: [:new, :create, :update, :destroy]
    resources :email_subscriptions, only: :update do
      collection do
        get "unsubscribe"
      end
    end
    resources :email_requests, only: :destroy
    resource :create_dev_approvals, only: :create
    resources :friends, only: [:show] do
      member do
        get "show_device"
        post "request_checkin"
      end
    end
    get "/apps", to: "approvals#index", defaults: { approvable_type: "Developer" }
    get "/friends", to: "approvals#index", defaults: { approvable_type: "User" }
    collection do
      get :me
    end
    resources :countries, only: :index
  end

  # Devs
  resources :developers, only: [:edit, :update]

  # Release notes
  resources :release_notes do
    member { post :notify }
  end

  resources :activities, only: :index

  namespace :developers do
    get "/", to: "consoles#show"
    resource :console, only: [:show] do
      collection { post "key" }
    end
    resources :approvals, only: [:index, :new, :create, :destroy]
    # For cool API usage stats in the future
    resources :requests, only: [:index] do
      collection do
        put :pay
      end
    end
  end
end
