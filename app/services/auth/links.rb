module Auth
  # URLs embedded in the emails. They point at the frontend when it has a
  # page for the flow, and at this API otherwise.
  module Links
    module_function

    def confirmation(token)
      base = Rails.configuration.x.auth.confirmation_url ||
             "#{Rails.configuration.x.auth.api_url}/auth/confirmation"
      Oauth::RedirectPolicy.build_redirect(base, confirmation_token: token)
    end

    def reset_password(token)
      Oauth::RedirectPolicy.build_redirect(Rails.configuration.x.auth.reset_password_url,
                                           reset_password_token: token)
    end
  end
end
