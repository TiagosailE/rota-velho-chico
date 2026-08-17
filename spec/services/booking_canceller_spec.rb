require "rails_helper"

RSpec.describe BookingCanceller do
  def stub_stripe_refund(refund_id: "re_test_123")
    allow(Stripe::Refund).to receive(:create).and_return(instance_double(Stripe::Refund, id: refund_id))
  end

  describe "reserva paga, dentro do prazo de estorno" do
    it "estorna no Stripe, marca payment e booking como refunded, e libera a vaga" do
      departure = create(:departure, capacity: 10, seats_taken: 3, starts_at: 10.days.from_now)
      booking = create(:booking, departure:, status: :confirmed, adults: 2, children_5_9: 1, children_0_4: 0)
      payment = create(:payment, booking:, status: :succeeded, amount_cents: 8_100,
                                  stripe_payment_intent_id: "pi_test_123")
      stub_stripe_refund

      result = described_class.new(booking:).call

      expect(result.success?).to be(true)
      expect(Stripe::Refund).to have_received(:create).with(payment_intent: "pi_test_123")
      expect(payment.reload).to be_refunded
      expect(payment.stripe_refund_id).to eq("re_test_123")
      expect(payment.refunded_amount_cents).to eq(8_100)
      expect(booking.reload).to be_refunded
      expect(booking.cancelled_at).to be_present
      expect(departure.reload.seats_taken).to eq(0)
    end
  end

  describe "reserva paga, fora do prazo de estorno" do
    it "nao chama o Stripe, marca a booking como cancelled (sinal retido), e libera a vaga" do
      departure = create(:departure, capacity: 10, seats_taken: 2, starts_at: 10.hours.from_now)
      booking = create(:booking, departure:, status: :confirmed, adults: 2, children_5_9: 0, children_0_4: 0)
      payment = create(:payment, booking:, status: :succeeded)
      allow(Stripe::Refund).to receive(:create)

      result = described_class.new(booking:).call

      expect(result.success?).to be(true)
      expect(Stripe::Refund).not_to have_received(:create)
      expect(payment.reload).to be_succeeded
      expect(booking.reload).to be_cancelled
      expect(departure.reload.seats_taken).to eq(0)
    end
  end

  describe "reserva nunca paga" do
    it "cancela sem chamar o Stripe, mesmo dentro do prazo de estorno" do
      departure = create(:departure, capacity: 10, seats_taken: 1, starts_at: 10.days.from_now)
      booking = create(:booking, departure:, status: :pending, adults: 1, children_5_9: 0, children_0_4: 0)
      allow(Stripe::Refund).to receive(:create)

      result = described_class.new(booking:).call

      expect(result.success?).to be(true)
      expect(Stripe::Refund).not_to have_received(:create)
      expect(booking.reload).to be_cancelled
      expect(departure.reload.seats_taken).to eq(0)
    end
  end

  describe "cancelamento pelo operador" do
    it "sempre estorna quando ha pagamento, mesmo fora do prazo" do
      departure = create(:departure, capacity: 10, seats_taken: 1, starts_at: 10.hours.from_now)
      booking = create(:booking, departure:, status: :confirmed, adults: 1, children_5_9: 0, children_0_4: 0)
      create(:payment, booking:, status: :succeeded)
      stub_stripe_refund

      result = described_class.new(booking:, cancelled_by_operator: true).call

      expect(result.success?).to be(true)
      expect(booking.reload).to be_refunded
    end
  end

  describe "libera vaga com a saida ainda agendada" do
    it "agenda a promocao da lista de espera" do
      departure = create(:departure, capacity: 10, seats_taken: 1)
      booking = create(:booking, departure:, status: :pending, adults: 1, children_5_9: 0, children_0_4: 0)

      expect { described_class.new(booking:).call }
        .to have_enqueued_job(PromoteWaitlistJob).with(departure.id)
    end
  end

  describe "reserva ja cancelada ou estornada" do
    it "recusa com :already_cancelled e nao mexe na vaga" do
      departure = create(:departure, capacity: 10, seats_taken: 1)
      booking = create(:booking, departure:, status: :cancelled)

      result = described_class.new(booking:).call

      expect(result.success?).to be(false)
      expect(result.error).to eq(:already_cancelled)
      expect(departure.reload.seats_taken).to eq(1)
    end
  end

  describe "falha no Stripe" do
    it "deixa Stripe::StripeError subir sem mudar nada no banco -- retry fica seguro" do
      departure = create(:departure, capacity: 10, seats_taken: 1, starts_at: 10.days.from_now)
      booking = create(:booking, departure:, status: :confirmed, adults: 1, children_5_9: 0, children_0_4: 0)
      create(:payment, booking:, status: :succeeded)
      allow(Stripe::Refund).to receive(:create).and_raise(Stripe::APIConnectionError.new("timeout"))

      expect { described_class.new(booking:).call }.to raise_error(Stripe::APIConnectionError)

      expect(booking.reload).to be_confirmed
      expect(departure.reload.seats_taken).to eq(1)
    end
  end
end
