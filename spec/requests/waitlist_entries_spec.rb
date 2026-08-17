require "rails_helper"

RSpec.describe "WaitlistEntries", type: :request do
  def valid_params(overrides = {})
    {
      waitlist_entry: {
        customer_name: "Ana Turista",
        customer_email: "ana@exemplo.com",
        customer_phone: "+55 75 99999-0000",
        adults: 2,
        children_5_9: 0,
        children_0_4: 0
      }.merge(overrides)
    }
  end

  describe "GET /departures/:departure_id/waitlist_entries/new" do
    it "mostra o formulario quando a saida esta esgotada" do
      departure = create(:departure, capacity: 5, seats_taken: 5)

      get new_departure_waitlist_entry_path(departure)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(departure.tour.title)
    end

    it "redireciona para o formulario de reserva quando ainda ha vaga" do
      departure = create(:departure, capacity: 5, seats_taken: 3)

      get new_departure_waitlist_entry_path(departure)

      expect(response).to redirect_to(new_departure_booking_path(departure))
    end

    it "devolve 404 para saida de passeio inativo" do
      tour = create(:tour, active: false)
      departure = create(:departure, tour:, capacity: 5, seats_taken: 5)

      get new_departure_waitlist_entry_path(departure)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /departures/:departure_id/waitlist_entries" do
    it "cria a entrada e redireciona para o passeio com aviso de sucesso" do
      departure = create(:departure, capacity: 5, seats_taken: 5)

      post departure_waitlist_entries_path(departure), params: valid_params

      expect(response).to redirect_to(tour_path(departure.tour.slug))
      expect(WaitlistEntry.count).to eq(1)
      expect(WaitlistEntry.last.customer_email).to eq("ana@exemplo.com")
    end

    it "nao cria entrada quando ainda ha vaga -- manda pro formulario de reserva" do
      departure = create(:departure, capacity: 5, seats_taken: 3)

      post departure_waitlist_entries_path(departure), params: valid_params

      expect(response).to redirect_to(new_departure_booking_path(departure))
      expect(WaitlistEntry.count).to eq(0)
    end

    it "recusa grupo vazio" do
      departure = create(:departure, capacity: 5, seats_taken: 5)

      post departure_waitlist_entries_path(departure), params: valid_params(adults: 0, children_5_9: 0, children_0_4: 0)

      expect(response).to have_http_status(:unprocessable_content)
      expect(WaitlistEntry.count).to eq(0)
    end

    it "devolve 404 para saida de passeio inativo" do
      tour = create(:tour, active: false)
      departure = create(:departure, tour:, capacity: 5, seats_taken: 5)

      post departure_waitlist_entries_path(departure), params: valid_params

      expect(response).to have_http_status(:not_found)
    end
  end
end
