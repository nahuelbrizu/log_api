module Auth
  # POST /auth/password { "email": "..." }  -> sends reset instructions
  # PUT  /auth/password { "reset_password_token", "password", "password_confirmation" }
  class PasswordsController < ApplicationController
    # Always 202 so the endpoint cannot be used to discover accounts.
    def create
      User.send_reset_password_instructions(email: params.require(:email))
      render json: { message: "If the account exists, reset instructions have been sent." },
             status: :accepted
    end

    def update
      params.require(:reset_password_token)
      params.require(:password)
      user = User.reset_password_by_token(
        params.permit(:reset_password_token, :password, :password_confirmation).to_h
      )

      if user.errors.empty?
        RefreshToken.revoke_all_for!(user)
        render json: { message: "Password updated. Sign in with the new password." }
      elsif user.errors.include?(:reset_password_token)
        render_error :unprocessable_entity, "invalid_token", "Reset password token is invalid or expired"
      else
        render_validation_errors(user)
      end
    end
  end
end
