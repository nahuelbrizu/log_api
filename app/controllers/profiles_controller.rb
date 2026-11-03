class ProfilesController < ApplicationController
  MAX_PER_PAGE = 100

  before_action :authenticate_user!
  before_action :set_own_profile, only: %i[update destroy]

  # GET /profiles?page=1&per_page=25
  def index
    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = params.fetch(:per_page, 25).to_i.clamp(1, MAX_PER_PAGE)
    scope = Profile.order(:id)

    render json: {
      profiles: scope.offset((page - 1) * per_page).limit(per_page).map { |p| ProfileSerializer.call(p) },
      meta: { page: page, per_page: per_page, total: scope.count }
    }
  end

  # GET /profiles/:id
  def show
    render json: { profile: ProfileSerializer.call(Profile.find(params[:id])) }
  end

  # POST /profiles (one profile per user)
  def create
    if current_user.profile
      return render_error(:conflict, "profile_exists", "The current user already has a profile")
    end

    profile = current_user.build_profile(profile_params)
    if profile.save
      render json: { profile: ProfileSerializer.call(profile) }, status: :created, location: profile
    else
      render_validation_errors(profile)
    end
  end

  # PATCH/PUT /profiles/:id
  def update
    if @profile.update(profile_params)
      render json: { profile: ProfileSerializer.call(@profile) }
    else
      render_validation_errors(@profile)
    end
  end

  # DELETE /profiles/:id
  def destroy
    @profile.destroy!
    head :no_content
  end

  private

  # Only the owner may modify or delete a profile; others get 404.
  def set_own_profile
    @profile = current_user.profile
    raise ActiveRecord::RecordNotFound unless @profile && @profile.id.to_s == params[:id].to_s
  end

  # user_id is never taken from the request: it comes from current_user.
  def profile_params
    params.permit(:display_name, :location, :bio)
  end
end
