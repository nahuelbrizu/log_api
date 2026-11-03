require "rails_helper"

RSpec.describe "Health, errors and CORS", type: :request do
  it "GET /up is a health check" do
    get "/up"
    expect(response).to have_http_status(:ok)
    expect(json).to eq("status" => "ok")
  end

  it "rejects malformed JSON with the standard error envelope" do
    post "/auth/sign_in", params: "{not json", headers: json_headers
    expect_error(:bad_request, "invalid_json")
  end

  it "answers CORS preflight for allowed origins and exposes Authorization" do
    options "/auth/sign_in", headers: {
      "Origin" => "http://localhost:5173",
      "Access-Control-Request-Method" => "POST",
      "Access-Control-Request-Headers" => "content-type,authorization"
    }
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:5173")

    get "/up", headers: { "Origin" => "http://localhost:5173" }
    expect(response.headers["Access-Control-Expose-Headers"]).to include("Authorization")
  end

  it "does not allow other origins" do
    get "/up", headers: { "Origin" => "https://evil.example" }
    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end
end

RSpec.describe "Error pages in production mode", type: :request do
  around do |example|
    env_config = Rails.application.env_config
    original = env_config.slice("action_dispatch.show_exceptions", "action_dispatch.show_detailed_exceptions")
    env_config["action_dispatch.show_exceptions"] = true
    env_config["action_dispatch.show_detailed_exceptions"] = false
    example.run
  ensure
    env_config.merge!(original)
  end

  it "renders unknown routes as the JSON error envelope" do
    get "/does-not-exist"
    expect(response).to have_http_status(:not_found)
    expect(json).to eq("error" => { "code" => "not_found", "message" => "Not Found" })
  end
end
