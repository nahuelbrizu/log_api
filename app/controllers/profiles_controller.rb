class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: :show
  before_action :set_own_profile, only: %i[update destroy]

  # GET /profiles
  def index
    render json: Profile.all
  end

  # GET /profiles/1
  def show
    render json: @profile
  end

  # POST /profiles
  def create
    if current_user.profile
      return render json: { error: 'El usuario ya tiene un perfil' }, status: :unprocessable_entity
    end

    @profile = current_user.build_profile(profile_params)
    if @profile.save
      render json: @profile, status: :created, location: @profile
    else
      render json: @profile.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /profiles/1
  def update
    if @profile.update(profile_params)
      render json: @profile
    else
      render json: @profile.errors, status: :unprocessable_entity
    end
  end

  # DELETE /profiles/1
  def destroy
    @profile.destroy
    head :no_content
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  # Only the owner may modify or delete a profile; others get 404.
  def set_own_profile
    @profile = Profile.find_by!(id: params[:id], user_id: current_user.id)
  end

  # user_id is never taken from the request: it comes from current_user.
  def profile_params
    params.require(:profile).permit(:display_name, :location, :bio)
  end
end
