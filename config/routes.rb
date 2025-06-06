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
      get 'barbers/barbers_working_today', to: 'users#barbers_working_today'
      get 'barbers/next_available', to: 'users#next_available'
      post 'barber/start_day', to: 'users#start_day'
      post 'barber/end_day', to: 'users#end_day'
      post 'barber/start_attendance', to: 'users#start_attendance'
      post 'barber/end_attendance', to: 'users#end_attendance'
      post 'barber/finish_attendance', to: 'users#finish_attendance'
      post 'login', to: 'auth#login'
      get 'me', to: 'auth#me'
    end
  end
end
