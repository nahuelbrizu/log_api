require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.reset!
    Rack::Attack.enabled = false
  end

  it "throttles repeated sign-in attempts for the same email with a JSON 429" do
    6.times { json_post "/auth/sign_in", email: "ana@example.com", password: "wrong-password" }

    expect_error(:too_many_requests, "rate_limited")
    expect(response.headers["Retry-After"]).to be_present
  end

  it "throttles sign-ups per IP" do
    6.times { |i| json_post "/auth/sign_up", email: "u#{i}@example.com", password: "s3cure-password" }
    expect_error(:too_many_requests, "rate_limited")
  end
end
