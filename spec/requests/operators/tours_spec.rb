require "rails_helper"

RSpec.describe "Operators::Tours", type: :request do
  describe "autenticacao" do
    it "redireciona para o login quando nao autenticado" do
      get operators_tours_path

      expect(response).to redirect_to(new_operator_session_path)
    end
  end

  describe "GET /operators/tours" do
    it "lista so os passeios do operador logado, nao de outros" do
      operator = create(:operator)
      other_operator = create(:operator)
      my_tour = create(:tour, operator:, title: "Meu Passeio")
      other_tour = create(:tour, operator: other_operator, title: "Passeio Alheio")
      sign_in operator

      get operators_tours_path

      expect(response.body).to include(my_tour.title)
      expect(response.body).not_to include(other_tour.title)
    end
  end

  describe "POST /operators/tours" do
    it "cria o passeio associado ao operador logado, mesmo sem operator_id no form" do
      operator = create(:operator)
      sign_in operator

      post operators_tours_path, params: {
        tour: {
          title: "Passeio Novo", slug: "passeio-novo", category: "boat", duration_minutes: 120,
          base_price_reais: "150.50", meeting_point: "Pier Central", min_age: 0
        }
      }

      tour = Tour.find_by(slug: "passeio-novo")
      expect(tour.operator).to eq(operator)
      expect(tour.base_price_cents).to eq(15_050)
      expect(response).to redirect_to(edit_operators_tour_path(tour))
    end

    it "reexibe o formulario com erro quando invalido" do
      operator = create(:operator)
      sign_in operator

      post operators_tours_path, params: { tour: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Tour.count).to eq(0)
    end
  end

  describe "GET /operators/tours/new" do
    it "mostra o formulario de novo passeio" do
      operator = create(:operator)
      sign_in operator

      get new_operators_tour_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET/PATCH /operators/tours/:id/edit" do
    it "devolve 404 ao tentar editar passeio de outro operador" do
      operator = create(:operator)
      other_tour = create(:tour, operator: create(:operator))
      sign_in operator

      get edit_operators_tour_path(other_tour)

      expect(response).to have_http_status(:not_found)
    end

    it "atualiza o passeio, convertendo reais para centavos" do
      operator = create(:operator)
      tour = create(:tour, operator:, base_price_cents: 10_000)
      sign_in operator

      patch operators_tour_path(tour), params: { tour: { base_price_reais: "99.90" } }

      expect(response).to redirect_to(edit_operators_tour_path(tour))
      expect(tour.reload.base_price_cents).to eq(9_990)
    end

    it "salva as coordenadas do ponto de encontro" do
      operator = create(:operator)
      tour = create(:tour, operator:, lat: nil, lng: nil)
      sign_in operator

      patch operators_tour_path(tour), params: { tour: { lat: "-9.4", lng: "-38.225" } }

      tour.reload
      expect(tour.lat).to eq(-9.4)
      expect(tour.lng).to eq(-38.225)
    end

    it "recusa atualizar o passeio de outro operador" do
      operator = create(:operator)
      other_tour = create(:tour, operator: create(:operator), title: "Original")
      sign_in operator

      patch operators_tour_path(other_tour), params: { tour: { title: "Sequestrado" } }

      expect(response).to have_http_status(:not_found)
      expect(other_tour.reload.title).to eq("Original")
    end

    it "reexibe o formulario de edicao com erro quando invalido" do
      operator = create(:operator)
      tour = create(:tour, operator:, title: "Original")
      sign_in operator

      patch operators_tour_path(tour), params: { tour: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(tour.reload.title).to eq("Original")
    end
  end
end
