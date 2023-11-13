Rails.application.routes.draw do
  resources :profiles do
    collection do
      get 'new' # Custom route for the new action
      get 'edit' # Custom route for the edit action
    end
  end

  get 'home/index'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth'
  }

  get 'users/authcallback', to: 'users/omniauth#google_oauth2'

  # Defines the root path route ("/")
  # root "articles#index"
end
