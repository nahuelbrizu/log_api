class ApplicationController < ActionController::API
  # Devise's base controller relies on respond_to/respond_with, which API
  # mode omits (only used by the OmniAuth callback controller here).
  include ActionController::MimeResponds
  respond_to :json

  # Requests are flat JSON objects: {"email": "...", "password": "..."}.
  wrap_parameters false

  rescue_from ActiveRecord::RecordNotFound do
    render_error :not_found, "not_found", "Resource not found"
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error :bad_request, "parameter_missing", "Missing parameter: #{e.param}"
  end

  rescue_from ActionDispatch::Http::Parameters::ParseError do
    render_error :bad_request, "invalid_json", "Request body is not valid JSON"
  end

  protected

  # Authentication is bearer-token only. The :jwt strategy is named
  # explicitly so no other Warden strategy (e.g. a session) can log a user in.
  def authenticate_user!
    return if current_user

    render_error :unauthorized, "unauthorized", "Missing, invalid, expired or revoked access token"
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = warden.authenticate(:jwt, scope: :user, store: false)
  end

  def user_signed_in?
    current_user.present?
  end

  # Uniform error envelope used by every endpoint:
  #   { "error": { "code": "...", "message": "...", "details": { ... } } }
  def render_error(status, code, message, details: nil)
    error = { code: code, message: message }
    error[:details] = details if details.present?
    render json: { error: error }, status: status
  end

  def render_validation_errors(record)
    render_error :unprocessable_entity, "validation_failed", "Validation failed",
                 details: record.errors.to_hash(true)
  end

  def bearer_token
    request.authorization.to_s[/\ABearer\s+(.+)\z/i, 1]
  end
end
