class BookingCanceller
  def initialize(booking:, cancelled_by_operator: false)
    @booking = booking
    @cancelled_by_operator = cancelled_by_operator
  end

  def call
    return Result.new(false, nil, :already_cancelled) if @booking.cancelled? || @booking.refunded?

    refunded = refund_needed?
    process_refund if refunded # chamada externa antes de qualquer escrita -- se falhar, nada mudou, retry e seguro

    @booking.departure.with_lock do
      @booking.departure.decrement!(:seats_taken, party_size)
      @booking.update!(status: refunded ? :refunded : :cancelled, cancelled_at: Time.current)
    end

    # Fora do lock, depois do commit -- mesmo padrao do DepartureCanceller.
    # So esse caminho libera vaga com a saida continuando agendada (o
    # DepartureCanceller cancela a saida inteira, nao sobra vaga pra
    # promover); e o unico gatilho real da lista de espera.
    PromoteWaitlistJob.perform_later(@booking.departure_id)

    Result.new(true, @booking, nil)
  end

  private

  # So vale a pena estornar se dinheiro de verdade foi cobrado -- reserva
  # nunca paga (payment nil ou ainda pending) nao tem o que devolver, mesmo
  # que a politica de prazo permitisse.
  def refund_needed?
    @booking.payment&.succeeded? && refundable?
  end

  def refundable?
    RefundPolicy.new(
      departure_starts_at: @booking.departure.starts_at,
      cancelled_at: Time.current,
      cancelled_by_operator: @cancelled_by_operator
    ).refundable?
  end

  def process_refund
    refund = Stripe::Refund.create(payment_intent: @booking.payment.stripe_payment_intent_id)
    @booking.payment.update!(
      status: :refunded,
      stripe_refund_id: refund.id,
      refunded_amount_cents: @booking.payment.amount_cents,
      refunded_at: Time.current
    )
  end

  def party_size
    @booking.adults + @booking.children_5_9 + @booking.children_0_4
  end
end
