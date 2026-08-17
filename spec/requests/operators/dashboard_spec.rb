require "rails_helper"

RSpec.describe "Operators::Dashboard", type: :request do
  describe "autenticacao" do
    it "redireciona para o login quando nao autenticado" do
      get operators_root_path

      expect(response).to redirect_to(new_operator_session_path)
    end
  end

  describe "GET /operators" do
    it "soma so o sinal de pagamento succeeded, excluindo reserva ja estornada" do
      operator = create(:operator)
      tour = create(:tour, operator:, title: "Catamara Popular")
      departure = create(:departure, tour:, capacity: 10, seats_taken: 5)

      confirmed = create(:booking, departure:, status: :confirmed)
      create(:payment, booking: confirmed, status: :succeeded, amount_cents: 8_100)

      # Reflete o unico jeito real de um pagamento virar refunded no app
      # (BookingCanceller/RefundBookingJob): status e refunded_amount_cents
      # mudam juntos, sempre o valor cheio -- nunca fica succeeded com
      # estorno parcial registrado.
      refunded = create(:booking, departure:, status: :refunded)
      create(:payment, booking: refunded, status: :refunded, amount_cents: 8_100, refunded_amount_cents: 8_100)

      sign_in operator

      get operators_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ApplicationController.helpers.format_price_cents(8_100))
      expect(response.body).to include("Catamara Popular")
    end

    it "conta reservas confirmadas e calcula a ocupacao media das saidas futuras, com precisao" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      departure_a = create(:departure, tour:, capacity: 10, seats_taken: 5, starts_at: 5.days.from_now)
      departure_b = create(:departure, tour:, capacity: 10, seats_taken: 3, starts_at: 8.days.from_now)
      create(:departure, tour:, capacity: 10, seats_taken: 10, starts_at: 2.days.ago, status: :completed)

      create(:booking, departure: departure_a, status: :confirmed)
      create(:booking, departure: departure_b, status: :confirmed)
      create(:booking, departure: departure_a, status: :pending)

      sign_in operator

      get operators_root_path

      page = Capybara::Node::Simple.new(response.body)
      metric_values = page.all(".card p.text-2xl").map(&:text)

      expect(metric_values).to include("2") # reservas confirmadas
      expect(metric_values).to include("40%") # media entre 50% e 30%, saidas futuras so
      expect(page).to have_content(departure_a.starts_at.strftime("%d/%m/%Y %H:%M"))
      expect(page).to have_content(departure_b.starts_at.strftime("%d/%m/%Y %H:%M"))
    end

    it "nao mistura dados de outro operador" do
      operator = create(:operator)
      other_operator = create(:operator)
      other_tour = create(:tour, operator: other_operator)
      other_departure = create(:departure, tour: other_tour)
      other_booking = create(:booking, departure: other_departure, status: :confirmed)
      create(:payment, booking: other_booking, status: :succeeded, amount_cents: 50_000)

      sign_in operator

      get operators_root_path

      expect(response.body).to include(ApplicationController.helpers.format_price_cents(0))
      expect(response.body).not_to include(other_tour.title)
    end

    it "mostra estados vazios quando o operador ainda nao tem reserva nem saida futura" do
      operator = create(:operator)
      sign_in operator

      get operators_root_path

      expect(response.body).to include(I18n.t("operators.dashboard.top_tour_empty"))
      expect(response.body).to include(I18n.t("operators.dashboard.average_occupancy_empty"))
      expect(response.body).to include(I18n.t("operators.dashboard.upcoming_departures_empty"))
    end

    it "mostra o convite pra conectar o Stripe quando o operador ainda nao tem pagamentos habilitados" do
      operator = create(:operator, :stripe_disconnected)
      sign_in operator

      get operators_root_path

      expect(response.body).to include(I18n.t("operators.stripe_connect.prompt.title"))
      expect(response.body).not_to include(I18n.t("operators.stripe_connect.connected"))
    end

    it "mostra o status conectado quando o operador ja habilitou pagamentos" do
      operator = create(:operator)
      sign_in operator

      get operators_root_path

      expect(response.body).to include(I18n.t("operators.stripe_connect.connected"))
      expect(response.body).not_to include(I18n.t("operators.stripe_connect.prompt.title"))
    end
  end
end
