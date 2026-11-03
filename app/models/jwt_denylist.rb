# Access tokens revoked before their natural expiry (sign out, account
# deletion). Rows can be purged once `exp` has passed: `bin/rails auth:cleanup`.
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  scope :expired, -> { where(exp: ...Time.current) }
end
