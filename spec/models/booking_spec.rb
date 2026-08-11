require "rails_helper"

RSpec.describe Booking, type: :model do
  subject { create(:booking) }

  it { is_expected.to belong_to(:departure) }
  it { is_expected.to have_one(:payment) }
  it { is_expected.to have_one(:review) }

  it do
    expect(subject).to define_enum_for(:status)
      .with_values(pending: 0, confirmed: 1, cancelled: 2, refunded: 3)
  end

  it { is_expected.to validate_presence_of(:code) }
  it { is_expected.to validate_uniqueness_of(:code) }

  it { is_expected.to validate_presence_of(:customer_name) }
  it { is_expected.to validate_presence_of(:customer_email) }

  it { is_expected.to validate_numericality_of(:adults).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_numericality_of(:children_5_9).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_numericality_of(:children_0_4).is_greater_than_or_equal_to(0) }

  it { is_expected.to validate_presence_of(:unit_price_cents) }
  it { is_expected.to validate_presence_of(:total_cents) }
  it { is_expected.to validate_presence_of(:deposit_cents) }

  describe "party nao pode ser vazio" do
    it "e invalido sem nenhum passageiro" do
      booking = build(:booking, adults: 0, children_5_9: 0, children_0_4: 0)

      expect(booking).not_to be_valid
      expect(booking.errors[:base]).to be_present
    end

    it "e valido com pelo menos uma crianca de 0 a 4 anos" do
      booking = build(:booking, adults: 0, children_5_9: 0, children_0_4: 1)

      expect(booking).to be_valid
    end
  end

  describe "#generate_code" do
    it "gera um codigo automaticamente quando nao informado" do
      booking = build(:booking, code: nil)

      booking.valid?

      expect(booking.code).to match(/\A[A-HJ-NP-Z2-9]{6}\z/)
    end

    it "nao sobrescreve um codigo ja informado" do
      booking = build(:booking, code: "ABCDEF")

      booking.valid?

      expect(booking.code).to eq("ABCDEF")
    end

    it "tenta de novo quando o candidato sorteado ja existe" do
      allow(Booking).to receive(:exists?).and_return(true, false)

      booking = build(:booking, code: nil)
      booking.valid?

      expect(Booking).to have_received(:exists?).twice
      expect(booking.code).to be_present
    end
  end

  describe "sinal nao pode passar do total" do
    it "e invalido quando o deposito e maior que o total" do
      booking = build(:booking, total_cents: 10_000, deposit_cents: 10_001)

      expect(booking).not_to be_valid
      expect(booking.errors[:deposit_cents]).to be_present
    end

    it "e valido quando o deposito e igual ao total" do
      booking = build(:booking, total_cents: 10_000, deposit_cents: 10_000)

      expect(booking).to be_valid
    end
  end

  describe "#reviewable?" do
    it "e avaliavel quando confirmada, com saida no passado e sem avaliacao" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, status: :confirmed)

      expect(booking.reviewable?).to be true
    end

    it "nao e avaliavel quando pendente" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, status: :pending)

      expect(booking.reviewable?).to be false
    end

    it "nao e avaliavel quando a saida ainda nao aconteceu" do
      departure = create(:departure, starts_at: 2.days.from_now)
      booking = create(:booking, departure:, status: :confirmed)

      expect(booking.reviewable?).to be false
    end

    it "nao e avaliavel quando ja existe avaliacao" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, status: :confirmed)
      create(:review, booking:)

      expect(booking.reviewable?).to be false
    end
  end
end
