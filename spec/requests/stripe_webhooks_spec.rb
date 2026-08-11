require "rails_helper"

# A verificacao de assinatura e testada de verdade, nao stubada: e uma
# computacao HMAC local (Stripe::Webhook.construct_event nao toca rede), e o
# proprio gem stripe expoe Signature.compute_signature/generate_header para
# montar isso em teste -- prova que uma assinatura invalida e recusada sem
# precisar de chave real.
RSpec.describe "StripeWebhooks", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
  end

  def event_payload(type:, object_id:, payment_intent: nil, event_id: "evt_#{SecureRandom.hex(8)}")
    { id: event_id, type:, data: { object: { id: object_id, payment_intent: } } }.to_json
  end

  def post_webhook(payload, secret: webhook_secret)
    timestamp = Time.current
    computed = Stripe::Webhook::Signature.compute_signature(timestamp, payload, secret)
    signature = Stripe::Webhook::Signature.generate_header(timestamp, computed)

    post stripe_webhook_path, params: payload, headers: { "Stripe-Signature" => signature, "CONTENT_TYPE" => "application/json" }
  end

  it "confirma o pagamento e a reserva quando checkout.session.completed chega com assinatura valida" do
    booking = create(:booking, status: :pending)
    create(:payment, booking:, stripe_checkout_session_id: "cs_test_123", status: :pending)

    post_webhook(event_payload(type: "checkout.session.completed", object_id: "cs_test_123", payment_intent: "pi_test_123"))

    expect(response).to have_http_status(:ok)
    expect(booking.reload).to be_confirmed
  end

  it "recusa com 400 quando a assinatura nao bate" do
    booking = create(:booking, status: :pending)
    create(:payment, booking:, stripe_checkout_session_id: "cs_test_123", status: :pending)

    post_webhook(event_payload(type: "checkout.session.completed", object_id: "cs_test_123"), secret: "whsec_outro_segredo")

    expect(response).to have_http_status(:bad_request)
    expect(booking.reload).to be_pending
  end

  it "responde 200 sem reprocessar quando o mesmo evento chega duas vezes" do
    booking = create(:booking, status: :pending)
    create(:payment, booking:, stripe_checkout_session_id: "cs_test_123", status: :pending)
    payload = event_payload(type: "checkout.session.completed", object_id: "cs_test_123",
                             payment_intent: "pi_test_123", event_id: "evt_fixo")

    post_webhook(payload)
    booking.update!(status: :cancelled) # se reprocessar, o confirm sobrescreveria isso de novo

    post_webhook(payload)

    expect(response).to have_http_status(:ok)
    expect(booking.reload).to be_cancelled
  end

  it "responde 200 sem quebrar para um tipo de evento nao tratado" do
    post_webhook(event_payload(type: "charge.refunded", object_id: "ch_test_123"))

    expect(response).to have_http_status(:ok)
  end

  it "responde 200 mesmo sem Payment correspondente ao id da sessao" do
    post_webhook(event_payload(type: "checkout.session.completed", object_id: "cs_test_inexistente"))

    expect(response).to have_http_status(:ok)
  end

  it "recusa com 400 em vez de 500 quando o webhook_secret ainda nao esta configurado" do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(nil)

    post_webhook(event_payload(type: "checkout.session.completed", object_id: "cs_test_123"))

    expect(response).to have_http_status(:bad_request)
  end
end
