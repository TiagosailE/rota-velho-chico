require "rails_helper"

RSpec.describe Tour, type: :model do
  subject { create(:tour) }

  it { is_expected.to belong_to(:operator) }
  it { is_expected.to have_many(:departures) }

  it do
    expect(subject).to define_enum_for(:category)
      .with_values(boat: 0, offroad: 1, hiking: 2, cultural: 3)
  end

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }

  it { is_expected.to validate_presence_of(:duration_minutes) }
  it { is_expected.to validate_numericality_of(:duration_minutes).is_greater_than(0) }

  it { is_expected.to validate_presence_of(:base_price_cents) }
  it { is_expected.to validate_numericality_of(:base_price_cents).is_greater_than(0) }

  it { is_expected.to validate_presence_of(:meeting_point) }

  it { is_expected.to validate_numericality_of(:min_age).is_greater_than_or_equal_to(0) }

  describe "#base_price_reais" do
    it "converte reais para centavos" do
      tour = build(:tour, base_price_reais: "135.50")

      expect(tour.base_price_cents).to eq(13_550)
    end

    it "le o preco base em reais a partir dos centavos" do
      tour = build(:tour, base_price_cents: 13_550)

      expect(tour.base_price_reais).to eq(135.50)
    end

    it "zera base_price_cents quando o valor em reais fica em branco" do
      tour = build(:tour, base_price_cents: 10_000)

      tour.base_price_reais = ""

      expect(tour.base_price_cents).to be_nil
    end
  end
end
