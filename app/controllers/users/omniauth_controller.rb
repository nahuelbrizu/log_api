class Users::OmniauthController < Devise::OmniauthCallbacksController
  User::OAUTH_PROVIDERS.each do |provider|
    define_method(provider) { handle_callback }
  end

  # OmniAuth redirects here when the provider denies or errors out.
  def failure
    render json: { error: 'authentication_failed', message: failure_message },
           status: :unauthorized
  end

  private

  def handle_callback
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    if user.persisted? && user.errors.empty?
      sign_in(user, event: :authentication)
      render json: { user: user.as_json(only: %i[id email name provider]) }, status: :ok
    else
      render json: { error: 'authentication_failed', provider: auth&.provider,
                     messages: user.errors.full_messages },
             status: :unprocessable_entity
    end
  end
end
