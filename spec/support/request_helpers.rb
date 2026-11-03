module RequestHelpers
  def json
    JSON.parse(response.body)
  end

  def json_post(path, body = {}, headers = {})
    post path, params: body.to_json, headers: json_headers.merge(headers)
  end

  def json_put(path, body = {}, headers = {})
    put path, params: body.to_json, headers: json_headers.merge(headers)
  end

  def json_patch(path, body = {}, headers = {})
    patch path, params: body.to_json, headers: json_headers.merge(headers)
  end

  def json_delete(path, body = {}, headers = {})
    delete path, params: body.to_json, headers: json_headers.merge(headers)
  end

  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  def auth_header(token)
    { "Authorization" => "Bearer #{token}" }
  end

  # Signs in through the API and returns the token response.
  def sign_in_tokens(user, password: "s3cure-password")
    json_post "/auth/sign_in", email: user.email, password: password
    expect(response).to have_http_status(:ok)
    json
  end

  def access_token_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def expect_error(status, code)
    expect(response).to have_http_status(status)
    expect(json.dig("error", "code")).to eq(code)
  end
end
