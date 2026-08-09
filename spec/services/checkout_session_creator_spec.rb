require "rails_helper"

RSpec.describe CheckoutSessionCreator do
  def stub_stripe_session(payment_intent: "pi_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")
    session = instance_double(Stripe::Checkout::Session, payment_intent:, url:)
    allow(Stripe::Checkout::Session).to receive(:create).and_return(session)
    session
  end

  describe "#call" do
    it "cria a sessao do Stripe com o valor do sinal, nao do total, e devolve a url" do
      booking = create(:booking, total_cents: 27_000, deposit_cents: 8_100)
      allow(Stripe::Checkout::Session).to receive(:create)
        .and_return(instance_double(Stripe::Checkout::Session,
                                     payment_intent: "pi_test_123",
                                     url: "https://checkout.stripe.com/pay/cs_test_abc"))

      result = described_class.new(
        booking:, success_url: "https://example.com/success", cancel_url: "https://example.com/cancel"
      ).call

      expect(Stripe::Checkout::Session).to have_received(:create).with(
        hash_including(
          mode: "payment",
          success_url: "https://example.com/success",
          cancel_url: "https://example.com/cancel",
          line_items: [ hash_including(price_data: hash_including(unit_amount: 8_100, currency: "brl")) ]
        )
      )
      expect(result).to eq("https://checkout.stripe.com/pay/cs_test_abc")
    end

    it "cria o Payment associado com o intent id da sessao" do
      booking = create(:booking, deposit_cents: 8_100)
      stub_stripe_session(payment_intent: "pi_test_456")

      described_class.new(booking:, success_url: "https://example.com/s", cancel_url: "https://example.com/c").call

      payment = booking.reload.payment
      expect(payment.stripe_payment_intent_id).to eq("pi_test_456")
      expect(payment.amount_cents).to eq(8_100)
      expect(payment).to be_pending
    end

    it "reaproveita o Payment existente numa nova tentativa, em vez de criar outro" do
      booking = create(:booking, deposit_cents: 8_100)
      existing_payment = create(:payment, booking:, stripe_payment_intent_id: "pi_test_old")
      stub_stripe_session(payment_intent: "pi_test_new")

      described_class.new(booking:, success_url: "https://example.com/s", cancel_url: "https://example.com/c").call

      expect(Payment.where(booking:).count).to eq(1)
      expect(existing_payment.reload.stripe_payment_intent_id).to eq("pi_test_new")
    end

    it "deixa Stripe::StripeError subir para quem chamou" do
      booking = create(:booking)
      allow(Stripe::Checkout::Session).to receive(:create).and_raise(Stripe::APIConnectionError.new("timeout"))

      expect do
        described_class.new(booking:, success_url: "https://example.com/s", cancel_url: "https://example.com/c").call
      end.to raise_error(Stripe::APIConnectionError)
    end
  end
end
