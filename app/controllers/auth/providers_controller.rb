module Auth
  # GET /auth/providers -> social login providers enabled on this server.
  class ProvidersController < ApplicationController
    def index
      providers = Devise.omniauth_configs.keys.map do |name|
        { name: name, authorize_url: "#{request.base_url}/auth/#{name}" }
      end
      render json: { providers: providers }
    end
  end
end
