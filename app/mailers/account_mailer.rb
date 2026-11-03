# Sent when someone tries to sign up with an email that already has a
# confirmed account (the API answers the same either way, see
# Auth::RegistrationsController).
class AccountMailer < ApplicationMailer
  def sign_up_attempt(user)
    @user = user
    @frontend_url = Rails.configuration.x.auth.frontend_url
    mail to: user.email, subject: "Sign-up attempt with your email"
  end
end
