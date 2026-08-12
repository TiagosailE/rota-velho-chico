require "rails_helper"

RSpec.describe Tour, type: :model do
  subject { create(:tour) }

  it { is_expected.to belong_to(:operator) }
  it { is_expected.to have_many(:departures) }
  it { is_expected.to have_many(:bookings) }
  it { is_expected.to have_many(:reviews) }
  it { is_expected.to have_many(:tour_photos) }

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

  it { is_expected.to validate_numericality_of(:lat).is_greater_than_or_equal_to(-90).is_less_than_or_equal_to(90).allow_nil }
  it { is_expected.to validate_numericality_of(:lng).is_greater_than_or_equal_to(-180).is_less_than_or_equal_to(180).allow_nil }
  it { is_expected.to validate_numericality_of(:lunch_price_cents).is_greater_than(0).allow_nil }

  describe "#coordinates?" do
    it "e falso quando falta lat ou lng" do
      expect(build(:tour, lat: nil, lng: -38.2).coordinates?).to be false
      expect(build(:tour, lat: -9.4, lng: nil).coordinates?).to be false
    end

    it "e verdadeiro quando os dois estao presentes" do
      expect(build(:tour, lat: -9.4, lng: -38.2).coordinates?).to be true
    end
  end

  describe "#cover_photo" do
    it "e nil quando o passeio nao tem foto" do
      expect(create(:tour).cover_photo).to be_nil
    end

    it "e a foto de menor position, nao a mais recente" do
      tour = create(:tour)
      segunda = create(:tour_photo, tour: tour, position: 1)
      primeira = create(:tour_photo, tour: tour, position: 0)

      expect(tour.reload.cover_photo).to eq(primeira)
      expect(tour.cover_photo).not_to eq(segunda)
    end
  end

  describe "#average_rating" do
    it "e nil quando o passeio nao tem avaliacao" do
      expect(create(:tour).average_rating).to be_nil
    end

    it "e a media arredondada em uma casa decimal" do
      tour = create(:tour)
      departure = create(:departure, tour:)
      booking_a = create(:booking, departure:)
      booking_b = create(:booking, departure:)
      create(:review, booking: booking_a, rating: 5)
      create(:review, booking: booking_b, rating: 4)

      expect(tour.average_rating).to eq(4.5)
    end
  end

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

  describe "#lunch_available?" do
    it "e falso quando o passeio nao tem preco de almoco" do
      expect(build(:tour, lunch_price_cents: nil).lunch_available?).to be false
    end

    it "e verdadeiro quando o passeio tem preco de almoco" do
      expect(build(:tour, :with_lunch).lunch_available?).to be true
    end
  end

  describe "#lunch_price_reais" do
    it "converte reais para centavos" do
      tour = build(:tour, lunch_price_reais: "75.50")

      expect(tour.lunch_price_cents).to eq(7_550)
    end

    it "le o preco do almoco em reais a partir dos centavos" do
      tour = build(:tour, lunch_price_cents: 7_550)

      expect(tour.lunch_price_reais).to eq(75.50)
    end

    it "fica nil quando o valor em reais fica em branco" do
      tour = build(:tour, :with_lunch)

      tour.lunch_price_reais = ""

      expect(tour.lunch_price_cents).to be_nil
    end
  end
end
