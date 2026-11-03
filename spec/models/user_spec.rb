require "rails_helper"

RSpec.describe User, type: :model do
  def auth_hash(provider:, uid:, email:, verified: true)
    OmniAuth::AuthHash.new(provider: provider, uid: uid, info: { email: email, name: "X" },
                           extra: { raw_info: { email_verified: verified } })
  end

  describe ".from_omniauth" do
    it "rejects providers that do not return an email" do
      user = described_class.from_omniauth(auth_hash(provider: "twitter", uid: "1", email: nil))
      expect(user).not_to be_persisted
      expect(user.errors[:email]).to be_present
    end

    it "never links via providers that do not verify emails (twitter)" do
      create(:user, email: "tw@example.com")
      user = described_class.from_omniauth(auth_hash(provider: "twitter", uid: "1", email: "tw@example.com"))
      expect(user.errors[:email]).to be_present
      expect(user.reload.provider).to eq("")
    end

    it "creates confirmed users with a random password" do
      user = described_class.from_omniauth(
        OmniAuth::AuthHash.new(provider: "github", uid: "9", info: { email: "n@example.com", name: "N" })
      )
      expect(user).to be_persisted
      expect(user).to be_confirmed
      expect(user.name).to eq("N")
      expect(user.encrypted_password).to be_present
    end
  end

  it "replaces the password of an unconfirmed account when linking it (pre-hijack protection)" do
    squatter = create(:user, :unconfirmed, email: "victim@example.com", password: "attacker-pass-1")
    described_class.from_omniauth(auth_hash(provider: "google_oauth2", uid: "g", email: "victim@example.com"))

    squatter.reload
    expect(squatter).to be_confirmed
    expect(squatter.provider).to eq("google_oauth2")
    expect(squatter.valid_password?("attacker-pass-1")).to be(false)
  end

  it "keeps the password of a confirmed account when linking it" do
    owner = create(:user, email: "owner@example.com")
    described_class.from_omniauth(auth_hash(provider: "google_oauth2", uid: "g2", email: "owner@example.com"))
    expect(owner.reload.valid_password?("s3cure-password")).to be(true)
  end

  it "caps passwords at 72 characters (bcrypt limit)" do
    expect(build(:user, password: "a1" * 37)).not_to be_valid
  end
end
