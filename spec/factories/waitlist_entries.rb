FactoryBot.define do
  factory :waitlist_entry do
    departure
    customer_name { "Turista Teste" }
    sequence(:customer_email) { |n| "espera#{n}@exemplo.com" }
    customer_phone { "+55 75 99999-0000" }
    adults { 1 }
    children_5_9 { 0 }
    children_0_4 { 0 }
    status { :pending }
  end
end
