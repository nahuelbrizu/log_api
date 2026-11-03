# frozen_string_literal: true

require "base64"
require "digest"

module Oauth
  # Rules shared by the OmniAuth request guard (start of the flow), the
  # callback (end of the flow) and the code exchange endpoint.
  module RedirectPolicy
    # RFC 7636: verifier is 43-128 chars of the unreserved set; an S256
    # challenge is a 43-char base64url string (we accept up to 128).
    VERIFIER_FORMAT  = /\A[A-Za-z0-9\-._~]{43,128}\z/
    CHALLENGE_FORMAT = /\A[A-Za-z0-9\-_]{43,128}\z/

    module_function

    def allowlist
      Rails.configuration.x.auth.oauth_redirect_allowlist
    end

    # Exact string match, as required by OAuth 2.1: no prefix or wildcard
    # matching, so an attacker cannot point the one-time code at a page they
    # control on an allowed host.
    def allowed_redirect_uri?(uri)
      uri.is_a?(String) && !uri.include?("#") && allowlist.include?(uri)
    end

    def valid_challenge?(challenge, method)
      (method.blank? || method == "S256") &&
        challenge.is_a?(String) && challenge.match?(CHALLENGE_FORMAT)
    end

    def verifier_matches?(verifier, challenge)
      return false unless verifier.is_a?(String) && verifier.match?(VERIFIER_FORMAT)

      computed = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
      ActiveSupport::SecurityUtils.secure_compare(computed, challenge.to_s)
    end

    # Appends query params to a (possibly custom-scheme) redirect URI.
    def build_redirect(uri, params)
      parsed = URI.parse(uri)
      query = URI.decode_www_form(parsed.query.to_s) + params.compact.map { |k, v| [k.to_s, v.to_s] }
      parsed.query = URI.encode_www_form(query)
      parsed.to_s
    end
  end
end
