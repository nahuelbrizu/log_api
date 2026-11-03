require_relative "boot"

require "rails"
# Only the frameworks an auth API needs (no Action Cable, Active Storage,
# Action Mailbox or Action Text, which would add routes and config).
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load variables from .env (the plain `dotenv` gem does not auto-load).
Dotenv.load

module AppNamedPoly
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
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

    # Authentication is stateless (JWT bearer tokens). The only thing that
    # needs a session is the OmniAuth handshake: the OAuth `state` param and
    # the client's redirect_uri/PKCE challenge must survive the round trip to
    # the provider. A short-lived, encrypted cookie is enough for that, so no
    # session table is needed. SameSite=Lax still sends the cookie on the
    # provider's top-level GET redirect back to the callback.
    config.session_store :cookie_store,
                         key: "_auth_oauth_handshake",
                         expire_after: 15.minutes,
                         same_site: :lax,
                         secure: Rails.env.production?,
                         httponly: true
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    # Unknown routes and unhandled exceptions render the same JSON error
    # envelope as the controllers instead of HTML pages.
    config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }
  end
end
