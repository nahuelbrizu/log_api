OmniAuth.config.test_mode = true

module OmniauthHelpers
  REDIRECT_URI = "http://localhost:5173/oauth/callback".freeze

  def mock_github(uid: "12345", email: "octo@example.com", name: "Octo Cat")
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: uid, info: { email: email, name: name }
    )
  end

  def mock_google(uid: "g-1", email: "gina@example.com", email_verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: uid, info: { email: email, name: "Gina" },
      extra: { raw_info: { email_verified: email_verified } }
    )
  end

  def pkce_pair
    verifier = SecureRandom.urlsafe_base64(48)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    [verifier, challenge]
  end

  # Runs the browser part of the flow and returns the redirect Location.
  def run_oauth_flow(provider, challenge:, redirect_uri: REDIRECT_URI)
    get "/auth/#{provider}", params: { return_to: redirect_uri, code_challenge: challenge,
                                       code_challenge_method: "S256" }
    expect(response).to have_http_status(:redirect)
    follow_redirect! # -> /auth/:provider/callback
    response.location
  end

  def code_from(location)
    Rack::Utils.parse_query(URI(location).query)["code"]
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers, type: :request
  config.before(type: :request) do
    Rails.configuration.x.auth.oauth_redirect_allowlist = [OmniauthHelpers::REDIRECT_URI, "myapp://oauth"]
  end
  config.after { OmniAuth.config.mock_auth.except!(:github, :google_oauth2) }
end
