class PaymentConfirmer
  def initialize(stripe_checkout_session_id:, stripe_payment_intent_id:)
    @stripe_checkout_session_id = stripe_checkout_session_id
    @stripe_payment_intent_id = stripe_payment_intent_id
  end

  # Sem Payment correspondente nao deveria acontecer, mas nao e motivo pra
  # falhar o webhook -- Stripe reenviaria pra sempre. So nao faz nada.
  def call
    payment = Payment.find_by(stripe_checkout_session_id: @stripe_checkout_session_id)
    return unless payment

    ActiveRecord::Base.transaction do
      # payment_intent so existe a partir de agora (era nil na criacao da
      # sessao) -- guardado aqui porque o BookingCanceller precisa dele pra
      # emitir o estorno.
      payment.update!(stripe_payment_intent_id: @stripe_payment_intent_id, status: :succeeded, paid_at: Time.current)
      payment.booking.update!(status: :confirmed)
    end
  end
end
