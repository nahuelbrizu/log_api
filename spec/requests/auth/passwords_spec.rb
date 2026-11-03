require "rails_helper"

RSpec.describe "Password reset", type: :request do
  let!(:user) { create(:user, email: "ana@example.com") }

  def reset_token
    json_post "/auth/password", email: user.email
    last_email.body.to_s[/reset_password_token=([\w-]+)/, 1]
  end

  it "emails reset instructions" do
    json_post "/auth/password", email: "ana@example.com"
    expect(response).to have_http_status(:accepted)
    expect(last_email.to).to eq(["ana@example.com"])
  end

  it "answers the same for unknown emails" do
    json_post "/auth/password", email: "ghost@example.com"
    expect(response).to have_http_status(:accepted)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "sets a new password and revokes existing refresh tokens" do
    old_tokens = sign_in_tokens(user)
    token = reset_token

    json_put "/auth/password", reset_password_token: token, password: "brand-new-pass",
                               password_confirmation: "brand-new-pass"
    expect(response).to have_http_status(:ok)

    json_post "/auth/refresh", refresh_token: old_tokens["refresh_token"]
    expect_error(:unauthorized, "invalid_refresh_token")

    sign_in_tokens(user, password: "brand-new-pass")
  end

  it "rejects an invalid token" do
    json_put "/auth/password", reset_password_token: "nope", password: "brand-new-pass",
                               password_confirmation: "brand-new-pass"
    expect_error(:unprocessable_entity, "invalid_token")
  end

  it "validates the new password" do
    json_put "/auth/password", reset_password_token: reset_token, password: "short",
                               password_confirmation: "short"
    expect_error(:unprocessable_entity, "validation_failed")
  end
end
