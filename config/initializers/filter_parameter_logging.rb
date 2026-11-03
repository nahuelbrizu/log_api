# Be sure to restart your server when you modify this file.

# Keep credentials and one-time secrets out of the logs. Partial matches:
# :token also covers access_token, refresh_token, confirmation_token and
# reset_password_token. `code` is the OAuth/one-time code, matched exactly.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :authorization, :code_verifier, :code_challenge, :state, /\Acode\z/
]
