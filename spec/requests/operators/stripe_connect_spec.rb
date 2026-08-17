require "rails_helper"

RSpec.describe "Operators::StripeConnect", type: :request do
  def stub_account_create(id: "acct_test_new")
    allow(Stripe::Account).to receive(:create).and_return(instance_double(Stripe::Account, id:))
  end

  def stub_account_link(url: "https://connect.stripe.com/setup/e/acct_test_new/xyz")
    allow(Stripe::AccountLink).to receive(:create).and_return(instance_double(Stripe::AccountLink, url:))
  end

  def stub_account_retrieve(charges_enabled:)
    allow(Stripe::Account).to receive(:retrieve).and_return(instance_double(Stripe::Account, charges_enabled:))
  end

  describe "autenticacao" do
    it "redireciona para o login quando nao autenticado" do
      post operators_stripe_connect_path

      expect(response).to redirect_to(new_operator_session_path)
    end
  end

  describe "POST /operators/stripe_connect" do
    it "cria a conta conectada quando o operador ainda nao tem uma, e redireciona pro onboarding" do
      operator = create(:operator, :stripe_disconnected)
      stub_account_create(id: "acct_test_new")
      stub_account_link(url: "https://connect.stripe.com/setup/e/acct_test_new/xyz")
      sign_in operator

      post operators_stripe_connect_path

      expect(Stripe::Account).to have_received(:create).with(
        hash_including(type: "express", country: "BR", email: operator.email)
      )
      expect(Stripe::AccountLink).to have_received(:create).with(
        hash_including(account: "acct_test_new", type: "account_onboarding")
      )
      expect(response).to redirect_to("https://connect.stripe.com/setup/e/acct_test_new/xyz")
      expect(operator.reload.stripe_account_id).to eq("acct_test_new")
    end

    it "reaproveita a conta existente em vez de criar outra, quando o operador ja tem uma" do
      operator = create(:operator, stripe_account_id: "acct_test_existing", stripe_charges_enabled: false)
      allow(Stripe::Account).to receive(:create)
      stub_account_link
      sign_in operator

      post operators_stripe_connect_path

      expect(Stripe::Account).not_to have_received(:create)
      expect(Stripe::AccountLink).to have_received(:create).with(hash_including(account: "acct_test_existing"))
    end

    it "mostra mensagem generica quando o Stripe falha" do
      operator = create(:operator, :stripe_disconnected)
      allow(Stripe::Account).to receive(:create).and_raise(Stripe::APIConnectionError.new("timeout"))
      sign_in operator

      post operators_stripe_connect_path

      expect(response).to redirect_to(operators_root_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("operators.stripe_connect.errors.unavailable"))
    end
  end

  describe "GET /operators/stripe_connect/refresh" do
    it "gera um link novo pra mesma conta, sem recriar a conta" do
      operator = create(:operator, stripe_account_id: "acct_test_existing", stripe_charges_enabled: false)
      allow(Stripe::Account).to receive(:create)
      stub_account_link
      sign_in operator

      get operators_stripe_connect_refresh_path

      expect(Stripe::Account).not_to have_received(:create)
      expect(response).to redirect_to("https://connect.stripe.com/setup/e/acct_test_new/xyz")
    end
  end

  describe "GET /operators/stripe_connect/return" do
    it "consulta a conta e liga o sinalizador quando o onboarding foi concluido" do
      operator = create(:operator, stripe_account_id: "acct_test_existing", stripe_charges_enabled: false)
      stub_account_retrieve(charges_enabled: true)
      sign_in operator

      get operators_stripe_connect_return_path

      expect(operator.reload).to be_stripe_charges_enabled
      expect(response).to redirect_to(operators_root_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("operators.stripe_connect.return.success"))
    end

    it "mantem desligado e avisa quando o onboarding ainda esta incompleto" do
      operator = create(:operator, stripe_account_id: "acct_test_existing", stripe_charges_enabled: false)
      stub_account_retrieve(charges_enabled: false)
      sign_in operator

      get operators_stripe_connect_return_path

      expect(operator.reload).not_to be_stripe_charges_enabled
      follow_redirect!
      expect(response.body).to include(I18n.t("operators.stripe_connect.return.incomplete"))
    end
  end
end
