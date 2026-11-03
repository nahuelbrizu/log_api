module Auth
  # POST /auth/refresh { "refresh_token": "..." } -> new token pair.
  # The presented refresh token is rotated (single use).
  class TokensController < ApplicationController
    def create
      user, new_refresh = RefreshToken.rotate!(params.require(:refresh_token), request: request)

      unless user.active_for_authentication?
        RefreshToken.revoke_all_for!(user)
        raise RefreshToken::InvalidToken
      end

      render json: Auth::TokenIssuer.call(user, request: request, refresh_token: new_refresh)
    rescue RefreshToken::InvalidToken
      render_error :unauthorized, "invalid_refresh_token", "Refresh token is invalid, expired or revoked"
    end
  end
end
