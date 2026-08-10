require "rails_helper"

RSpec.describe "Operators::Sessions", type: :request do
  describe "GET /operators/sign_in" do
    it "mostra os rotulos do formulario em pt-BR, nao em ingles" do
      get new_operator_session_path

      expect(response.body).to include(">E-mail<")
      expect(response.body).to include(">Senha<")
      expect(response.body).not_to include(">Email<")
      expect(response.body).not_to include(">Password<")
    end
  end

  describe "POST /operators/sign_in" do
    it "loga e redireciona para o painel, nao para a home publica" do
      operator = create(:operator, password: "senha-valida-123")

      post operator_session_path, params: { operator: { email: operator.email, password: "senha-valida-123" } }

      expect(response).to redirect_to(operators_root_path)
    end

    it "recusa credenciais invalidas" do
      operator = create(:operator, password: "senha-valida-123")

      post operator_session_path, params: { operator: { email: operator.email, password: "senha-errada" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
