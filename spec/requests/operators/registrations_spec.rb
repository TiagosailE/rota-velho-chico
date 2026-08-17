require "rails_helper"

RSpec.describe "Operators::Registrations", type: :request do
  def valid_params(overrides = {})
    {
      operator: {
        name: "Agencia Nova",
        email: "agencia.nova@exemplo.com",
        phone: "+55 75 99999-0000",
        whatsapp: "+55 75 99999-0000",
        bio: "Passeios de barco e trilha em Paulo Afonso.",
        password: "senha-valida-123",
        password_confirmation: "senha-valida-123"
      }.merge(overrides)
    }
  end

  describe "GET /operators/sign_up" do
    it "mostra o formulario de cadastro" do
      get new_operator_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("devise.registrations.new.explanation"))
    end
  end

  describe "POST /operators" do
    it "cria a conta como active: false e manda pro login com aviso de analise" do
      post operator_registration_path, params: valid_params

      operator = Operator.find_by!(email: "agencia.nova@exemplo.com")
      expect(operator).not_to be_active
      expect(operator.name).to eq("Agencia Nova")
      expect(operator.phone).to eq("+55 75 99999-0000")
      expect(operator.bio).to eq("Passeios de barco e trilha em Paulo Afonso.")

      expect(response).to redirect_to(new_operator_session_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("devise.registrations.signed_up_but_pending_approval"))
    end

    it "gera o slug a partir do nome, resolvendo colisao" do
      create(:operator, name: "Agencia Existente", slug: "agencia-nova")

      post operator_registration_path, params: valid_params

      operator = Operator.find_by!(email: "agencia.nova@exemplo.com")
      expect(operator.slug).to eq("agencia-nova-2")
    end

    it "nao autentica a conta recem-criada -- ela ainda esta pendente" do
      post operator_registration_path, params: valid_params
      follow_redirect!

      get operators_root_path

      expect(response).to redirect_to(new_operator_session_path)
    end

    it "reexibe o formulario com erro quando invalido" do
      post operator_registration_path, params: valid_params(name: "")

      expect(response).to have_http_status(:unprocessable_content)
      expect(Operator.exists?(email: "agencia.nova@exemplo.com")).to be(false)
    end

    it "recusa senha e confirmacao diferentes" do
      post operator_registration_path, params: valid_params(password_confirmation: "outra-senha")

      expect(response).to have_http_status(:unprocessable_content)
      expect(Operator.exists?(email: "agencia.nova@exemplo.com")).to be(false)
    end
  end

  describe "edicao/exclusao de conta -- fora de escopo, neutralizadas" do
    it "GET /operators/edit redireciona pro painel" do
      operator = create(:operator)
      sign_in operator

      get edit_operator_registration_path

      expect(response).to redirect_to(operators_root_path)
    end

    it "PATCH /operators redireciona pro painel, sem alterar nada" do
      operator = create(:operator, name: "Nome Original")
      sign_in operator

      patch operator_registration_path, params: { operator: { name: "Nome Trocado" } }

      expect(response).to redirect_to(operators_root_path)
      expect(operator.reload.name).to eq("Nome Original")
    end

    it "DELETE /operators redireciona pro painel, sem apagar a conta" do
      operator = create(:operator)
      sign_in operator

      delete operator_registration_path

      expect(response).to redirect_to(operators_root_path)
      expect(Operator.exists?(operator.id)).to be(true)
    end
  end
end
