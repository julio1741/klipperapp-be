Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    namespace :v1 do
      resources :attendances
      resources :branches
      resources :profiles
      resources :roles
      resources :services
      resources :users
      resources :organizations do
        collection do
          get 'slug/:slug', to: 'organizations#find_by_slug', as: :find_by_slug
        end
      end
      get 'barbers/next_available', to: 'barbers#next_available'
      post 'barbers/:id/start_day', to: 'barbers#start_day'
      post 'barbers/:id/end_day', to: 'barbers#end_day'
      post 'barbers/:id/start_attendance', to: 'barbers#start_attendance'
      post 'barbers/:id/end_attendance', to: 'barbers#end_attendance'
      post 'login', to: 'auth#login'
      get 'me', to: 'auth#me'
    end
  end
end
