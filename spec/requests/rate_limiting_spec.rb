require "rails_helper"

# Cada endpoint limitado tem seu proprio `with:` -- muda o destino do redirect
# e, no caso da reserva, ate o motivo do limite existir. Um teste por endpoint,
# entao, nao e repeticao: e o unico jeito de garantir que a resposta de
# excesso leva o visitante pra algum lugar util em vez de um 429 cru.
#
# Os contadores vivem numa store de cache com escopo de processo e sao zerados
# entre exemplos por spec/support/rate_limiting.rb.
RSpec.describe "Rate limiting", type: :request do
  describe "POST /operators/sign_in" do
    it "corta as tentativas depois do limite, em vez de aceitar senha atras de senha" do
      operator = create(:operator, password: "senha-valida-123")
      credentials = { operator: { email: operator.email, password: "senha-errada" } }

      10.times { post operator_session_path, params: credentials }
      expect(response).to have_http_status(:unprocessable_content)

      post operator_session_path, params: credentials

      expect(response).to redirect_to(new_operator_session_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("rate_limit.exceeded"))
    end

    it "nao atrapalha quem erra a senha poucas vezes e acerta depois" do
      operator = create(:operator, password: "senha-valida-123")

      3.times do
        post operator_session_path, params: { operator: { email: operator.email, password: "senha-errada" } }
      end
      post operator_session_path, params: { operator: { email: operator.email, password: "senha-valida-123" } }

      expect(response).to redirect_to(operators_root_path)
    end
  end

  describe "POST /booking_lookup" do
    it "corta a varredura de codigos depois do limite" do
      attempt = { code: "ZZZZZZ", email: "ana@exemplo.com" }

      10.times { post booking_lookup_path, params: attempt }
      expect(response).to have_http_status(:unprocessable_content)

      post booking_lookup_path, params: attempt

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("rate_limit.exceeded"))
    end
  end

  describe "POST /bookings/:code/cancel" do
    it "corta a varredura depois do limite" do
      booking = create(:booking, code: "ABCDEF", customer_email: "ana@exemplo.com")
      attempt = { email: "chute@exemplo.com" }

      10.times { post cancel_booking_path(booking.code), params: attempt }
      expect(flash[:alert]).to eq(I18n.t("booking_lookups.not_found"))

      post cancel_booking_path(booking.code), params: attempt

      expect(flash[:alert]).to eq(I18n.t("rate_limit.exceeded"))
      expect(booking.reload).to be_pending
    end
  end

  describe "POST /bookings/:code/review" do
    it "corta a varredura depois do limite" do
      booking = create(:booking, code: "ABCDEF", customer_email: "ana@exemplo.com")
      attempt = { email: "chute@exemplo.com", review: { rating: 5, comment: "otimo" } }

      10.times { post review_booking_path(booking.code), params: attempt }
      expect(flash[:alert]).to eq(I18n.t("booking_lookups.not_found"))

      post review_booking_path(booking.code), params: attempt

      expect(flash[:alert]).to eq(I18n.t("rate_limit.exceeded"))
      expect(Review.count).to eq(0)
    end
  end

  describe "POST /bookings/:code/pay" do
    # Reserva ja confirmada para o controller sair antes do Stripe: o objetivo
    # aqui e o limite, e spec nao toca a rede (NOTES.md).
    it "corta as tentativas depois do limite, sem abrir sessao no Stripe" do
      booking = create(:booking, code: "ABCDEF", status: :confirmed)

      10.times { post pay_booking_path(booking.code) }
      expect(flash[:alert]).to eq(I18n.t("checkout.errors.not_payable"))

      post pay_booking_path(booking.code)

      expect(flash[:alert]).to eq(I18n.t("rate_limit.exceeded"))
    end
  end

  describe "POST /departures/:departure_id/bookings" do
    it "corta o laco que esgotaria as vagas sem pagar" do
      departure = create(:departure, capacity: 30, seats_taken: 0)
      attempt = {
        booking: {
          customer_name: "Ana Turista", customer_email: "ana@exemplo.com",
          customer_phone: "+55 75 99999-0000", adults: 0, children_5_9: 0, children_0_4: 0
        }
      }

      10.times { post departure_bookings_path(departure), params: attempt }
      expect(response).to have_http_status(:unprocessable_content)

      post departure_bookings_path(departure), params: attempt

      expect(response).to redirect_to(new_departure_booking_path(departure))
      follow_redirect!
      expect(response.body).to include(I18n.t("rate_limit.exceeded"))
    end
  end
end
