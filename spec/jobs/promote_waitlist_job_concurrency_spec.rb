require "rails_helper"

# Mesmo espirito do teste de 20 threads do BookingCreator
# (docs/architecture.md secao 5): sem o lock na propria entrada da fila
# (WaitlistEntry#with_lock em PromoteWaitlistJob#promote), threads
# concorrentes leriam a mesma entrada como "pending" antes de qualquer
# escrita comitar e promoveriam a mesma pessoa varias vezes -- o
# BookingCreator sozinho nao pega isso, porque cada chamada e uma reserva
# valida por si (ha vaga de sobra pra todas). O lock na entrada, nao na
# saida, e o que garante uma unica promocao por pessoa na fila.
RSpec.describe PromoteWaitlistJob, :concurrency do
  it "10 threads disputando a mesma entrada da fila promovem uma unica vez" do
    departure = create(:departure, capacity: 10, seats_taken: 0)
    create(:waitlist_entry, departure:, customer_email: "ana@exemplo.com", adults: 1)

    run_concurrently(10) do |_index, _connection|
      thread_departure = Departure.find(departure.id)
      described_class.new.perform(thread_departure.id)
    end

    expect(Booking.count).to eq(1)
    expect(Booking.first.customer_email).to eq("ana@exemplo.com")
    expect(WaitlistEntry.promoted.count).to eq(1)
    expect(departure.reload.seats_taken).to eq(1)
  end
end
