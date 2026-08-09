require "rails_helper"

RSpec.describe "Tours", type: :request do
  describe "GET /tours" do
    it "lista passeios ativos" do
      tour = create(:tour, active: true)
      create(:tour, active: false)

      get tours_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tour.title)
    end

    it "filtra por categoria" do
      boat = create(:tour, category: :boat)
      hiking = create(:tour, category: :hiking)

      get tours_path(category: "hiking")

      expect(response.body).to include(hiking.title)
      expect(response.body).not_to include(boat.title)
    end

    it "ignora categoria invalida em vez de quebrar" do
      tour = create(:tour)

      get tours_path(category: "nao-existe")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tour.title)
    end

    it "filtra por data, considerando so passeios com saida agendada naquele dia" do
      target_date = 10.days.from_now.to_date
      with_departure = create(:tour)
      create(:departure, tour: with_departure, starts_at: target_date.in_time_zone.change(hour: 9))

      without_departure = create(:tour)
      create(:departure, tour: without_departure, starts_at: (target_date + 1).in_time_zone.change(hour: 9))

      get tours_path(date: target_date.to_s)

      expect(response.body).to include(with_departure.title)
      expect(response.body).not_to include(without_departure.title)
    end

    it "nao lista passeio cuja unica saida na data esta cancelada" do
      target_date = 10.days.from_now.to_date
      tour = create(:tour)
      create(:departure, tour:, starts_at: target_date.in_time_zone.change(hour: 9), status: :cancelled)

      get tours_path(date: target_date.to_s)

      expect(response.body).not_to include(tour.title)
    end

    it "ignora data invalida em vez de quebrar" do
      tour = create(:tour)

      get tours_path(date: "nao-e-uma-data")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tour.title)
    end

    it "ignora preco invalido em vez de quebrar" do
      tour = create(:tour)

      get tours_path(min_price: "nao-e-numero")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tour.title)
    end

    it "filtra por faixa de preco" do
      cheap = create(:tour, base_price_cents: 5_000)
      expensive = create(:tour, base_price_cents: 20_000)

      get tours_path(min_price: "100", max_price: "150")

      expect(response.body).not_to include(cheap.title)
      expect(response.body).not_to include(expensive.title)
    end

    it "combina categoria e faixa de preco" do
      match = create(:tour, category: :offroad, base_price_cents: 18_000)
      wrong_category = create(:tour, category: :boat, base_price_cents: 18_000)
      wrong_price = create(:tour, category: :offroad, base_price_cents: 5_000)

      get tours_path(category: "offroad", min_price: "100", max_price: "200")

      expect(response.body).to include(match.title)
      expect(response.body).not_to include(wrong_category.title)
      expect(response.body).not_to include(wrong_price.title)
    end

    it "mostra estado vazio quando nenhum passeio bate com os filtros" do
      create(:tour, base_price_cents: 5_000)

      get tours_path(min_price: "100")

      expect(response.body).to include(I18n.t("tours.index.empty"))
    end
  end

  describe "GET /tours/:slug" do
    it "mostra o passeio encontrado" do
      tour = create(:tour, slug: "passeio-teste", description: "Descricao de teste", duration_minutes: 90)

      get tour_path("passeio-teste")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(tour.title)
      expect(response.body).to include(tour.description)
      expect(response.body).to include("1h30")
    end

    it "devolve 404 para slug inexistente" do
      get tour_path("nao-existe")

      expect(response).to have_http_status(:not_found)
    end

    it "devolve 404 para passeio inativo" do
      tour = create(:tour, slug: "passeio-inativo", active: false)

      get tour_path(tour.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "lista so saidas futuras e agendadas" do
      tour = create(:tour, slug: "passeio-com-saidas")
      future = create(:departure, tour:, starts_at: 5.days.from_now.change(hour: 9))
      create(:departure, tour:, starts_at: 5.days.ago.change(hour: 9), status: :completed)
      create(:departure, tour:, starts_at: 6.days.from_now.change(hour: 9), status: :cancelled)

      get tour_path(tour.slug)

      expect(response.body).to include(future.starts_at.strftime("%d/%m/%Y"))
    end

    it "mostra estado vazio quando nao ha saida futura" do
      tour = create(:tour, slug: "passeio-sem-saidas")

      get tour_path(tour.slug)

      expect(response.body).to include(I18n.t("tours.show.no_departures"))
    end
  end
end
