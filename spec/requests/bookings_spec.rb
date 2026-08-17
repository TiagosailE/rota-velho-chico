require "rails_helper"

RSpec.describe "Bookings", type: :request do
  def valid_params(overrides = {})
    {
      booking: {
        customer_name: "Ana Turista",
        customer_email: "ana@exemplo.com",
        customer_phone: "+55 75 99999-0000",
        adults: 2,
        children_5_9: 1,
        children_0_4: 0
      }.merge(overrides)
    }
  end

  describe "GET /departures/:departure_id/bookings/new" do
    it "mostra o formulario para uma saida de passeio ativo" do
      departure = create(:departure)

      get new_departure_booking_path(departure)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(departure.tour.title)
    end

    it "devolve 404 para saida de passeio inativo" do
      tour = create(:tour, active: false)
      departure = create(:departure, tour:)

      get new_departure_booking_path(departure)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /departures/:departure_id/bookings/price_summary" do
    it "recalcula o resumo de preco via GET, sem criar reserva" do
      departure = create(:departure, capacity: 10, seats_taken: 0)

      # O Stimulus controller manda o FormData do formulario inteiro, entao
      # os campos chegam aninhados em booking[...] -- igual ao POST de
      # create, nao soltos. Testar com o shape real evita reproduzir aqui o
      # mesmo bug que so apareceu simulando o campo mudando no navegador.
      get price_summary_departure_bookings_path(departure),
          params: { booking: { adults: 3, children_5_9: 1, children_0_4: 0, lunch_count: 0 } }

      calculator = PriceCalculator.new(unit_price_cents: departure.unit_price_cents, adults: 3, children_5_9: 1, children_0_4: 0)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ApplicationController.helpers.format_price_cents(calculator.total_cents))
      expect(Booking.count).to eq(0)
    end

    it "devolve 404 para saida de passeio inativo" do
      tour = create(:tour, active: false)
      departure = create(:departure, tour:)

      get price_summary_departure_bookings_path(departure), params: { booking: { adults: 1 } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /departures/:departure_id/bookings" do
    it "cria a reserva, incrementa seats_taken e redireciona para a confirmacao com o codigo" do
      departure = create(:departure, capacity: 10, seats_taken: 0)

      post departure_bookings_path(departure), params: valid_params
      booking = Booking.last

      expect(response).to redirect_to(booking_confirmation_path)
      follow_redirect!
      expect(response.body).to include(booking.code)
      expect(departure.reload.seats_taken).to eq(3)
    end

    it "envia o e-mail de reserva registrada com o codigo" do
      departure = create(:departure, capacity: 10, seats_taken: 0)

      expect { post departure_bookings_path(departure), params: valid_params }
        .to have_enqueued_mail(BookingMailer, :booking_created)
    end

    it "nao vaza o flash[:booking_id] interno como toast na tela de confirmacao" do
      departure = create(:departure, capacity: 10, seats_taken: 0)

      post departure_bookings_path(departure), params: valid_params
      follow_redirect!

      expect(response.body).not_to include('class="toast toast-')
    end

    it "recusa quando nao ha vagas suficientes" do
      departure = create(:departure, capacity: 1, seats_taken: 1)

      post departure_bookings_path(departure), params: valid_params(adults: 1, children_5_9: 0, children_0_4: 0)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("bookings.errors.sold_out"))
      expect(Booking.count).to eq(0)
    end

    it "recusa grupo vazio" do
      departure = create(:departure)

      post departure_bookings_path(departure), params: valid_params(adults: 0, children_5_9: 0, children_0_4: 0)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("bookings.errors.invalid_party"))
      expect(Booking.count).to eq(0)
    end

    it "recusa saida cancelada" do
      departure = create(:departure, status: :cancelled)

      post departure_bookings_path(departure), params: valid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("bookings.errors.departure_not_scheduled"))
      expect(Booking.count).to eq(0)
    end

    it "cria a reserva com almoco quando o passeio oferece o add-on" do
      tour = create(:tour, :with_lunch)
      departure = create(:departure, tour:, capacity: 10, seats_taken: 0)

      post departure_bookings_path(departure), params: valid_params(lunch_count: 2)
      booking = Booking.last

      expect(response).to redirect_to(booking_confirmation_path)
      expect(booking.lunch_count).to eq(2)
      expect(booking.lunch_unit_price_cents).to eq(tour.lunch_price_cents)
    end

    it "recusa lunch_count quando o passeio nao oferece almoco" do
      departure = create(:departure, tour: create(:tour, lunch_price_cents: nil))

      post departure_bookings_path(departure), params: valid_params(lunch_count: 1)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("bookings.errors.invalid_lunch_count"))
      expect(Booking.count).to eq(0)
    end

    it "recusa nome em branco com mensagem legivel, sem criar a reserva" do
      departure = create(:departure)

      post departure_bookings_path(departure), params: valid_params(customer_name: "")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome")
      expect(Booking.count).to eq(0)
    end

    it "devolve 404 para saida de passeio inativo" do
      tour = create(:tour, active: false)
      departure = create(:departure, tour:)

      post departure_bookings_path(departure), params: valid_params

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /bookings/confirmation" do
    it "redireciona para a home quando acessado sem ter acabado de reservar" do
      get booking_confirmation_path

      expect(response).to redirect_to(root_path)
    end
  end
end
