# Demo data for local development: `bin/rails db:seed`.
# Skipped in production unless SEED_DEMO_USER=1 is set explicitly.
if Rails.env.production? && ENV["SEED_DEMO_USER"] != "1"
  puts "Skipping demo seed in production (set SEED_DEMO_USER=1 to force)."
  return
end

email = ENV.fetch("DEMO_USER_EMAIL", "demo@example.com")
password = ENV.fetch("DEMO_USER_PASSWORD", "demo-password-123")

user = User.find_or_initialize_by(email: email)
if user.new_record?
  user.assign_attributes(name: "Demo User", password: password)
  user.skip_confirmation!
  user.save!
end
user.profile || user.create_profile!(display_name: "Demo", location: "Buenos Aires", bio: "Demo account")

puts "Demo user ready: #{email} / #{password}"
