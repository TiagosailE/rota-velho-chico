class DepartureCanceller
  def initialize(departure:)
    @departure = departure
  end

  # Estorno e e-mail NAO acontecem aqui dentro. Se o Stripe demorar ou
  # cair, o banco nao pode ficar com a transacao aberta -- e um job que
  # falhou pode ser reprocessado, uma transacao abortada no meio de varios
  # estornos nao.
  def call
    return Result.new(false, nil, :already_cancelled) if @departure.cancelled?

    bookings = nil

    ActiveRecord::Base.transaction do
      @departure.update!(status: :cancelled, seats_taken: 0)
      bookings = @departure.bookings.where(status: [ :pending, :confirmed ]).to_a
      bookings.each { |booking| booking.update!(status: :cancelled, cancelled_at: Time.current) }
    end

    bookings.each { |booking| RefundBookingJob.perform_later(booking.id) }

    Result.new(true, bookings.size, nil)
  end
end
