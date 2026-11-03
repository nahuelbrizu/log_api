# Short-lived, single-use code returned to the frontend after a social
# login. It is bound to the return_to URI and PKCE challenge sent when the
# flow started (return_to), so only the client that started the flow can redeem it.
class OauthCode < ApplicationRecord
  belongs_to :user

  scope :expired, -> { where(expires_at: ...Time.current) }

  def self.digest(code)
    Digest::SHA256.hexdigest(code.to_s)
  end

  # Returns the plaintext code.
  def self.issue!(user:, code_challenge:, redirect_uri:)
    code = SecureRandom.urlsafe_base64(32)
    create!(
      user: user,
      code_digest: digest(code),
      code_challenge: code_challenge,
      redirect_uri: redirect_uri,
      expires_at: Rails.configuration.x.auth.oauth_code_ttl.from_now
    )
    code
  end

  # Marks the code used and returns its user, or nil when the code is
  # unknown, expired, already used, or the return_to / PKCE verifier do
  # not match. A code is burnt on the first attempt, even a failed one.
  def self.redeem(code:, code_verifier:, redirect_uri:)
    record = find_by(code_digest: digest(code))
    return nil if record.nil?

    consumed = where(id: record.id, used_at: nil)
               .where("expires_at > ?", Time.current)
               .update_all(used_at: Time.current)
    return nil unless consumed == 1
    return nil unless record.redirect_uri == redirect_uri
    return nil unless Oauth::RedirectPolicy.verifier_matches?(code_verifier, record.code_challenge)

    record.user
  end
end
