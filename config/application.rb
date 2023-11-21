require_relative "boot"

require "rails/all"
require 'dotenv'
Dotenv.load

Bundler.require(*Rails.groups)

module AppNamedPoly
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.middleware.use ActionDispatch::Session::CookieStore

    config.middleware.use OmniAuth::Builder do
      provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
        scope: 'email, profile, uid', # Specify the scopes you need
        access_type: 'offline', # For obtaining refresh tokens
        name: 'google', # An optional provider name (useful if you have multiple providers)
        prompt: 'select_account', # To force the account selection prompt
      }
    end

    config.api_only = true
  end
end
