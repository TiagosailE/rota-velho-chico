class RefundBookingJob < ApplicationJob
  queue_as :default

  # Sem rescue do erro do Stripe de proposito -- e isso que torna o job
  # reprocessavel se a chamada falhar (ver DepartureCanceller).
  def perform(booking_id)
    booking = Booking.find(booking_id)
    return unless booking.cancelled?

    if booking.payment&.succeeded?
      refund = Stripe::Refund.create(payment_intent: booking.payment.stripe_payment_intent_id)
      booking.payment.update!(
        status: :refunded,
        stripe_refund_id: refund.id,
        refunded_amount_cents: booking.payment.amount_cents,
        refunded_at: Time.current
      )
      booking.update!(status: :refunded)
    end

    BookingMailer.departure_cancelled(booking).deliver_later
  end
end
