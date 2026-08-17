require "rails_helper"

RSpec.describe Operator, type: :model do
  subject { create(:operator) }

  it { is_expected.to have_many(:tours) }
  it { is_expected.to have_many(:departures).through(:tours) }
  it { is_expected.to have_many(:bookings).through(:tours) }

  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }

  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  it { is_expected.to validate_uniqueness_of(:stripe_account_id).allow_nil }

  describe "geracao de slug no autocadastro" do
    it "gera o slug a partir do nome quando nao foi informado" do
      operator = create(:operator, name: "Agencia do Canion", slug: nil)

      expect(operator.slug).to eq("agencia-do-canion")
    end

    it "resolve colisao acrescentando um numero" do
      create(:operator, name: "Agencia Existente", slug: "agencia-nova")

      operator = create(:operator, name: "Agencia Nova", slug: nil)

      expect(operator.slug).to eq("agencia-nova-2")
    end

    it "respeita o slug explicito, sem gerar por cima (seeds/console)" do
      operator = create(:operator, name: "Qualquer Nome", slug: "slug-escolhido")

      expect(operator.slug).to eq("slug-escolhido")
    end
  end

  describe "conta pendente de aprovacao" do
    it "active_for_authentication? e falso quando active e false" do
      operator = build(:operator, active: false)

      expect(operator.active_for_authentication?).to be(false)
    end

    it "inactive_message e :pending_approval quando active e false" do
      operator = build(:operator, active: false)

      expect(operator.inactive_message).to eq(:pending_approval)
    end

    it "active_for_authentication? e verdadeiro quando active e true" do
      operator = build(:operator, active: true)

      expect(operator.active_for_authentication?).to be(true)
    end

    it "inactive_message delega pro Devise quando active e true" do
      operator = build(:operator, active: true)

      expect(operator.inactive_message).to eq(:inactive)
    end
  end
end
