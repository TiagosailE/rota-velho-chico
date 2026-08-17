FactoryBot.define do
  factory :operator do
    sequence(:name) { |n| "Agencia #{n}" }
    sequence(:slug) { |n| "agencia-#{n}" }
    sequence(:email) { |n| "agencia#{n}@exemplo.com" }
    password { "password123" }
    active { true }

    # Conectado por padrao -- a maioria dos specs de reserva/pagamento nao
    # e sobre o Connect em si, e forcar cada um a lidar com onboarding
    # inflaria specs sem relacao. O caminho "ainda nao conectado" tem seu
    # proprio trait, usado so onde o gate de fato importa.
    sequence(:stripe_account_id) { |n| "acct_test_#{n}" }
    stripe_charges_enabled { true }

    trait :stripe_disconnected do
      stripe_account_id { nil }
      stripe_charges_enabled { false }
    end
  end
end
