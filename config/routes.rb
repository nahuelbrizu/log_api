Rails.application.routes.draw do
  # Devise: /users/sign_in, /users/sign_up, /users/confirmation, ...
  # OmniAuth: POST /users/auth/:provider → GET /users/auth/:provider/callback
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth'
  }

  resources :profiles, except: %i[new edit]

  get 'home/index'
  root 'home#index'
end
