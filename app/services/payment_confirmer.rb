class PaymentConfirmer
  def initialize(stripe_payment_intent_id:)
    @stripe_payment_intent_id = stripe_payment_intent_id
  end

  # Sem Payment correspondente nao deveria acontecer, mas nao e motivo pra
  # falhar o webhook -- Stripe reenviaria pra sempre. So nao faz nada.
  def call
    payment = Payment.find_by(stripe_payment_intent_id: @stripe_payment_intent_id)
    return unless payment

    ActiveRecord::Base.transaction do
      payment.update!(status: :succeeded, paid_at: Time.current)
      payment.booking.update!(status: :confirmed)
    end
  end
end
