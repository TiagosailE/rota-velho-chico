require "rails_helper"

RSpec.describe "Operators::Departures", type: :request do
  describe "autenticacao" do
    it "redireciona para o login quando nao autenticado" do
      tour = create(:tour)

      get new_operators_tour_departure_path(tour)

      expect(response).to redirect_to(new_operator_session_path)
    end
  end

  describe "escopo do operador" do
    it "devolve 404 ao acessar saida de passeio de outro operador" do
      operator = create(:operator)
      other_tour = create(:tour, operator: create(:operator))
      other_departure = create(:departure, tour: other_tour)
      sign_in operator

      get operators_tour_departure_path(other_tour, other_departure)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /operators/tours/:tour_id/departures/new" do
    it "mostra o formulario de nova saida" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      sign_in operator

      get new_operators_tour_departure_path(tour)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /operators/tours/:tour_id/departures" do
    it "cria a saida, convertendo o preco especial de reais para centavos" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      sign_in operator

      post operators_tour_departures_path(tour), params: {
        departure: { starts_at: 10.days.from_now, capacity: 15, price_override_reais: "120.00" }
      }

      departure = tour.departures.last
      expect(departure.price_override_cents).to eq(12_000)
      expect(response).to redirect_to(operators_tour_departure_path(tour, departure))
    end

    it "reexibe o formulario com erro quando invalido" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      sign_in operator

      post operators_tour_departures_path(tour), params: { departure: { capacity: 0 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(tour.departures.count).to eq(0)
    end
  end

  describe "PATCH /operators/tours/:tour_id/departures/:id" do
    it "recusa reduzir a capacidade abaixo das vagas ja ocupadas" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      departure = create(:departure, tour:, capacity: 10, seats_taken: 6)
      sign_in operator

      patch operators_tour_departure_path(tour, departure), params: { departure: { capacity: 5 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("activerecord.errors.models.departure.attributes.capacity.below_seats_taken"))
      expect(departure.reload.capacity).to eq(10)
    end

    it "nao permite alterar status ou seats_taken pelo formulario" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      departure = create(:departure, tour:, status: :scheduled, seats_taken: 2)
      sign_in operator

      patch operators_tour_departure_path(tour, departure),
            params: { departure: { capacity: 20, status: "cancelled", seats_taken: 99 } }

      departure.reload
      expect(departure.status).to eq("scheduled")
      expect(departure.seats_taken).to eq(2)
      expect(departure.capacity).to eq(20)
    end

    it "remove o preco especial quando o campo de reais fica em branco" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      departure = create(:departure, tour:, price_override_cents: 15_000)
      sign_in operator

      patch operators_tour_departure_path(tour, departure), params: { departure: { price_override_reais: "" } }

      expect(response).to redirect_to(operators_tour_departure_path(tour, departure))
      expect(departure.reload.price_override_cents).to be_nil
    end
  end

  describe "GET /operators/tours/:tour_id/departures/:id" do
    it "mostra a taxa de ocupacao e a lista de reservas" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      departure = create(:departure, tour:, capacity: 10, seats_taken: 3)
      booking = create(:booking, departure:, customer_name: "Ana Turista")
      sign_in operator

      get operators_tour_departure_path(tour, departure)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("30%")
      expect(response.body).to include(booking.customer_name)
      expect(response.body).to include(booking.code)
    end
  end
end
