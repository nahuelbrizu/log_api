# frozen_string_literal: true

# Devise handles password hashing, confirmation and password reset. The
# HTTP endpoints are our own JSON controllers (app/controllers/auth), so
# Devise's HTML controllers and session-based sign-in are not used.
Devise.setup do |config|
  require "devise/orm/active_record"

  config.mailer_sender = ENV.fetch("MAILER_SENDER", "no-reply@example.com")
  config.parent_mailer = "ActionMailer::Base"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.email_regexp = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  # bcrypt ignores everything after 72 bytes, so cap there instead of
  # silently accepting longer passwords.
  config.password_length = 8..72
  config.stretches = Rails.env.test? ? 1 : 12
  config.pepper = ENV["DEVISE_PEPPER"].presence

  config.reconfirmable = false
  config.confirm_within = 3.days
  config.reset_password_within = 2.hours
  config.sign_in_after_reset_password = false
  config.send_password_change_notification = true

  # Never keep users in the session; authentication is per request (JWT).
  config.skip_session_storage = %i[http_auth params_auth]
  config.navigational_formats = []

  # --- JWT access tokens (devise-jwt / warden-jwt_auth) -------------------
  # Tokens are issued explicitly by Auth::TokenIssuer and revoked by
  # Auth::SessionsController, so no dispatch/revocation paths are needed.
  config.jwt do |jwt|
    jwt.secret = ENV["JWT_SECRET_KEY"].presence || Rails.application.secret_key_base
    jwt.expiration_time = Rails.application.config.x.auth.access_token_ttl.to_i
    jwt.dispatch_requests = []
    jwt.revocation_requests = []
    jwt.algorithm = "HS256"
  end

  # --- Social login (OmniAuth) --------------------------------------------
  # A provider is enabled only when both of its credentials are present.
  {
    google_oauth2: [%w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET], { scope: "email,profile", prompt: "select_account" }],
    facebook: [%w[FACEBOOK_APP_ID FACEBOOK_APP_SECRET], { scope: "email", info_fields: "email,name" }],
    github: [%w[GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET], { scope: "user:email" }],
    twitter: [%w[TWITTER_API_KEY TWITTER_API_SECRET], {}]
  }.each do |provider, (keys, options)|
    next unless Rails.env.test? || keys.all? { |k| ENV[k].present? }

    config.omniauth provider, *keys.map { |k| ENV[k] }, **options
  end
end

# The request phase is guarded by Oauth::RequestGuard (allowlisted
# redirect_uri + PKCE) and the callback by OmniAuth's `state` param, so the
# login can be started with a plain GET from a browser or a mobile app.
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
# Behind a proxy, set API_URL so callback URLs use the public host.
OmniAuth.config.full_host = Rails.application.config.x.auth.api_url if ENV["API_URL"].present?
OmniAuth.config.logger = Rails.logger
