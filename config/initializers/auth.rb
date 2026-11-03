# frozen_string_literal: true

# Central place for every auth-related setting. All values come from ENV
# (see .env.example) so the service can be reused without code changes.
list = ->(value) { value.to_s.split(",").map(&:strip).reject(&:empty?) }

frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173").chomp("/")

Rails.application.configure do
  config.x.auth.api_url = ENV.fetch("API_URL", "http://localhost:3000").chomp("/")
  config.x.auth.frontend_url = frontend_url

  config.x.auth.access_token_ttl = Integer(ENV.fetch("JWT_ACCESS_TOKEN_TTL_MINUTES", 15)).minutes
  config.x.auth.refresh_token_ttl = Integer(ENV.fetch("REFRESH_TOKEN_TTL_DAYS", 30)).days
  config.x.auth.oauth_code_ttl = Integer(ENV.fetch("OAUTH_CODE_TTL_SECONDS", 60)).seconds

  # Exact URIs the OAuth flow may redirect back to (web and mobile schemes).
  config.x.auth.oauth_redirect_allowlist =
    list.call(ENV.fetch("OAUTH_REDIRECT_ALLOWLIST", "#{frontend_url}/oauth/callback"))

  # Pages of *your* frontend that receive the tokens from the emails. When
  # CONFIRMATION_URL is empty, the email links straight to this API.
  config.x.auth.confirmation_url = ENV["CONFIRMATION_URL"].presence
  config.x.auth.reset_password_url = ENV.fetch("RESET_PASSWORD_URL", "#{frontend_url}/reset-password")

  config.x.auth.cors_origins = list.call(ENV.fetch("CORS_ORIGINS", frontend_url))
end

if Rails.env.production?
  missing = %w[JWT_SECRET_KEY API_URL OAUTH_REDIRECT_ALLOWLIST].reject { |k| ENV[k].present? }
  raise "Missing required ENV for production: #{missing.join(', ')}" if missing.any?
end
