class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[ show update destroy ]

  # GET /profiles
  def index
    @profiles = Profile.all

    render json: @profiles
  end
  # GET /profiles/new
  def new
    # @profile = Profile.new
    @profile = current_user.build_profile
  end
  # GET /profiles/1
  def show
    render json: @profile
  end
  def edit
    @profile = current_user.profile.find(params[:id])
  end
  # POST /profiles
  def create
    # @profile = Profile.new(profile_params)
    @profile = current_user.build_profile(profile_params)

    respond_to do |format|
      if @profile.save
        format.html { redirect_to @profile, notice: 'Profile was successfully created.' }
        format.json { render :show, status: :created, location: @profile }
      else
        format.html { render :new }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
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
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_profile
      @profile = Profile.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def profile_params
      params.require(:profile).permit(:display_name, :location, :bio, :user_id)
    end
end
