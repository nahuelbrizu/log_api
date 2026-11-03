require "rails_helper"

RSpec.describe "Sign in / sign out", type: :request do
  let!(:user) { create(:user, email: "ana@example.com") }

  describe "POST /auth/sign_in" do
    it "returns an access token, a refresh token and the user" do
      json_post "/auth/sign_in", email: "ANA@example.com", password: "s3cure-password"

      expect(response).to have_http_status(:ok)
      expect(json).to include("token_type" => "Bearer", "expires_in" => 15 * 60)
      expect(json["access_token"]).to be_present
      expect(json["refresh_token"]).to be_present
      expect(json.dig("user", "email")).to eq("ana@example.com")
      expect(user.reload.sign_in_count).to eq(1)
    end

    it "returns the same error for a wrong password and an unknown email" do
      json_post "/auth/sign_in", email: "ana@example.com", password: "wrong-password"
      expect_error(:unauthorized, "invalid_credentials")
      wrong_password_body = response.body

      json_post "/auth/sign_in", email: "ghost@example.com", password: "wrong-password"
      expect_error(:unauthorized, "invalid_credentials")
      expect(response.body).to eq(wrong_password_body)
    end

    it "refuses unconfirmed accounts" do
      create(:user, :unconfirmed, email: "pending@example.com")
      json_post "/auth/sign_in", email: "pending@example.com", password: "s3cure-password"
      expect_error(:forbidden, "unconfirmed")
    end

    it "does not set any authentication cookie" do
      json_post "/auth/sign_in", email: "ana@example.com", password: "s3cure-password"
      expect(response.headers["Set-Cookie"]).to be_nil
    end
  end

  describe "DELETE /auth/sign_out" do
    it "revokes the access token and the given refresh token" do
      tokens = sign_in_tokens(user)
      headers = auth_header(tokens["access_token"])

      json_delete "/auth/sign_out", { refresh_token: tokens["refresh_token"] }, headers
      expect(response).to have_http_status(:no_content)

      get "/me", headers: headers
      expect_error(:unauthorized, "unauthorized")

      json_post "/auth/refresh", refresh_token: tokens["refresh_token"]
      expect_error(:unauthorized, "invalid_refresh_token")
    end

    it "with all=true revokes every refresh token of the user" do
      first = sign_in_tokens(user)
      second = sign_in_tokens(user)

      json_delete "/auth/sign_out", { all: true }, auth_header(first["access_token"])
      expect(response).to have_http_status(:no_content)

      json_post "/auth/refresh", refresh_token: second["refresh_token"]
      expect_error(:unauthorized, "invalid_refresh_token")
    end

    it "requires a valid access token" do
      json_delete "/auth/sign_out"
      expect_error(:unauthorized, "unauthorized")
    end
  end
end
