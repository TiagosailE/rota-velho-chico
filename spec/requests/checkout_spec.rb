require "rails_helper"

RSpec.describe "Checkout", type: :request do
  # payment_intent nil por padrao replica o comportamento real: a Checkout
  # Session so ganha PaymentIntent quando o pagamento e concluido.
  def stub_stripe_session(id: "cs_test_123", payment_intent: nil, url: "https://checkout.stripe.com/pay/cs_test_123")
    allow(Stripe::Checkout::Session).to receive(:create)
      .and_return(instance_double(Stripe::Checkout::Session, id:, payment_intent:, url:))
  end

  describe "POST /bookings/:code/pay" do
    it "cria a sessao e redireciona para o Stripe" do
      booking = create(:booking, code: "ABCDEF", status: :pending)
      stub_stripe_session(url: "https://checkout.stripe.com/pay/cs_test_abc")

      post pay_booking_path("ABCDEF")

      expect(response).to redirect_to("https://checkout.stripe.com/pay/cs_test_abc")
      expect(booking.reload.payment).to be_present
    end

    it "permite tentar de novo quando o pagamento anterior ainda esta pendente" do
      booking = create(:booking, code: "ABCDEF", status: :pending)
      create(:payment, booking:, status: :pending, stripe_payment_intent_id: "pi_test_old")
      stub_stripe_session(payment_intent: "pi_test_new")

      post pay_booking_path("ABCDEF")

      expect(response).to have_http_status(:found)
      expect(Payment.where(booking:).count).to eq(1)
    end

    it "recusa quando a reserva ja esta confirmada" do
      booking = create(:booking, code: "ABCDEF", status: :confirmed)

      post pay_booking_path("ABCDEF")

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("checkout.errors.not_payable"))
    end

    it "recusa quando o pagamento ja foi bem-sucedido" do
      booking = create(:booking, code: "ABCDEF", status: :pending)
      create(:payment, booking:, status: :succeeded)

      post pay_booking_path("ABCDEF")

      expect(response).to redirect_to(new_booking_lookup_path)
    end

    it "recusa quando o operador ainda nao conectou a conta Stripe" do
      operator = create(:operator, :stripe_disconnected)
      tour = create(:tour, operator:)
      departure = create(:departure, tour:)
      booking = create(:booking, departure:, code: "ABCDEF", status: :pending)
      allow(Stripe::Checkout::Session).to receive(:create)

      post pay_booking_path("ABCDEF")

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("checkout.errors.operator_not_connected"))
      expect(Stripe::Checkout::Session).not_to have_received(:create)
      expect(booking.reload.payment).to be_nil
    end

    it "mostra mensagem generica quando o Stripe falha" do
      booking = create(:booking, code: "ABCDEF", status: :pending)
      allow(Stripe::Checkout::Session).to receive(:create).and_raise(Stripe::APIConnectionError.new("timeout"))

      post pay_booking_path("ABCDEF")

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("checkout.errors.unavailable"))
      expect(booking.reload.payment).to be_nil
    end

    # Credencial faltando nao e falha passageira: mandar o turista "tentar de
    # novo em instantes" e conselho falso, porque nunca vai funcionar ate
    # alguem configurar a chave.
    it "diferencia credencial ausente de indisponibilidade passageira" do
      booking = create(:booking, code: "ABCDEF", status: :pending)
      allow(Stripe::Checkout::Session).to receive(:create)
        .and_raise(Stripe::AuthenticationError.new("No API key provided"))

      post pay_booking_path("ABCDEF")

      follow_redirect!
      expect(response.body).to include(I18n.t("checkout.errors.not_configured"))
      expect(response.body).not_to include(I18n.t("checkout.errors.unavailable"))
      expect(booking.reload.payment).to be_nil
    end
  end

  describe "GET /checkout/success" do
    it "mostra o codigo da reserva" do
      get checkout_success_path(code: "ABCDEF")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ABCDEF")
    end
  end

  describe "GET /checkout/cancel" do
    it "mostra o codigo da reserva" do
      get checkout_cancel_path(code: "ABCDEF")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ABCDEF")
    end
  end
end
