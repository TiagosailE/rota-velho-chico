require "rails_helper"

RSpec.describe "Operators::Sessions", type: :request do
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
