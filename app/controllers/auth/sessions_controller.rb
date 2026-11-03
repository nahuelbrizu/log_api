module Auth
  # POST   /auth/sign_in   email + password -> token pair
  # DELETE /auth/sign_out  revokes the access token (and refresh token[s])
  class SessionsController < ApplicationController
    before_action :authenticate_user!, only: :destroy

    def create
      email = params.require(:email)
      password = params.require(:password)
      user = User.find_for_authentication(email: email)

      unless valid_credentials?(user, password)
        return render_error(:unauthorized, "invalid_credentials", "Invalid email or password")
      end

      unless user.active_for_authentication?
        return render_error(:forbidden, user.inactive_message.to_s,
                            "Confirm your email address before signing in")
      end

      user.update_tracked_fields!(request)
      render json: Auth::TokenIssuer.call(user, request: request), status: :ok
    end

    # Body (optional): { "refresh_token": "..." } revokes that session's
    # refresh token; { "all": true } revokes every refresh token of the user.
    def destroy
      payload = Auth::TokenIssuer.decode(bearer_token)
      JwtDenylist.revoke_jwt(payload, current_user) if payload

      if ActiveModel::Type::Boolean.new.cast(params[:all])
        RefreshToken.revoke_all_for!(current_user)
      elsif params[:refresh_token].present?
        token = current_user.refresh_tokens.find_by(token_digest: RefreshToken.digest(params[:refresh_token]))
        RefreshToken.revoke_family!(token.family_id) if token
      end

      head :no_content
    end

    private

    # Runs bcrypt even for unknown emails so response time does not reveal
    # whether an account exists.
    def valid_credentials?(user, password)
      return user.valid_password?(password) if user

      Devise::Encryptor.compare(User, self.class.dummy_digest, password)
      false
    end

    def self.dummy_digest
      @dummy_digest ||= Devise::Encryptor.digest(User, SecureRandom.hex(16))
    end
  end
end
