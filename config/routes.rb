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
        collection do
          get 'by_users_working_today', to: 'attendances#by_users_working_today'
        end
      end
      resources :branches
      resources :profiles
      resources :roles
      resources :services

      resources :users do
        collection do
          get 'working_today', to: 'users#users_working_today'
          get 'next_available', to: 'users#next_available'
          post 'start_day', to: 'users#start_day'
          post 'end_day', to: 'users#end_day'
          post 'start_attendance', to: 'users#start_attendance'
          post 'end_attendance', to: 'users#end_attendance'
          post 'finish_attendance', to: 'users#finish_attendance'
        end
      end

      resources :organizations do
        collection do
          get 'slug/:slug', to: 'organizations#find_by_slug', as: :find_by_slug
        end
      end
      post 'login', to: 'auth#login'
      get 'me', to: 'auth#me'
    end
  end
end
