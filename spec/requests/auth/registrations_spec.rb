require "rails_helper"

RSpec.describe "Sign up", type: :request do
  it "creates an unconfirmed user and emails a confirmation link" do
    expect {
      json_post "/auth/sign_up", email: "New@Example.com", password: "s3cure-password", name: "Ana"
    }.to change(User, :count).by(1)

    expect(response).to have_http_status(:accepted)
    user = User.last
    expect(user.email).to eq("new@example.com")
    expect(user).not_to be_confirmed
    expect(last_email.to).to eq(["new@example.com"])
    expect(last_email.body.to_s).to include("confirmation_token=")
  end

  it "does not hand out tokens before the email is confirmed" do
    json_post "/auth/sign_up", email: "new@example.com", password: "s3cure-password"
    expect(json).not_to have_key("access_token")
  end

  it "answers the same for an existing email (no enumeration) and notifies its owner" do
    existing = create(:user, email: "taken@example.com")

    expect {
      json_post "/auth/sign_up", email: "taken@example.com", password: "another-password"
    }.not_to change(User, :count)

    expect(response).to have_http_status(:accepted)
    expect(last_email.to).to eq([existing.email])
    expect(last_email.subject).to match(/sign-up attempt/i)
  end

  it "resends the confirmation when the existing account is unconfirmed" do
    create(:user, :unconfirmed, email: "pending@example.com")
    json_post "/auth/sign_up", email: "pending@example.com", password: "another-password"

    expect(response).to have_http_status(:accepted)
    expect(last_email.body.to_s).to include("confirmation_token=")
  end

  it "rejects short passwords with a validation error" do
    json_post "/auth/sign_up", email: "new@example.com", password: "short"

    expect_error(:unprocessable_entity, "validation_failed")
    expect(json.dig("error", "details", "password")).to be_present
  end

  it "rejects a password equal to the email" do
    json_post "/auth/sign_up", email: "same@example.com", password: "same@example.com"
    expect_error(:unprocessable_entity, "validation_failed")
  end

  it "requires email and password" do
    json_post "/auth/sign_up", email: "new@example.com"
    expect_error(:bad_request, "parameter_missing")
  end
end
