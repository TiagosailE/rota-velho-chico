FactoryBot.define do
  factory :stripe_event do
    sequence(:stripe_event_id) { |n| "evt_test_#{n}" }
    event_type { "payment_intent.succeeded" }
  end
end
