class User < ApplicationRecord
  OAUTH_PROVIDERS = %i[google_oauth2 facebook github twitter].freeze

  has_one :profile, dependent: :destroy
  has_many :refresh_tokens, dependent: :delete_all
  has_many :oauth_codes, dependent: :delete_all

  devise :database_authenticatable, :registerable, :recoverable,
         :validatable, :confirmable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Only providers with credentials configured (config/initializers/devise.rb).
  devise :omniauthable, omniauth_providers: Devise.omniauth_configs.keys

  validates :name, length: { maximum: 100 }
  validate :password_not_email, if: -> { password.present? }

  # Finds or creates the user for an OmniAuth callback.
  #
  # 1. A user already linked to this provider/uid → that user.
  # 2. An existing account with the same email → link it, but only if the
  #    provider verified the email and the account is not yet linked to
  #    another provider (otherwise anyone could take over an account by
  #    signing up at a provider with someone else's address). If that
  #    account was never confirmed, its password is replaced, since whoever
  #    set it never proved they own the email.
  # 3. Otherwise → a new, already-confirmed user.
  #
  # Always returns a User; check #persisted? and #errors.
  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid.to_s)
    return user if user

    email = auth.info.email.presence
    if email.nil?
      return new.tap { |u| u.errors.add(:email, "was not provided by #{auth.provider}") }
    end

    existing = find_by(email: email.downcase)
    if existing
      if existing.provider.blank? && verified_email?(auth)
        # An unconfirmed account may have been registered by someone else
        # with this address: drop the password they chose before linking.
        existing.password = Devise.friendly_token(32) unless existing.confirmed?
        existing.update(provider: auth.provider, uid: auth.uid.to_s)
        existing.confirm unless existing.confirmed?
      else
        existing.errors.add(:email, "is already registered; sign in with your original method")
      end
      return existing
    end

    new(
      provider: auth.provider,
      uid: auth.uid.to_s,
      email: email,
      name: auth.info.name.presence&.first(100),
      password: Devise.friendly_token(32)
    ).tap do |u|
      u.skip_confirmation!
      u.save
    end
  end

  def self.verified_email?(auth)
    case auth.provider.to_s
    when "google_oauth2"
      ActiveModel::Type::Boolean.new.cast(auth.extra&.raw_info&.email_verified)
    when "github", "facebook"
      # GitHub only exposes verified addresses here; Facebook requires a
      # confirmed email for the account.
      true
    else
      false
    end
  end
  private_class_method :verified_email?

  private

  def password_not_email
    errors.add(:password, "must not be the same as the email") if password.casecmp?(email.to_s)
  end
end
