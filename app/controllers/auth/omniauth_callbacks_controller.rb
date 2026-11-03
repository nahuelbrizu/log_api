module Auth
  # End of the social login flow (GET /auth/:provider/callback).
  #
  # OmniAuth has already verified the provider's `state` param against the
  # handshake cookie. Here we find/create the user, mint a one-time code
  # bound to the PKCE challenge, and redirect the browser back to the
  # allowlisted return_to URI with ?code=... (never with the tokens).
  # Errors are reported to the same URI as ?error=...
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    User::OAUTH_PROVIDERS.each do |provider|
      define_method(provider) { handle_callback }
    end

    # Provider denied access, `state` mismatch, network error, ...
    def failure
      error = request.env["omniauth.error.type"] || "authentication_failed"
      redirect_or_render(:unauthorized, "oauth_failed", "Social login failed: #{error}",
                         redirect_error: "access_denied")
    end

    private

    def handle_callback
      flow = request.env["omniauth.params"] || {}
      redirect_uri = flow["return_to"]
      unless Oauth::RedirectPolicy.allowed_redirect_uri?(redirect_uri) &&
             Oauth::RedirectPolicy.valid_challenge?(flow["code_challenge"], flow["code_challenge_method"])
        return render_error(:bad_request, "invalid_oauth_flow",
                            "Login was not started with a valid return_to and code_challenge")
      end

      user = User.from_omniauth(request.env["omniauth.auth"])
      unless user.persisted? && user.errors.empty?
        return redirect_or_render(:unprocessable_entity, "oauth_account_conflict",
                                  user.errors.full_messages.to_sentence.presence || "Could not sign in",
                                  redirect_error: "account_conflict")
      end

      code = OauthCode.issue!(user: user, code_challenge: flow["code_challenge"], redirect_uri: redirect_uri)
      redirect_to Oauth::RedirectPolicy.build_redirect(redirect_uri, code: code), allow_other_host: true
    end

    def redirect_or_render(status, code, message, redirect_error:)
      redirect_uri = (request.env["omniauth.params"] || {})["return_to"]
      if Oauth::RedirectPolicy.allowed_redirect_uri?(redirect_uri)
        redirect_to Oauth::RedirectPolicy.build_redirect(redirect_uri, error: redirect_error),
                    allow_other_host: true
      else
        render_error status, code, message
      end
    end
  end
end
