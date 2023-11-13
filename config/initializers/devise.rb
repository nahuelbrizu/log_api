# frozen_string_literal: true

Devise.setup do |config|

  require 'devise/orm/active_record'
  config.omniauth :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  config.sign_out_via = :get
  config.mailer_sender = '<mailgun email domain>'
  config.parent_mailer = 'ActionMailer::Base'
  config.reconfirmable = false
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

end
