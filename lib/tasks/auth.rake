namespace :auth do
  desc "Delete expired denylisted JWTs, refresh tokens and OAuth codes (run daily via cron)"
  task cleanup: :environment do
    counts = {
      jwt_denylists: JwtDenylist.expired.delete_all,
      refresh_tokens: RefreshToken.expired.delete_all,
      oauth_codes: OauthCode.expired.delete_all
    }
    puts "auth:cleanup deleted #{counts}"
  end
end
