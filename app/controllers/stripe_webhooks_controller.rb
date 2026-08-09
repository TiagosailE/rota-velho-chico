class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    event = Stripe::Webhook.construct_event(request.body.read, request.headers["Stripe-Signature"], webhook_secret)

    # Tenta inserir o evento; se ja existir, ja foi processado (Stripe
    # reenvia webhooks) -- responde 200 e para, sem reprocessar. A
    # validacao de unicidade do model pega o caso comum (RecordInvalid);
    # o indice unico do banco e o backstop pra corrida rara entre duas
    # entregas concorrentes (RecordNotUnique).
    StripeEvent.create!(stripe_event_id: event.id, event_type: event.type)

    case event.type
    when "payment_intent.succeeded"
      PaymentConfirmer.new(stripe_payment_intent_id: event.data.object.id).call
    end

    head :ok
  rescue Stripe::SignatureVerificationError
    head :bad_request
  rescue ArgumentError
    # Stripe::Webhook::Signature.compute_signature levanta ArgumentError (nao
    # SignatureVerificationError) quando webhook_secret esta ausente -- ou
    # seja, antes das credenciais do Stripe serem configuradas. Mesmo
    # tratamento: nao ha como verificar a assinatura.
    head :bad_request
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    head :ok
  end

  private

  def webhook_secret
    Rails.application.credentials.dig(:stripe, :webhook_secret)
  end
end
