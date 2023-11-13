Rails.application.routes.draw do
  resources :profiles
  get 'home/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth'
  }

  get 'users/authcallback', to: 'users/omniauth#google_oauth2'

  # Defines the root path route ("/")
  # root "articles#index"
end
