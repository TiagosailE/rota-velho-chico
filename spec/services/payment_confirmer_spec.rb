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

    it "envia o recibo e agenda lembrete (24h antes) e pedido de avaliacao (1 dia depois da saida)" do
      departure = create(:departure, starts_at: 10.days.from_now.change(hour: 9))
      booking = create(:booking, departure:, status: :pending)
      create(:payment, booking:, stripe_checkout_session_id: "cs_test_123", stripe_payment_intent_id: nil, status: :pending)

      expect {
        described_class.new(stripe_checkout_session_id: "cs_test_123", stripe_payment_intent_id: "pi_test_123").call
      }
        .to have_enqueued_mail(BookingMailer, :payment_received).with(booking)
        .and have_enqueued_mail(BookingMailer, :departure_reminder).with(booking).at(departure.starts_at - 24.hours)
        .and have_enqueued_mail(BookingMailer, :review_request).with(booking).at(departure.starts_at + 1.day)
    end
  end
end
