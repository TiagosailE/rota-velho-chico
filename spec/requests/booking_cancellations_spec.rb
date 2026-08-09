require "rails_helper"

RSpec.describe "BookingCancellations", type: :request do
  describe "POST /bookings/:code/cancel" do
    it "cancela e mostra a confirmacao com o novo status quando codigo e e-mail batem" do
      departure = create(:departure, capacity: 10, seats_taken: 1, starts_at: 10.hours.from_now)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :pending,
                                  adults: 1, children_5_9: 0, children_0_4: 0)

      post cancel_booking_path("ABCDEF"), params: { email: "ana@exemplo.com" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("bookings.confirmation.status_cancelled"))
      expect(booking.reload).to be_cancelled
      expect(departure.reload.seats_taken).to eq(0)
    end

    it "estorna quando ha pagamento dentro do prazo, e mostra status estornada" do
      departure = create(:departure, capacity: 10, seats_taken: 1, starts_at: 10.days.from_now)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :confirmed,
                                  adults: 1, children_5_9: 0, children_0_4: 0)
      create(:payment, booking:, status: :succeeded, stripe_payment_intent_id: "pi_test_123")
      allow(Stripe::Refund).to receive(:create).and_return(instance_double(Stripe::Refund, id: "re_test_123"))

      post cancel_booking_path("ABCDEF"), params: { email: "ana@exemplo.com" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("bookings.confirmation.status_refunded"))
    end

    it "recusa com mensagem generica quando o e-mail nao bate, sem cancelar" do
      departure = create(:departure, seats_taken: 1)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :pending)

      post cancel_booking_path("ABCDEF"), params: { email: "outra@exemplo.com" }

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("booking_lookups.not_found"))
      expect(booking.reload).to be_pending
      expect(departure.reload.seats_taken).to eq(1)
    end

    it "recusa reserva ja cancelada" do
      booking = create(:booking, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :cancelled)

      post cancel_booking_path("ABCDEF"), params: { email: "ana@exemplo.com" }

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("bookings.cancellation.errors.already_cancelled"))
    end

    it "mostra mensagem generica quando o Stripe falha ao estornar" do
      departure = create(:departure, seats_taken: 1, starts_at: 10.days.from_now)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :confirmed)
      create(:payment, booking:, status: :succeeded)
      allow(Stripe::Refund).to receive(:create).and_raise(Stripe::APIConnectionError.new("timeout"))

      post cancel_booking_path("ABCDEF"), params: { email: "ana@exemplo.com" }

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("checkout.errors.unavailable"))
      expect(booking.reload).to be_confirmed
    end
  end
end
