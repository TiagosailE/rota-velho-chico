require "rails_helper"

# O teste de overbooking descrito em docs/architecture.md, secao 5.
# Pre-requisitos (transacao desligada, pool de conexoes, limpeza manual) vem
# de spec/support/concurrency.rb -- ver spec/test_harness_spec.rb para o
# guarda-corpo desse arranjo.
RSpec.describe BookingCreator, :concurrency do
  it "20 threads disputando 10 vagas resultam em exatamente 10 reservas" do
    departure = create(:departure, capacity: 10, seats_taken: 0)

    results = run_concurrently(20) do |index, _connection|
      # Cada thread precisa da sua propria instancia -- compartilhar o mesmo
      # objeto ActiveRecord entre threads causaria disputa no objeto Ruby em
      # si (with_lock recarrega self), nao so na linha do banco.
      thread_departure = Departure.find(departure.id)

      BookingCreator.new(
        departure: thread_departure,
        customer_name: "Turista #{index}",
        customer_email: "turista#{index}@exemplo.com",
        customer_phone: "+55 75 99999-0000",
        adults: 1,
        children_5_9: 0,
        children_0_4: 0
      ).call
    end

    successes = results.select(&:success?)
    failures = results.reject(&:success?)

    expect(successes.size).to eq(10)
    expect(failures.size).to eq(10)
    expect(failures.map(&:error).uniq).to eq([ :sold_out ])

    expect(departure.reload.seats_taken).to eq(10)
    expect(departure.bookings.count).to eq(10)
  end
end
