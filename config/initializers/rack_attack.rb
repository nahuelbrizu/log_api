# frozen_string_literal: true

# Throttles for the endpoints attackers care about (credential stuffing,
# signup spam, email bombing). Limits are per IP and, where the request
# names an account, per email too.
#
# The counters live in Rails.cache. With several app servers, point
# Rails.cache at a shared store (Redis/Memcached), or limits become per process.
class Rack::Attack
  self.cache.store =
    if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
      ActiveSupport::Cache::MemoryStore.new
    else
      Rails.cache
    end

  # Parses JSON bodies too (Rack::Request#params only reads form bodies).
  def self.email_param(req)
    email = ActionDispatch::Request.new(req.env).params["email"]
    email.to_s.downcase.strip.presence
  rescue ActionDispatch::Http::Parameters::ParseError
    nil
  end

  RULES = {
    # name               method    path                          limit period
    "sign_in"         => ["POST",  "/auth/sign_in",              10, 1.minute],
    "sign_up"         => ["POST",  "/auth/sign_up",              5,  1.minute],
    "password"        => ["POST",  "/auth/password",             5,  1.minute],
    "password_reset"  => ["PUT",   "/auth/password",             10, 1.minute],
    "confirm_resend"  => ["POST",  "/auth/confirmation/resend",  5,  1.minute],
    "refresh"         => ["POST",  "/auth/refresh",              30, 1.minute],
    "oauth_token"     => ["POST",  "/auth/oauth/token",          20, 1.minute]
  }.freeze

  RULES.each do |name, (verb, path, limit, period)|
    throttle("#{name}/ip", limit: limit, period: period) do |req|
      req.ip if req.request_method == verb && req.path == path
    end
  end

  # Per-account limits: slow down attacks spread across many IPs.
  {
    "sign_in/email" => ["/auth/sign_in", 5, 1.minute],
    "password/email" => ["/auth/password", 5, 1.hour],
    "confirm_resend/email" => ["/auth/confirmation/resend", 5, 1.hour]
  }.each do |name, (path, limit, period)|
    throttle(name, limit: limit, period: period) do |req|
      email_param(req) if req.post? && req.path == path
    end
  end

  # Starting OAuth logins (/auth/:provider, not the callback).
  throttle("oauth_start/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.get? && req.path.match?(%r{\A/auth/(google_oauth2|facebook|github|twitter)/?\z})
  end

  self.throttled_responder = lambda do |request|
    match = request.env["rack.attack.match_data"] || {}
    retry_after = (match[:period] || 60).to_i
    body = { error: { code: "rate_limited", message: "Too many requests. Retry later." } }
    [429, { "Content-Type" => "application/json; charset=utf-8", "Retry-After" => retry_after.to_s },
     [body.to_json]]
  end
end

Rack::Attack.enabled = !Rails.env.test?

# Validates redirect_uri / PKCE params before OmniAuth starts a login. It
# runs after the throttles and before the OmniAuth strategies, which Devise
# appends to the stack later during boot.
require Rails.root.join("lib/oauth/request_guard").to_s
Rails.application.config.middleware.insert_after Rack::Attack, Oauth::RequestGuard
