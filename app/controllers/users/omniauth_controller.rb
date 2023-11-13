class Users::OmniauthController < Devise::RegistrationsController
  # github callback
  def github
    @user = User.create_from_provider_data(request.env['omniauth.auth'])
    if @user.persisted?

      session[:info] = request.env['omniauth.auth']

      sign_in_and_redirect @user
      set_flash_message(:notice, :success, kind: 'Github') if is_navigational_format?
    else
      flash[:error] = 'There was a problem signing you in through Github. Please register or try signing in later.'
      redirect_to new_user_registration_url
    end
  end

  # twitter callback
  def twitter
    @user = User.create_from_provider_data(request.env['omniauth.auth'])
    if @user.persisted?

      session[:creds] = request.env['omniauth.auth']['extra']['access_token']

      sign_in_and_redirect @user
      set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
    else
      flash[:error] = 'There was a problem signing you in through Twitter. Please register or try signing in later.'
      redirect_to new_user_registration_url
    end
  end

  # google callback
  def google_oauth2
    @user = User.create_from_provider_data(request.env['omniauth.auth'])
    if @user.persisted?
      sign_in_and_redirect @user
      set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
    else
      render 'There was a problem signing you in through Google. Please register or try signing in later.'
      redirect_to new_user_registration_url
    end
  end

  # facebook callback
  def facebook
    @user = User.create_from_provider_data(request.env['omniauth.auth'])
    if @user.persisted?
      sign_in_and_redirect @user
      set_flash_message(:notice, :success, kind: 'Facebook') if is_navigational_format?
    else
      render = 'There was a problem signing you in through Facebook. Please register or try signing in later.'
      redirect_to new_user_registration_url
    end
  end



  def failure
    render 'There was a problem signing you in. Please register or try signing in later.'
    redirect_to new_user_registration_url # Redirect only once
  end



end