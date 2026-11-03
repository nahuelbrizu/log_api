# frozen_string_literal: true

require "json"
require_relative "redirect_policy"

module Oauth
  # Rack middleware placed in front of the OmniAuth strategies.
  #
  # OmniAuth's request phase (GET/POST /auth/:provider) is allowed over GET so
  # that SPAs can navigate and mobile apps can open it in a system browser.
  # Instead of a CSRF token (an API-only app has no page to embed one in),
  # every login must carry:
  #
  #   * return_to      - where the browser is sent at the end; must exactly
  #                      match an entry of OAUTH_REDIRECT_ALLOWLIST
  #   * code_challenge - PKCE S256 challenge; the one-time code returned at
  #                      the end is only exchangeable with its verifier
  #
  # Requests without them are rejected before reaching the provider. OmniAuth
  # stores the query params in the session, so the callback gets them back.
  #
  # Every other query param is dropped: several strategies copy params such
  # as redirect_uri, state, scope or client_options straight into the
  # provider's authorize URL, and clients must not be able to tamper with it.
  class RequestGuard
    PATH = %r{\A/auth/(?<provider>[a-z0-9_]+)/?\z}
    ALLOWED_PARAMS = %w[return_to code_challenge code_challenge_method].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      match = PATH.match(env["PATH_INFO"].to_s)
      return @app.call(env) unless match && provider?(match[:provider])

      request = Rack::Request.new(env)
      params = request.GET

      unless RedirectPolicy.allowed_redirect_uri?(params["return_to"])
        return error(400, "invalid_return_to",
                     "return_to is missing or not in OAUTH_REDIRECT_ALLOWLIST")
      end

      unless RedirectPolicy.valid_challenge?(params["code_challenge"], params["code_challenge_method"])
        return error(400, "invalid_code_challenge",
                     "code_challenge (PKCE, S256) is missing or malformed")
      end

      env["QUERY_STRING"] = Rack::Utils.build_query(params.slice(*ALLOWED_PARAMS))
      env.delete("rack.request.query_hash")
      env.delete("rack.request.query_string")
      env.delete("action_dispatch.request.query_parameters")
      @app.call(env)
    end

    private

    def provider?(name)
      Devise.omniauth_providers.map(&:to_s).include?(name)
    end

    def error(status, code, message)
      body = JSON.generate(error: { code: code, message: message })
      [status, { "Content-Type" => "application/json; charset=utf-8" }, [body]]
    end
  end
end
