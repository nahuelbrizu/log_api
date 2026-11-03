require "rails_helper"

RSpec.describe Oauth::RequestGuard do
  let(:seen) { {} }
  let(:app) { ->(env) { seen[:query] = Rack::Request.new(env).GET; [200, {}, ["ok"]] } }
  let(:guard) { described_class.new(app) }
  let(:challenge) { "a" * 43 }

  before do
    Rails.configuration.x.auth.oauth_redirect_allowlist = ["http://localhost:5173/oauth/callback"]
  end

  def call(path)
    guard.call(Rack::MockRequest.env_for(path))
  end

  it "passes only the known params on to OmniAuth" do
    status, = call("/auth/github?return_to=http%3A%2F%2Flocalhost%3A5173%2Foauth%2Fcallback" \
                   "&code_challenge=#{challenge}&redirect_uri=https://evil.example&state=x&scope=repo")

    expect(status).to eq(200)
    expect(seen[:query].keys).to contain_exactly("return_to", "code_challenge")
  end

  it "does not touch other paths" do
    status, = call("/auth/sign_in?redirect_uri=whatever")
    expect(status).to eq(200)
    expect(seen[:query]).to eq("redirect_uri" => "whatever")
  end

  it "does not touch provider callbacks" do
    status, = call("/auth/github/callback?code=abc&state=xyz")
    expect(status).to eq(200)
  end
end
