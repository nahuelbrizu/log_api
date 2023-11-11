require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Habilita el modo de producción.
  config.cache_classes = true
  config.eager_load = true

  # Configura la base de datos.
  config.database_configuration = { production: { url: ENV['DATABASE_URL'] } }

  # Manejo de errores y logging.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.force_ssl = true

  # Configuración de los registros (logs).
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.log_level = :info
  config.log_tags = [:request_id]

  # Configuración de seguridad de contenido.
  config.middleware.use SecureHeaders::Middleware

  # Compresión Gzip y caché de activos.
  config.middleware.use Rack::Deflater
  config.public_file_server.headers = { 'Cache-Control' => 'public, s-maxage=31536000, max-age=15552000' }

  # Full error reports are disabled and caching is turned on.
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Ignore bad email addresses and do not raise email delivery errors.
  config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n.
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
