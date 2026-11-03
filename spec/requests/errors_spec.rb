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
