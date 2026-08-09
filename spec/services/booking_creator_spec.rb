require "rails_helper"

RSpec.describe BookingCreator do
  def build_creator(departure:, adults: 1, children_5_9: 0, children_0_4: 0)
    described_class.new(
      departure:,
      customer_name: "Turista Teste",
      customer_email: "turista@exemplo.com",
      customer_phone: "+55 75 99999-0000",
      adults:,
      children_5_9:,
      children_0_4:
    )
  end

  describe "reserva bem-sucedida" do
    it "cria a reserva com o snapshot de preco correto e incrementa seats_taken" do
      departure = create(:departure, capacity: 10, seats_taken: 0)

      result = build_creator(departure:, adults: 2, children_5_9: 1, children_0_4: 0).call

      expect(result.success?).to be(true)
      expect(result.error).to be_nil

      booking = result.value
      price = PriceCalculator.new(
        unit_price_cents: departure.unit_price_cents, adults: 2, children_5_9: 1, children_0_4: 0
      )
      expect(booking.unit_price_cents).to eq(departure.unit_price_cents)
      expect(booking.total_cents).to eq(price.total_cents)
      expect(booking.deposit_cents).to eq(price.deposit_cents)
      expect(booking).to be_pending
      expect(booking.code).to be_present

      expect(departure.reload.seats_taken).to eq(3)
    end

    it "usa o price_override_cents da saida quando presente, nao o preco base do passeio" do
      tour = create(:tour, base_price_cents: 10_000)
      departure = create(:departure, tour:, price_override_cents: 20_000)

      result = build_creator(departure:, adults: 1).call

      expect(result.value.unit_price_cents).to eq(20_000)
    end

    it "criancas de 0 a 4 anos contam vaga mas nao contam preco" do
      departure = create(:departure, capacity: 10, seats_taken: 0)

      result = build_creator(departure:, adults: 1, children_0_4: 3).call

      expect(result.value.total_cents).to eq(departure.unit_price_cents)
      expect(departure.reload.seats_taken).to eq(4)
    end
  end

  describe "falhas" do
    it "recusa com :invalid_party quando o grupo esta vazio" do
      departure = create(:departure)

      result = build_creator(departure:, adults: 0, children_5_9: 0, children_0_4: 0).call

      expect(result.success?).to be(false)
      expect(result.error).to eq(:invalid_party)
      expect(Booking.count).to eq(0)
      expect(departure.reload.seats_taken).to eq(0)
    end

    it "recusa com :invalid_party quando alguma contagem e negativa" do
      departure = create(:departure)

      result = build_creator(departure:, adults: -1).call

      expect(result.error).to eq(:invalid_party)
      expect(Booking.count).to eq(0)
    end

    it "recusa com :departure_not_scheduled quando a saida esta cancelada" do
      departure = create(:departure, status: :cancelled)

      result = build_creator(departure:, adults: 1).call

      expect(result.error).to eq(:departure_not_scheduled)
      expect(Booking.count).to eq(0)
      expect(departure.reload.seats_taken).to eq(0)
    end

    it "recusa com :departure_in_the_past quando a saida ja aconteceu" do
      departure = create(:departure, starts_at: 1.hour.ago)

      result = build_creator(departure:, adults: 1).call

      expect(result.error).to eq(:departure_in_the_past)
      expect(Booking.count).to eq(0)
    end

    it "recusa com :sold_out quando nao ha vagas suficientes" do
      departure = create(:departure, capacity: 5, seats_taken: 4)

      result = build_creator(departure:, adults: 2).call

      expect(result.error).to eq(:sold_out)
      expect(Booking.count).to eq(0)
      expect(departure.reload.seats_taken).to eq(4)
    end

    it "aceita exatamente as vagas restantes" do
      departure = create(:departure, capacity: 5, seats_taken: 4)

      result = build_creator(departure:, adults: 1).call

      expect(result.success?).to be(true)
      expect(departure.reload.seats_taken).to eq(5)
    end
  end
end
