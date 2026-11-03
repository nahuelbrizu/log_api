require "rails_helper"

RSpec.describe "Current user (/me)", type: :request do
  let!(:user) { create(:user, :github, email: "ana@example.com", name: "Ana") }
  let(:headers) { auth_header(access_token_for(user)) }

  describe "GET /me" do
    it "returns the user without sensitive fields" do
      create(:profile, user: user, display_name: "ana")
      get "/me", headers: headers

      expect(response).to have_http_status(:ok)
      body = json["user"]
      expect(body).to include("id" => user.id, "email" => "ana@example.com", "name" => "Ana",
                              "provider" => "github", "confirmed" => true)
      expect(body.dig("profile", "display_name")).to eq("ana")
      expect(body.keys).not_to include("uid", "encrypted_password", "confirmation_token",
                                       "reset_password_token", "current_sign_in_ip")
    end

    it "is 401 without a token" do
      get "/me"
      expect_error(:unauthorized, "unauthorized")
    end

    it "is 401 with a tampered token" do
      get "/me", headers: auth_header("#{access_token_for(user)}x")
      expect_error(:unauthorized, "unauthorized")
    end

    it "is 401 with an expired token" do
      token = access_token_for(user)
      travel 16.minutes do
        get "/me", headers: auth_header(token)
        expect_error(:unauthorized, "unauthorized")
      end
    end

    it "ignores session cookies: only the bearer token authenticates" do
      get "/me", headers: { "Cookie" => "_auth_oauth_handshake=whatever" }
      expect_error(:unauthorized, "unauthorized")
    end
  end

  describe "PATCH /me" do
    let!(:user) { create(:user, name: "Ana") }

    it "updates the name" do
      json_patch "/me", { name: "Ana María" }, headers
      expect(response).to have_http_status(:ok)
      expect(json.dig("user", "name")).to eq("Ana María")
    end

    it "changes the password with the current password and revokes refresh tokens" do
      tokens = sign_in_tokens(user)
      json_patch "/me", { current_password: "s3cure-password", password: "brand-new-pass",
                          password_confirmation: "brand-new-pass" }, headers
      expect(response).to have_http_status(:ok)

      json_post "/auth/refresh", refresh_token: tokens["refresh_token"]
      expect_error(:unauthorized, "invalid_refresh_token")
      sign_in_tokens(user, password: "brand-new-pass")
    end

    it "refuses a password change without the right current password" do
      json_patch "/me", { current_password: "wrong", password: "brand-new-pass",
                          password_confirmation: "brand-new-pass" }, headers
      expect_error(:unprocessable_entity, "validation_failed")
      expect(json.dig("error", "details", "current_password")).to be_present
    end

    it "ignores attributes that are not allowed" do
      json_patch "/me", { email: "evil@example.com", provider: "github" }, headers
      expect(user.reload.email).not_to eq("evil@example.com")
      expect(user.provider).to eq("")
    end
  end

  describe "DELETE /me" do
    it "deletes the account and revokes the token" do
      create(:profile, user: user)
      expect { delete "/me", headers: headers }.to change(User, :count).by(-1)
      expect(response).to have_http_status(:no_content)

      get "/me", headers: headers
      expect_error(:unauthorized, "unauthorized")
    end
  end
end
