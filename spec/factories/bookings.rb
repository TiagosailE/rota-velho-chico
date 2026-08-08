FactoryBot.define do
  factory :booking do
    departure
    sequence(:code) { |n| format("BK%06d", n) }
    customer_name { "Turista Teste" }
    sequence(:customer_email) { |n| "turista#{n}@exemplo.com" }
    customer_phone { "+55 75 99999-0000" }
    adults { 2 }
    children_5_9 { 0 }
    children_0_4 { 0 }
    unit_price_cents { 13_500 }
    total_cents { 27_000 }
    deposit_cents { 8_100 }
    status { :pending }
  end
end
