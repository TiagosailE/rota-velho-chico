require "rails_helper"

RSpec.describe PaymentConfirmer do
  describe "#call" do
    it "marca o Payment como succeeded, guarda o payment_intent e confirma a Booking" do
      booking = create(:booking, status: :pending)
      payment = create(:payment, booking:, stripe_checkout_session_id: "cs_test_123",
                                  stripe_payment_intent_id: nil, status: :pending)

      described_class.new(stripe_checkout_session_id: "cs_test_123", stripe_payment_intent_id: "pi_test_123").call

      expect(payment.reload).to be_succeeded
      expect(payment.stripe_payment_intent_id).to eq("pi_test_123")
      expect(payment.paid_at).to be_present
      expect(booking.reload).to be_confirmed
    end

    it "nao faz nada quando nao existe Payment com esse id de sessao" do
      booking = create(:booking, status: :pending)
      create(:payment, booking:, stripe_checkout_session_id: "cs_test_outro")

      expect {
        described_class.new(stripe_checkout_session_id: "cs_test_inexistente", stripe_payment_intent_id: "pi_test_x").call
      }.not_to raise_error

      expect(booking.reload).to be_pending
    end
  end
end
