Rails.application.routes.draw do
  # Social login (OmniAuth, mounted by Devise):
  #   GET  /auth/:provider?redirect_uri=...&code_challenge=...  -> provider
  #   GET  /auth/:provider/callback                             -> redirect_uri?code=...
  devise_for :users, path: "", only: :omniauth_callbacks,
                     controllers: { omniauth_callbacks: "auth/omniauth_callbacks" }

  scope "auth", module: "auth", as: "auth" do
    post   "sign_up",             to: "registrations#create"
    post   "sign_in",             to: "sessions#create"
    delete "sign_out",            to: "sessions#destroy"
    post   "refresh",             to: "tokens#create"
    post   "oauth/token",         to: "oauth_tokens#create"
    get    "providers",           to: "providers#index"

    match  "confirmation",        to: "confirmations#create", via: %i[get post], as: :confirmation
    post   "confirmation/resend", to: "confirmations#resend"

    post   "password",            to: "passwords#create"
    put    "password",            to: "passwords#update"
    patch  "password",            to: "passwords#update"
  end

  resource :me, only: %i[show update destroy], controller: "me"
  resources :profiles, except: %i[new edit]

  get "up", to: "health#show"
  root "health#show"
end
