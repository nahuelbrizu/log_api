class User < ApplicationRecord
  OAUTH_PROVIDERS = %i[google_oauth2 facebook github twitter].freeze

  has_one :profile, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :trackable,
         :omniauthable, omniauth_providers: OAUTH_PROVIDERS

  # Finds or creates the user for an OmniAuth callback.
  #
  # 1. A user already linked to this provider/uid → that user.
  # 2. An existing account with the same email → link it, but only if the
  #    provider verified the email and the account is not yet linked to
  #    another provider (otherwise anyone could take over an account by
  #    signing up at a provider with someone else's address).
  # 3. Otherwise → a new, already-confirmed user.
  #
  # Always returns a User; check #persisted? and #errors.
  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid.to_s)
    return user if user

    email = auth.info.email.presence
    if email.nil?
      return new.tap { |u| u.errors.add(:email, "no fue provisto por #{auth.provider}") }
    end

    existing = find_by(email: email)
    if existing
      if existing.provider.blank? && verified_email?(auth)
        existing.update(provider: auth.provider, uid: auth.uid.to_s)
        existing.confirm unless existing.confirmed?
      else
        existing.errors.add(:email, 'ya está registrado; iniciá sesión con tu método original')
      end
      return existing
    end

    new(
      provider: auth.provider,
      uid: auth.uid.to_s,
      email: email,
      name: auth.info.name.presence || 'None',
      password: Devise.friendly_token[0, 20]
    ).tap do |u|
      u.skip_confirmation!
      u.save
    end
  end

  def self.verified_email?(auth)
    case auth.provider.to_s
    when 'google_oauth2'
      ActiveModel::Type::Boolean.new.cast(auth.extra&.raw_info&.email_verified)
    when 'github', 'facebook'
      # GitHub only exposes verified addresses here; Facebook requires a
      # confirmed email for the account.
      true
    else
      false
    end
  end
  private_class_method :verified_email?
end
