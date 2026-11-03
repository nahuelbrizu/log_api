module Auth
  # POST /auth/oauth/token
  #   { "code": "...", "code_verifier": "...", "redirect_uri": "..." }
  #
  # Exchanges the one-time code delivered to the frontend at the end of a
  # social login for a token pair.
  class OauthTokensController < ApplicationController
    def create
      user = OauthCode.redeem(
        code: params.require(:code),
        code_verifier: params.require(:code_verifier),
        redirect_uri: params.require(:redirect_uri)
      )

      unless user&.active_for_authentication?
        return render_error(:bad_request, "invalid_grant",
                            "Code is invalid, expired, already used, or does not match the verifier")
      end

      user.update_tracked_fields!(request)
      render json: Auth::TokenIssuer.call(user, request: request)
    end
  end
end
