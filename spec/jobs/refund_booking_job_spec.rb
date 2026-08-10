require "rails_helper"

RSpec.describe RefundBookingJob do
  include ActiveJob::TestHelper

  def stub_stripe_refund(refund_id: "re_test_123")
    allow(Stripe::Refund).to receive(:create).and_return(instance_double(Stripe::Refund, id: refund_id))
  end

  describe "#perform" do
    it "estorna no Stripe e marca payment/booking como refunded quando havia pagamento" do
      booking = create(:booking, status: :cancelled)
      payment = create(:payment, booking:, status: :succeeded, amount_cents: 8_100,
                                  stripe_payment_intent_id: "pi_test_123")
      stub_stripe_refund

      described_class.new.perform(booking.id)

      expect(Stripe::Refund).to have_received(:create).with(payment_intent: "pi_test_123")
      expect(payment.reload).to be_refunded
      expect(payment.refunded_amount_cents).to eq(8_100)
      expect(booking.reload).to be_refunded
    end

    it "nao chama o Stripe quando a reserva nunca foi paga" do
      booking = create(:booking, status: :cancelled)
      allow(Stripe::Refund).to receive(:create)

      described_class.new.perform(booking.id)

      expect(Stripe::Refund).not_to have_received(:create)
      expect(booking.reload.status).to eq("cancelled")
    end

    it "nao processa reserva que nao esta cancelled" do
      booking = create(:booking, status: :confirmed)
      create(:payment, booking:, status: :succeeded)
      allow(Stripe::Refund).to receive(:create)

      described_class.new.perform(booking.id)

      expect(Stripe::Refund).not_to have_received(:create)
      expect(booking.reload.status).to eq("confirmed")
    end

    it "envia o e-mail de cancelamento" do
      booking = create(:booking, status: :cancelled)

      expect { described_class.new.perform(booking.id) }
        .to have_enqueued_mail(BookingMailer, :departure_cancelled)
    end

    it "deixa Stripe::StripeError subir sem enviar e-mail -- job fica reprocessavel" do
      booking = create(:booking, status: :cancelled)
      create(:payment, booking:, status: :succeeded)
      allow(Stripe::Refund).to receive(:create).and_raise(Stripe::APIConnectionError.new("timeout"))

      expect { described_class.new.perform(booking.id) }.to raise_error(Stripe::APIConnectionError)
      expect(booking.reload.status).to eq("cancelled")
    end
  end
end
