require "rails_helper"

RSpec.describe "Email confirmation", type: :request do
  let!(:user) { create(:user, :unconfirmed) }
  let(:token) do
    user.send_confirmation_instructions
    last_email.body.to_s[/confirmation_token=([\w-]+)/, 1]
  end

  it "confirms with the token from the email (POST)" do
    json_post "/auth/confirmation", confirmation_token: token

    expect(response).to have_http_status(:ok)
    expect(json.dig("user", "confirmed")).to be(true)
    expect(user.reload).to be_confirmed
  end

  it "confirms via the GET link in the email" do
    get "/auth/confirmation", params: { confirmation_token: token }
    expect(response).to have_http_status(:ok)
    expect(user.reload).to be_confirmed
  end

  it "rejects an invalid token" do
    json_post "/auth/confirmation", confirmation_token: "nope"
    expect_error(:unprocessable_entity, "invalid_token")
  end

  it "reports an already confirmed account" do
    t = token
    json_post "/auth/confirmation", confirmation_token: t
    json_post "/auth/confirmation", confirmation_token: t
    expect_error(:unprocessable_entity, "already_confirmed")
  end

  describe "resend" do
    it "sends a new link to unconfirmed accounts" do
      json_post "/auth/confirmation/resend", email: user.email
      expect(response).to have_http_status(:accepted)
      expect(last_email.to).to eq([user.email])
    end

    it "answers the same for unknown emails without sending anything" do
      ActionMailer::Base.deliveries.clear
      json_post "/auth/confirmation/resend", email: "ghost@example.com"
      expect(response).to have_http_status(:accepted)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
