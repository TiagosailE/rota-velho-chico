FactoryBot.define do
  factory :payment do
    booking
    sequence(:stripe_checkout_session_id) { |n| "cs_test_#{n}" }
    stripe_payment_intent_id { nil }
    amount_cents { 8_100 }
    status { :pending }
  end
end
