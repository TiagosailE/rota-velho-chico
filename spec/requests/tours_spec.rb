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

    it "mostra a nota media no card quando o passeio tem avaliacao" do
      tour = create(:tour)
      departure = create(:departure, tour:, starts_at: 2.days.ago)
      booking = create(:booking, departure:, status: :confirmed)
      create(:review, booking:, rating: 4)

      get tours_path

      expect(response.body).to include(I18n.t("tours.index.card.rating", rating: 4.0, count: 1))
    end

    it "mostra a contagem de passeios encontrados" do
      create_list(:tour, 2)

      get tours_path

      expect(response.body).to include(I18n.t("tours.index.results", count: 2))
    end

    it "usa a capa de um passeio ativo como foto do hero" do
      tour = create(:tour, active: true)
      photo = create(:tour_photo, tour:, position: 0)

      get tours_path

      expect(response.body).to include(url_for(photo.image.variant(:hero)))
    end

    it "nao usa foto de passeio inativo no hero" do
      inactive = create(:tour, active: false)
      photo = create(:tour_photo, tour: inactive, position: 0)

      get tours_path

      expect(response.body).not_to include(url_for(photo.image.variant(:hero)))
    end

    it "renderiza o hero sem foto nenhuma sem quebrar" do
      create(:tour, active: true)

      get tours_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("tours.index.hero.title"))
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

    it "mostra o preco do almoco quando o passeio oferece o add-on" do
      tour = create(:tour, :with_lunch, slug: "passeio-com-almoco")

      get tour_path(tour.slug)

      expect(response.body).to include(I18n.t("tours.show.lunch_price", price: "R$ 75,00"))
    end

    it "nao mostra o bloco de almoco quando o passeio nao oferece o add-on" do
      tour = create(:tour, slug: "passeio-sem-almoco", lunch_price_cents: nil)

      get tour_path(tour.slug)

      expect(response.body).not_to include(I18n.t("tours.show.lunch_label"))
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

    it "mostra o calendario do mes atual, com horario e vagas no dia da saida agendada" do
      tour = create(:tour, slug: "passeio-com-saidas")
      departure = create(:departure, tour:, starts_at: 5.days.from_now.change(hour: 9), capacity: 12, seats_taken: 2)

      get tour_path(tour.slug)

      expect(response.body).to include(departure.starts_at.strftime("%H:%M"))
      expect(response.body).to include(I18n.t("tours.show.seats_available", count: 10))
    end

    it "nao mostra no calendario uma saida cancelada ou concluida" do
      tour = create(:tour, slug: "passeio-sem-disponibilidade")
      create(:departure, tour:, starts_at: 5.days.from_now.change(hour: 9), status: :cancelled)
      create(:departure, tour:, starts_at: 6.days.from_now.change(hour: 9), status: :completed)

      get tour_path(tour.slug)

      expect(response.body).to include(I18n.t("tours.show.no_departures"))
    end

    it "navega para outro mes via parametro month, sem afetar o mes atual" do
      tour = create(:tour, slug: "passeio-mes-que-vem")
      next_month = Date.current.next_month.beginning_of_month
      departure = create(:departure, tour:, starts_at: (next_month + 10.days).in_time_zone.change(hour: 9))

      get tour_path(tour.slug), params: { month: next_month.strftime("%Y-%m") }

      expect(response.body).to include(departure.starts_at.strftime("%H:%M"))
    end

    it "ignora parametro month invalido e usa o mes atual" do
      tour = create(:tour, slug: "passeio-mes-invalido")
      departure = create(:departure, tour:, starts_at: 3.days.from_now.change(hour: 9))

      get tour_path(tour.slug), params: { month: "nao-e-um-mes" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(departure.starts_at.strftime("%H:%M"))
    end

    it "nao mostra no calendario uma saida que ja passou hoje" do
      tour = create(:tour, slug: "passeio-com-saida-passada")
      create(:departure, tour:, starts_at: 1.hour.ago)

      get tour_path(tour.slug)

      expect(response.body).to include(I18n.t("tours.show.no_departures"))
    end

    it "mostra estado vazio quando nao ha saida no mes" do
      tour = create(:tour, slug: "passeio-sem-saidas")

      get tour_path(tour.slug)

      expect(response.body).to include(I18n.t("tours.show.no_departures"))
    end

    it "nao mostra o mapa quando o passeio nao tem coordenadas" do
      tour = create(:tour, slug: "passeio-sem-mapa", lat: nil, lng: nil)

      get tour_path(tour.slug)

      expect(response.body).not_to include(I18n.t("tours.show.location_title"))
    end

    it "mostra o mapa com as coordenadas quando o passeio tem lat/lng" do
      tour = create(:tour, slug: "passeio-com-mapa", lat: -9.4, lng: -38.225)

      get tour_path(tour.slug)

      expect(response.body).to include(I18n.t("tours.show.location_title"))
      expect(response.body).to include('data-map-lat-value="-9.4"')
      expect(response.body).to include('data-map-lng-value="-38.225"')
    end

    it "mostra mensagem de vazio quando o passeio nao tem avaliacao" do
      tour = create(:tour, slug: "passeio-sem-avaliacao")

      get tour_path(tour.slug)

      expect(response.body).to include(I18n.t("tours.show.reviews_empty"))
    end

    it "lista as avaliacoes com nota e comentario quando existem" do
      tour = create(:tour, slug: "passeio-avaliado")
      departure = create(:departure, tour:, starts_at: 2.days.ago)
      booking = create(:booking, departure:, status: :confirmed)
      create(:review, booking:, rating: 5, comment: "Experiencia incrivel")

      get tour_path(tour.slug)

      expect(response.body).to include("Experiencia incrivel")
      expect(response.body).to include(I18n.t("tours.show.reviews_summary", rating: 5.0, count: 1))
    end
  end
end
