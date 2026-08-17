class PromoteWaitlistJob < ApplicationJob
  queue_as :default

  # Um turno por vez, sempre o mais antigo primeiro: se a entrada da frente
  # da fila nao cabe na vaga livre agora, para -- nao pula pra uma entrada
  # menor atras dela. Quem chegou primeiro tem prioridade sobre a vaga
  # disponivel, nao so sobre o tamanho do proprio grupo. Continua enquanto
  # houver vaga e a proxima entrada da fila couber, entao um cancelamento
  # que libera varias vagas pode promover mais de uma entrada.
  def perform(departure_id)
    departure = Departure.find(departure_id)
    return unless departure.scheduled?

    loop do
      entry = departure.waitlist_entries.pending.order(:created_at).first
      break if entry.nil?
      break unless promote(entry)
    end
  end

  private

  def promote(entry)
    booking = nil

    # BookingCreator e o unico caminho que mexe em seats_taken (NOTES.md,
    # invariante 2) -- a promocao passa por ele em vez de criar a Booking
    # aqui, e ganha de graca a mesma checagem de vaga sob lock que ja
    # protege o BookingCreator no fluxo normal. O with_lock aqui e o que
    # impede duas threads de promoverem a mesma entrada duas vezes -- ver
    # spec/jobs/promote_waitlist_job_concurrency_spec.rb.
    entry.with_lock do
      next unless entry.pending?

      result = BookingCreator.new(
        departure: entry.departure,
        customer_name: entry.customer_name,
        customer_email: entry.customer_email,
        customer_phone: entry.customer_phone,
        adults: entry.adults,
        children_5_9: entry.children_5_9,
        children_0_4: entry.children_0_4
      ).call

      next unless result.success?

      entry.update!(status: :promoted, booking: result.value)
      booking = result.value
    end

    return false if booking.nil?

    # Mesma reserva que nasceria pelo formulario publico -- mesmo e-mail,
    # sem mensagem separada so por ter vindo da fila.
    BookingMailer.booking_created(booking).deliver_later
    true
  end
end
