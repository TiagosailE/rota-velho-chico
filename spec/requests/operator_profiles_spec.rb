require "rails_helper"

RSpec.describe "OperatorProfiles", type: :request do
  describe "GET /agencias/:slug" do
    it "mostra nome, bio e passeios ativos do operador" do
      operator = create(:operator, name: "Agencia Teste", bio: "Somos otimos", slug: "agencia-teste")
      active_tour = create(:tour, operator:, title: "Passeio Ativo", active: true)
      inactive_tour = create(:tour, operator:, title: "Passeio Inativo", active: false)

      get operator_profile_path("agencia-teste")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Agencia Teste")
      expect(response.body).to include("Somos otimos")
      expect(response.body).to include(active_tour.title)
      expect(response.body).not_to include(inactive_tour.title)
    end

    it "mostra telefone e whatsapp quando presentes" do
      operator = create(:operator, slug: "agencia-contato", phone: "+55 75 3281-1000", whatsapp: "+55 75 99100-1000")

      get operator_profile_path("agencia-contato")

      expect(response.body).to include('href="tel:557532811000"')
      expect(response.body).to include('href="https://wa.me/5575991001000"')
    end

    it "mostra estado vazio quando o operador nao tem passeio ativo" do
      operator = create(:operator, slug: "agencia-sem-passeio")

      get operator_profile_path("agencia-sem-passeio")

      expect(response.body).to include(I18n.t("operator_profiles.show.tours_empty"))
    end

    it "devolve 404 para slug inexistente" do
      get operator_profile_path("nao-existe")

      expect(response).to have_http_status(:not_found)
    end

    it "devolve 404 para operador inativo" do
      operator = create(:operator, slug: "agencia-inativa", active: false)

      get operator_profile_path(operator.slug)

      expect(response).to have_http_status(:not_found)
    end
  end
end
