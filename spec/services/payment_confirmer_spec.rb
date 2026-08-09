require "rails_helper"

RSpec.describe PaymentConfirmer do
  describe "#call" do
    it "marca o Payment como succeeded e a Booking como confirmed" do
      booking = create(:booking, status: :pending)
      payment = create(:payment, booking:, stripe_payment_intent_id: "pi_test_123", status: :pending)

      described_class.new(stripe_payment_intent_id: "pi_test_123").call

      expect(payment.reload).to be_succeeded
      expect(payment.paid_at).to be_present
      expect(booking.reload).to be_confirmed
    end

    it "nao faz nada quando nao existe Payment com esse intent id" do
      booking = create(:booking, status: :pending)
      create(:payment, booking:, stripe_payment_intent_id: "pi_test_outro")

      expect { described_class.new(stripe_payment_intent_id: "pi_test_inexistente").call }
        .not_to raise_error

      expect(booking.reload).to be_pending
    end
  end
end
