source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/nahuelbrizu/#{repo}.git" }

ruby "3.0.3"

gem "rails", "~> 7.0.8"
gem "puma", "~> 5.0"
gem 'rspec-rails'
gem 'devise'
gem 'omniauth-github'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'
gem 'omniauth-facebook'
gem 'dotenv-rails', groups: [:development, :test]
gem 'activerecord-session_store'
gem 'mailgun-ruby'
gem 'stripe'
gem 'jquery-rails'
gem "omniauth-rails_csrf_protection"
gem 'rack-cors'

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :production do
  gem "mysql2", "~> 0.5"
end
