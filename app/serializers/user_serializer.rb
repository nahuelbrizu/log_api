# Public representation of a user. Allowlist on purpose: uid, password
# digests, confirmation/reset tokens and tracking IPs are never exposed.
class UserSerializer
  def self.call(user, include_profile: false)
    data = {
      id: user.id,
      email: user.email,
      name: user.name,
      provider: user.provider.presence,
      confirmed: user.confirmed?,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
    data[:profile] = user.profile && ProfileSerializer.call(user.profile) if include_profile
    data
  end
end
