module Auth
  # POST /auth/sign_up
  #
  # To avoid account enumeration the response is the same 202 whether or not
  # the email is already registered. New users get a confirmation email;
  # owners of an existing account get a notice (or a fresh confirmation link
  # if they never confirmed).
  class RegistrationsController < ApplicationController
    def create
      user = User.new(sign_up_params)

      if user.save
        accepted
      elsif email_taken_only?(user)
        notify_existing_account(user.email)
        accepted
      else
        render_validation_errors(user)
      end
    end

    private

    def sign_up_params
      params.require(:email)
      params.require(:password)
      params.permit(:email, :password, :password_confirmation, :name)
    end

    def email_taken_only?(user)
      user.errors.attribute_names == [:email] && user.errors.of_kind?(:email, :taken)
    end

    def notify_existing_account(email)
      existing = User.find_for_authentication(email: email)
      return unless existing

      if existing.confirmed?
        AccountMailer.sign_up_attempt(existing).deliver_now
      else
        existing.send_confirmation_instructions
      end
    end

    def accepted
      render json: { message: "If the email can be registered, a confirmation link has been sent to it." },
             status: :accepted
    end
  end
end
