require "rails_helper"

RSpec.describe "Refresh tokens", type: :request do
  let!(:user) { create(:user) }
  let!(:tokens) { sign_in_tokens(user) }

  it "rotates: returns a new pair and invalidates the old refresh token" do
    json_post "/auth/refresh", refresh_token: tokens["refresh_token"]

    expect(response).to have_http_status(:ok)
    expect(json["access_token"]).to be_present
    expect(json["refresh_token"]).not_to eq(tokens["refresh_token"])

    get "/me", headers: auth_header(json["access_token"])
    expect(response).to have_http_status(:ok)
  end

  it "revokes the whole family when a rotated token is reused" do
    json_post "/auth/refresh", refresh_token: tokens["refresh_token"]
    rotated = json["refresh_token"]

    json_post "/auth/refresh", refresh_token: tokens["refresh_token"] # replay
    expect_error(:unauthorized, "invalid_refresh_token")

    json_post "/auth/refresh", refresh_token: rotated
    expect_error(:unauthorized, "invalid_refresh_token")
  end

  it "rejects expired refresh tokens" do
    travel 31.days do
      json_post "/auth/refresh", refresh_token: tokens["refresh_token"]
      expect_error(:unauthorized, "invalid_refresh_token")
    end
  end

  it "rejects unknown refresh tokens" do
    json_post "/auth/refresh", refresh_token: "garbage"
    expect_error(:unauthorized, "invalid_refresh_token")
  end

  it "stores only a digest of the token" do
    expect(RefreshToken.where(token_digest: tokens["refresh_token"])).to be_empty
    expect(RefreshToken.find_by(token_digest: RefreshToken.digest(tokens["refresh_token"]))).to be_present
  end
end
