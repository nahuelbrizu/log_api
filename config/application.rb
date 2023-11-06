require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AppNamedPoly
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.middleware.use ActionDispatch::Session::CookieStore

    config.middleware.use OmniAuth::Builder do
      provider :google_oauth2, '772918967244-k93kvjnb41dfhnp477vo2hgmafvi29i1.apps.googleusercontent.com', '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', {
        scope: 'email, profile, uid', # Specify the scopes you need
        access_type: 'offline', # For obtaining refresh tokens
        name: 'google', # An optional provider name (useful if you have multiple providers)
        prompt: 'select_account', # To force the account selection prompt
      }
    end

    # Configuration for the application, engines, and railties goes here.
    #       config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
