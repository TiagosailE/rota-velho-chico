class Operators::DashboardController < Operators::BaseController
  def show
    @deposits_received_cents = deposits_received_cents
    @confirmed_bookings_count = current_operator.bookings.confirmed.count
    @average_occupancy_percentage = average_occupancy_percentage
    @top_tour = top_tour
    @upcoming_departures = current_operator.departures.scheduled
      .where("starts_at > ?", Time.current)
      .order(:starts_at)
      .limit(5)
  end

  private

  # succeeded = dinheiro ainda retido pela plataforma. O estorno (BookingCanceller/
  # RefundBookingJob) sempre muda o status pra refunded junto de gravar
  # refunded_amount_cents -- os dois nunca ficam dessincronizados no fluxo
  # real do app -- entao filtrar por succeeded ja exclui reserva estornada
  # sem precisar subtrair nada.
  def deposits_received_cents
    Payment.where(booking_id: current_operator.bookings.select(:id), status: :succeeded)
           .sum(:amount_cents)
  end

  # So saidas futuras -- ocupacao de uma saida que ja aconteceu nao ajuda o
  # operador a planejar nada. Poucas dezenas de saidas por operador no
  # maximo, entao somar em Ruby em vez de SQL agregado fica mais simples
  # sem custar nada de verdade.
  def average_occupancy_percentage
    departures = current_operator.departures.scheduled.where("starts_at > ?", Time.current).to_a
    return nil if departures.empty?

    (departures.sum { |departure| departure.seats_taken * 100.0 / departure.capacity } / departures.size).round
  end

  # "Mais vendido" conta reserva confirmada de verdade, nao pending nem
  # cancelada/reembolsada -- inner join via where forca isso sozinho, sem
  # precisar filtrar depois.
  def top_tour
    current_operator.tours
      .joins(:bookings)
      .where(bookings: { status: :confirmed })
      .group("tours.id")
      .order(Arel.sql("COUNT(bookings.id) DESC"))
      .first
  end
end
