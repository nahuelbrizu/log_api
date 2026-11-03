require "rails_helper"

RSpec.describe "Social login (OAuth)", type: :request do
  let(:verifier_and_challenge) { pkce_pair }
  let(:verifier) { verifier_and_challenge.first }
  let(:challenge) { verifier_and_challenge.last }

  describe "starting the flow" do
    it "rejects a return_to that is not allowlisted" do
      get "/auth/github", params: { return_to: "https://evil.example/cb", code_challenge: challenge }
      expect_error(:bad_request, "invalid_return_to")
    end

    it "rejects prefix tricks on an allowed URI" do
      get "/auth/github", params: { return_to: "#{OmniauthHelpers::REDIRECT_URI}/../evil",
                                    code_challenge: challenge }
      expect_error(:bad_request, "invalid_return_to")
    end

    it "requires a PKCE challenge" do
      get "/auth/github", params: { return_to: OmniauthHelpers::REDIRECT_URI }
      expect_error(:bad_request, "invalid_code_challenge")
    end

    it "rejects the plain PKCE method" do
      get "/auth/github", params: { return_to: OmniauthHelpers::REDIRECT_URI,
                                    code_challenge: challenge, code_challenge_method: "plain" }
      expect_error(:bad_request, "invalid_code_challenge")
    end
  end

  describe "callback + code exchange" do
    before { mock_github }

    it "redirects with a one-time code (no tokens in the URL) that exchanges for tokens" do
      location = run_oauth_flow(:github, challenge: challenge)

      expect(location).to start_with("#{OmniauthHelpers::REDIRECT_URI}?code=")
      expect(location).not_to include("access_token", "refresh_token")

      json_post "/auth/oauth/token", code: code_from(location), code_verifier: verifier,
                                     return_to: OmniauthHelpers::REDIRECT_URI
      expect(response).to have_http_status(:ok)
      expect(json.dig("user", "email")).to eq("octo@example.com")
      expect(json.dig("user", "provider")).to eq("github")

      get "/me", headers: auth_header(json["access_token"])
      expect(response).to have_http_status(:ok)
    end

    it "works with a custom-scheme redirect for mobile apps" do
      location = run_oauth_flow(:github, challenge: challenge, redirect_uri: "myapp://oauth")
      expect(location).to start_with("myapp://oauth?code=")
    end

    it "creates a confirmed user once and reuses it on later logins" do
      expect { run_oauth_flow(:github, challenge: challenge) }.to change(User, :count).by(1)
      expect(User.last).to be_confirmed
      expect { run_oauth_flow(:github, challenge: challenge) }.not_to change(User, :count)
    end

    it "codes are single use" do
      code = code_from(run_oauth_flow(:github, challenge: challenge))
      body = { code: code, code_verifier: verifier, return_to: OmniauthHelpers::REDIRECT_URI }

      json_post "/auth/oauth/token", body
      expect(response).to have_http_status(:ok)
      json_post "/auth/oauth/token", body
      expect_error(:bad_request, "invalid_grant")
    end

    it "rejects a wrong PKCE verifier (and burns the code)" do
      code = code_from(run_oauth_flow(:github, challenge: challenge))

      json_post "/auth/oauth/token", code: code, code_verifier: pkce_pair.first,
                                     return_to: OmniauthHelpers::REDIRECT_URI
      expect_error(:bad_request, "invalid_grant")

      json_post "/auth/oauth/token", code: code, code_verifier: verifier,
                                     return_to: OmniauthHelpers::REDIRECT_URI
      expect_error(:bad_request, "invalid_grant")
    end

    it "rejects a different return_to" do
      code = code_from(run_oauth_flow(:github, challenge: challenge))
      json_post "/auth/oauth/token", code: code, code_verifier: verifier, return_to: "myapp://oauth"
      expect_error(:bad_request, "invalid_grant")
    end

    it "rejects expired codes" do
      code = code_from(run_oauth_flow(:github, challenge: challenge))
      travel 2.minutes do
        json_post "/auth/oauth/token", code: code, code_verifier: verifier,
                                       return_to: OmniauthHelpers::REDIRECT_URI
        expect_error(:bad_request, "invalid_grant")
      end
    end

    it "fails the callback if the flow was not started through the guard" do
      get "/auth/github/callback"
      expect_error(:bad_request, "invalid_oauth_flow")
    end
  end

  describe "account linking" do
    it "links an existing password account when the provider verified the email" do
      user = create(:user, email: "gina@example.com")
      mock_google(email: "gina@example.com", email_verified: true)

      location = run_oauth_flow(:google_oauth2, challenge: challenge)
      expect(code_from(location)).to be_present
      expect(user.reload.provider).to eq("google_oauth2")
    end

    it "refuses to link when the provider did not verify the email" do
      user = create(:user, email: "gina@example.com")
      mock_google(email: "gina@example.com", email_verified: false)

      location = run_oauth_flow(:google_oauth2, challenge: challenge)
      expect(location).to eq("#{OmniauthHelpers::REDIRECT_URI}?error=account_conflict")
      expect(user.reload.provider).to eq("")
    end

    it "refuses to link an account already linked to another provider" do
      create(:user, :github, email: "gina@example.com")
      mock_google(email: "gina@example.com", email_verified: true)

      location = run_oauth_flow(:google_oauth2, challenge: challenge)
      expect(location).to include("error=account_conflict")
    end
  end

  it "redirects provider failures back to the client with an error" do
    OmniAuth.config.mock_auth[:github] = :access_denied
    location = run_oauth_flow(:github, challenge: challenge)
    expect(location).to eq("#{OmniauthHelpers::REDIRECT_URI}?error=access_denied")
  end

  it "lists the enabled providers" do
    get "/auth/providers"
    expect(response).to have_http_status(:ok)
    expect(json["providers"].map { |p| p["name"] }).to include("github", "google_oauth2")
  end
end
