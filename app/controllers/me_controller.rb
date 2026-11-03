# The authenticated user's own account.
#   GET    /me  -> user (with profile)
#   PATCH  /me  -> update name and/or password
#   DELETE /me  -> delete the account
class MeController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: { user: UserSerializer.call(current_user, include_profile: true) }
  end

  # Changing the password requires current_password and signs out every
  # other session (all refresh tokens are revoked).
  def update
    attrs = params.permit(:name, :password, :password_confirmation, :current_password)
    changing_password = attrs[:password].present?

    ok = if changing_password
           current_user.update_with_password(attrs.to_h)
         else
           current_user.update(attrs.slice(:name).to_h)
         end
    return render_validation_errors(current_user) unless ok

    RefreshToken.revoke_all_for!(current_user) if changing_password
    render json: { user: UserSerializer.call(current_user, include_profile: true) }
  end

  def destroy
    payload = Auth::TokenIssuer.decode(bearer_token)
    JwtDenylist.revoke_jwt(payload, current_user) if payload
    current_user.destroy!
    head :no_content
  end
end
