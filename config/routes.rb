Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web' # ← ¡esto es clave!

  # Montar Sidekiq::Web dentro de las rutas de la aplicación
  mount Sidekiq::Web => '/sidekiq'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    namespace :v1 do
      resources :attendances do
        member do
          patch :reopen
        end
        collection do
          get 'by_users_working_today', to: 'attendances#by_users_working_today'
          get 'by_users_queue', to: 'attendances#by_users_queue'
          get 'today', to: 'attendances#today'
          get 'history', to: 'attendances#history'
          get 'statistics', to: 'attendances#statistics'
          get 'summary', to: 'attendances#summary'
        end
      end
      resources :branches
      resources :profiles do
        get :search, on: :collection
      end
      resources :roles
      resources :services
      resources :expenses
      resources :cash_reconciliations, only: [:index, :create] do
        get :preview, on: :collection
        member do
          patch :approve
        end
      end

      resources :users do
        collection do
          get 'working_today', to: 'users#users_working_today'
          get 'next_available', to: 'users#next_available'
          post 'start_day', to: 'users#start_day'
          post 'end_day', to: 'users#end_day'
          post 'start_attendance', to: 'users#start_attendance'
          post 'end_attendance', to: 'users#end_attendance'
          post 'finish_attendance', to: 'users#finish_attendance'
          post 'postpone_attendance', to: 'users#postpone_attendance'
          post 'resume_attendance', to: 'users#resume_attendance'
          post 'cancel_attendance', to: 'users#cancel_attendance'
          get 'calculate_payment', to: 'users#calculate_payment'
          post 'reset_password', to: 'users#reset_password'
          patch 'update_password', to: 'users#update_password'
          post 'verify_email', to: 'users#verify_email'
        end
        member do
          patch 'not_available', to: 'users#not_available'
          patch 'available', to: 'users#available'
        end
      end

      resources :organizations do
        collection do
          get 'slug/:slug', to: 'organizations#find_by_slug', as: :find_by_slug
        end
      end
      post 'clean', to: 'organizations#clean'
      post 'build_queue', to: 'organizations#build_queue'
      get 'show_queue', to: 'organizations#show_queue'
      post 'login', to: 'auth#login'
      get 'me', to: 'auth#me'
      resources :payments do
        member do
          patch :approve
          patch :reject
          patch :cancel
          patch :mark_success
          patch :resend
        end
      end
      resources :push_subscriptions, only: [:create]
    end
  end
end
