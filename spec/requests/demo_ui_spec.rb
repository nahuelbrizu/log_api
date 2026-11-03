require "rails_helper"

RSpec.describe "Demo UI", type: :request do
  it "serves the static page at /ui/" do
    get "/ui/"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
    expect(response.body).to include('<script src="/ui/app.js">')
  end

  describe "DEMO_UI setting (config/initializers/auth.rb)" do
    let(:initializer) { Rails.root.join("config/initializers/auth.rb") }
    let(:keys) { %w[DEMO_UI API_URL OAUTH_REDIRECT_ALLOWLIST CONFIRMATION_URL RESET_PASSWORD_URL FRONTEND_URL] }

    # Re-evaluates the initializer under the given ENV and restores both ENV
    # and config.x.auth afterwards.
    def with_auth_config(env)
      saved_env = keys.to_h { |k| [k, ENV[k]] }
      saved_config = Rails.configuration.x.auth.dup
      keys.each { |k| ENV.delete(k) }
      env.each { |k, v| ENV[k] = v }
      load initializer
      yield Rails.configuration.x.auth
    ensure
      saved_env.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      Rails.configuration.x.auth = saved_config
    end

    it "when on, allows the UI as OAuth return and points email links at it" do
      with_auth_config("DEMO_UI" => "true", "API_URL" => "https://api.example.com") do |auth|
        expect(auth.oauth_redirect_allowlist).to include("https://api.example.com/ui/")
        expect(auth.confirmation_url).to eq("https://api.example.com/ui/")
        expect(auth.reset_password_url).to eq("https://api.example.com/ui/")
      end
    end

    it "when on, keeps explicitly configured email pages" do
      with_auth_config("DEMO_UI" => "true", "RESET_PASSWORD_URL" => "https://app.example.com/reset",
                       "CONFIRMATION_URL" => "https://app.example.com/confirm") do |auth|
        expect(auth.reset_password_url).to eq("https://app.example.com/reset")
        expect(auth.confirmation_url).to eq("https://app.example.com/confirm")
      end
    end

    it "when off, does not touch the allowlist or the email links" do
      with_auth_config("DEMO_UI" => "false", "API_URL" => "https://api.example.com",
                       "FRONTEND_URL" => "https://app.example.com") do |auth|
        expect(auth.oauth_redirect_allowlist).to eq(["https://app.example.com/oauth/callback"])
        expect(auth.confirmation_url).to be_nil
        expect(auth.reset_password_url).to eq("https://app.example.com/reset-password")
      end
    end
  end
end
