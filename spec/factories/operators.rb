FactoryBot.define do
  factory :operator do
    sequence(:name) { |n| "Agencia #{n}" }
    sequence(:slug) { |n| "agencia-#{n}" }
    sequence(:email) { |n| "agencia#{n}@exemplo.com" }
    password { "password123" }
    active { true }
  end
end
