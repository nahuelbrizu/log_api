module Auth
  # GET|POST /auth/confirmation      { "confirmation_token": "..." }
  # POST     /auth/confirmation/resend { "email": "..." }
  class ConfirmationsController < ApplicationController
    def create
      user = User.confirm_by_token(params.require(:confirmation_token))

      if user.errors.empty?
        render json: { message: "Email confirmed. You can sign in now.", user: UserSerializer.call(user) }
      elsif user.errors.of_kind?(:email, :already_confirmed)
        render_error :unprocessable_entity, "already_confirmed", "Email was already confirmed"
      else
        render_error :unprocessable_entity, "invalid_token", "Confirmation token is invalid or expired"
      end
    end

    # Always 202, whether or not the email exists or is already confirmed.
    def resend
      user = User.find_for_authentication(email: params.require(:email))
      user.send_confirmation_instructions if user && !user.confirmed?

      render json: { message: "If the account exists and is unconfirmed, a new link has been sent." },
             status: :accepted
    end
  end
end
