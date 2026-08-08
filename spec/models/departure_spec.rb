require "rails_helper"

RSpec.describe Departure, type: :model do
  subject { create(:departure) }

  it { is_expected.to belong_to(:tour) }
  it { is_expected.to have_many(:bookings) }

  it do
    expect(subject).to define_enum_for(:status)
      .with_values(scheduled: 0, cancelled: 1, completed: 2)
  end

  it { is_expected.to validate_presence_of(:starts_at) }

  it { is_expected.to validate_presence_of(:capacity) }
  it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0) }

  it do
    is_expected.to validate_numericality_of(:price_override_cents)
      .is_greater_than(0).allow_nil
  end

  describe "unicidade de starts_at por tour" do
    it "recusa duas saidas do mesmo tour no mesmo horario" do
      tour = create(:tour)
      time = 10.days.from_now
      create(:departure, tour:, starts_at: time)

      duplicate = build(:departure, tour:, starts_at: time)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:starts_at]).to be_present
    end

    it "permite o mesmo horario em tours diferentes" do
      time = 10.days.from_now
      create(:departure, starts_at: time)

      other = build(:departure, starts_at: time)

      expect(other).to be_valid
    end
  end

  describe "#unit_price_cents" do
    it "usa o preco override quando presente" do
      tour = create(:tour, base_price_cents: 10_000)
      departure = create(:departure, tour:, price_override_cents: 15_000)

      expect(departure.unit_price_cents).to eq(15_000)
    end

    it "cai para o preco base do passeio quando nao ha override" do
      tour = create(:tour, base_price_cents: 10_000)
      departure = create(:departure, tour:, price_override_cents: nil)

      expect(departure.unit_price_cents).to eq(10_000)
    end
  end
end
