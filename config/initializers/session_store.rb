Rails.application.config.session_store :active_record_store, key: '_devise-omniauth_session'
Rails.application.config.session_store :cookie_store, key: '_your_app_session'
