FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "s3cure-password" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :github do
      provider { "github" }
      sequence(:uid) { |n| "gh-#{n}" }
    end
  end

  factory :profile do
    user
    display_name { "Display" }
    location { "Somewhere" }
    bio { "Hello" }
  end
end
