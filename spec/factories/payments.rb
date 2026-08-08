FactoryBot.define do
  factory :payment do
    booking
    sequence(:stripe_payment_intent_id) { |n| "pi_test_#{n}" }
    amount_cents { 8_100 }
    status { :pending }
  end
end
