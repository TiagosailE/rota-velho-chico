FactoryBot.define do
  factory :tour do
    operator
    sequence(:title) { |n| "Passeio #{n}" }
    sequence(:slug) { |n| "passeio-#{n}" }
    category { :boat }
    duration_minutes { 240 }
    base_price_cents { 13_500 }
    meeting_point { "Pier do Rio do Sal" }
    min_age { 0 }
    active { true }

    trait :with_lunch do
      lunch_price_cents { 7_500 }
    end
  end
end
