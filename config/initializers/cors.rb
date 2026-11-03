# frozen_string_literal: true

# Browser clients authenticate with a bearer token, not cookies, so
# credentials stay disabled and any listed origin may call the API.
# CORS_ORIGINS is a comma-separated list (use "*" only for public demos).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*Rails.application.config.x.auth.cors_origins)

    resource "*",
             headers: :any,
             expose: %w[Authorization Retry-After],
             methods: %i[get post put patch delete options head],
             max_age: 600
  end
end
