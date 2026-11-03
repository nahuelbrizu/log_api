require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let!(:owner) { create(:user) }
  let!(:other) { create(:user) }
  let(:owner_headers) { auth_header(access_token_for(owner)) }
  let(:other_headers) { auth_header(access_token_for(other)) }

  it "requires authentication" do
    get "/profiles"
    expect_error(:unauthorized, "unauthorized")
  end

  describe "POST /profiles" do
    it "creates the current user's profile, ignoring user_id from the request" do
      json_post "/profiles", { display_name: "Me", bio: "Hi", user_id: other.id }, owner_headers

      expect(response).to have_http_status(:created)
      expect(json.dig("profile", "user_id")).to eq(owner.id)
    end

    it "allows only one profile per user" do
      create(:profile, user: owner)
      json_post "/profiles", { display_name: "Again" }, owner_headers
      expect_error(:conflict, "profile_exists")
    end

    it "validates lengths" do
      json_post "/profiles", { display_name: "x" * 101 }, owner_headers
      expect_error(:unprocessable_entity, "validation_failed")
    end
  end

  describe "reading" do
    let!(:profile) { create(:profile, user: owner) }

    it "lists profiles with pagination metadata" do
      create(:profile, user: other)
      get "/profiles", params: { per_page: 1 }, headers: other_headers

      expect(response).to have_http_status(:ok)
      expect(json["profiles"].size).to eq(1)
      expect(json["meta"]).to include("page" => 1, "per_page" => 1, "total" => 2)
    end

    it "shows any profile" do
      get "/profiles/#{profile.id}", headers: other_headers
      expect(response).to have_http_status(:ok)
      expect(json.dig("profile", "id")).to eq(profile.id)
    end

    it "returns 404 JSON for a missing profile" do
      get "/profiles/0", headers: other_headers
      expect_error(:not_found, "not_found")
    end
  end

  describe "updating and deleting" do
    let!(:profile) { create(:profile, user: owner, display_name: "Before") }

    it "lets the owner update" do
      json_patch "/profiles/#{profile.id}", { display_name: "After" }, owner_headers
      expect(response).to have_http_status(:ok)
      expect(profile.reload.display_name).to eq("After")
    end

    it "hides other users' profiles from update (404)" do
      json_patch "/profiles/#{profile.id}", { display_name: "Hacked" }, other_headers
      expect_error(:not_found, "not_found")
      expect(profile.reload.display_name).to eq("Before")
    end

    it "hides other users' profiles from delete (404)" do
      delete "/profiles/#{profile.id}", headers: other_headers
      expect_error(:not_found, "not_found")
      expect(Profile.exists?(profile.id)).to be(true)
    end

    it "lets the owner delete" do
      delete "/profiles/#{profile.id}", headers: owner_headers
      expect(response).to have_http_status(:no_content)
      expect(Profile.exists?(profile.id)).to be(false)
    end
  end
end
