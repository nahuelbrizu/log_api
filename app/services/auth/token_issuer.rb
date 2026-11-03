module Auth
  # Builds the token pair returned by sign in, refresh and the OAuth code
  # exchange. The access token is a short-lived JWT (devise-jwt); the
  # refresh token is an opaque random string (see RefreshToken).
  class TokenIssuer
    def self.call(user, request:, refresh_token: nil)
      access_token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      refresh_token ||= RefreshToken.issue!(user, request: request).last

      {
        token_type: "Bearer",
        access_token: access_token,
        expires_in: payload["exp"] - payload["iat"],
        refresh_token: refresh_token,
        refresh_token_expires_in: Rails.configuration.x.auth.refresh_token_ttl.to_i,
        user: UserSerializer.call(user)
      }
    end

    # Decodes an access token presented by the client (already verified by
    # the Warden strategy when this is called after authenticate_user!).
    def self.decode(token)
      Warden::JWTAuth::TokenDecoder.new.call(token)
    rescue JWT::DecodeError
      nil
    end
  end
end
