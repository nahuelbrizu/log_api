class ApplicationController < ActionController::API
  # Devise's controllers rely on respond_to/respond_with, which API mode omits.
  include ActionController::MimeResponds

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: 'not_found' }, status: :not_found
  end
end
