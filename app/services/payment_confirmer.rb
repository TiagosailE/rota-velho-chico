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

    # Fora da transacao, mesmo padrao do RefundBookingJob -- chamada de
    # e-mail nao pode segurar o commit. O lembrete e o pedido de avaliacao
    # sao agendados aqui, uma vez so, no momento em que a reserva confirma
    # (nao ha outro ponto do app que transicione pra confirmed); cada
    # mailer reconfere o estado da reserva no proprio momento do envio.
    booking = payment.booking
    BookingMailer.payment_received(booking).deliver_later
    BookingMailer.departure_reminder(booking).deliver_later(wait_until: booking.departure.starts_at - 24.hours)
    BookingMailer.review_request(booking).deliver_later(wait_until: booking.departure.starts_at + 1.day)
  end
end
