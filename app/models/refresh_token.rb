# Opaque, long-lived token used to obtain new access tokens. Only a SHA-256
# digest is stored, so a database leak does not expose usable tokens.
#
# Rotation: every refresh revokes the presented token and issues a new one
# in the same family. Presenting an already-rotated token means it was
# copied, so the whole family is revoked (RFC 6819 / OAuth 2.1 guidance).
class RefreshToken < ApplicationRecord
  class InvalidToken < StandardError; end

  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(expires_at: ...Time.current) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  # Returns [record, plaintext_token].
  def self.issue!(user, family_id: nil, request: nil)
    token = SecureRandom.urlsafe_base64(48)
    record = create!(
      user: user,
      token_digest: digest(token),
      family_id: family_id || SecureRandom.uuid,
      expires_at: Rails.configuration.x.auth.refresh_token_ttl.from_now,
      user_agent: request&.user_agent.to_s.first(255).presence,
      ip_address: request&.remote_ip
    )
    [record, token]
  end

  # Consumes a refresh token and returns [user, new_plaintext_token].
  # Raises InvalidToken for unknown, expired or revoked tokens.
  def self.rotate!(token, request: nil)
    result = transaction do
      record = lock.find_by(token_digest: digest(token))
      next :invalid if record.nil? || record.expires_at.past?

      if record.revoked_at
        # Reuse of a rotated token: revoke the chain. Committed (not rolled
        # back) because the transaction block returns normally.
        revoke_family!(record.family_id)
        next :invalid
      end

      record.update!(revoked_at: Time.current)
      _new_record, new_token = issue!(record.user, family_id: record.family_id, request: request)
      [record.user, new_token]
    end
    raise InvalidToken if result == :invalid

    result
  end

  def self.revoke_family!(family_id)
    where(family_id: family_id, revoked_at: nil).update_all(revoked_at: Time.current)
  end

  def self.revoke_all_for!(user)
    where(user: user, revoked_at: nil).update_all(revoked_at: Time.current)
  end
end
