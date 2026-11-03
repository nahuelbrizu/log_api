# Target of config.exceptions_app: unknown routes and unhandled exceptions
# render the standard JSON error envelope.
class ErrorsController < ActionController::API
  CODES = {
    400 => "bad_request", 404 => "not_found", 405 => "method_not_allowed",
    406 => "not_acceptable", 422 => "unprocessable_entity", 500 => "internal_server_error"
  }.freeze

  def show
    status = request.path_info.delete_prefix("/").to_i
    status = 500 unless status.between?(400, 599)
    code = CODES.fetch(status, "error")
    render json: { error: { code: code, message: Rack::Utils::HTTP_STATUS_CODES[status] } },
           status: status
  end
end
