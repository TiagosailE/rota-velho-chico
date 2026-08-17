class BookingMailer < ApplicationMailer
  def booking_created(booking)
    @booking = booking

    mail to: booking.customer_email, subject: t("booking_mailer.booking_created.subject", code: booking.code)
  end

  def payment_received(booking)
    @booking = booking

    mail to: booking.customer_email, subject: t("booking_mailer.payment_received.subject", code: booking.code)
  end

  # Agendado no momento da confirmacao do pagamento (PaymentConfirmer), nao
  # disparado na hora -- entre o agendamento e o envio passam ate 24h, tempo
  # de sobra pra reserva ter sido cancelada ou a saida ter sido cancelada
  # pelo operador (DepartureCanceller). Reconfere o estado aqui, no momento
  # do envio, em vez de confiar no que era verdade quando foi agendado.
  def departure_reminder(booking)
    @booking = booking
    return unless booking.confirmed?
    return if booking.departure.starts_at.past?

    mail to: booking.customer_email, subject: t("booking_mailer.departure_reminder.subject", code: booking.code)
  end

  # Mesmo raciocinio do lembrete, agendado com ainda mais antecedencia.
  # booking.reviewable? ja cobre reserva cancelada/reembolsada e reserva ja
  # avaliada -- nao duplica essas checagens aqui.
  def review_request(booking)
    @booking = booking
    return unless booking.reviewable?

    mail to: booking.customer_email, subject: t("booking_mailer.review_request.subject")
  end

  def departure_cancelled(booking)
    @booking = booking

    mail to: booking.customer_email, subject: t("booking_mailer.departure_cancelled.subject")
  end
end
