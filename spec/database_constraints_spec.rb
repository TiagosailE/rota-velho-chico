# frozen_string_literal: true

require "rails_helper"

# As constraints do banco sao a ultima linha de defesa (docs/architecture.md, secao 5).
# Elas so valem alguma coisa se o banco de fato recusar o dado ruim, entao aqui
# os INSERT sao feitos em SQL cru, sem passar por model nem validacao -- que e
# exatamente o cenario que elas existem para cobrir: a aplicacao errou.
#
# DDL sem teste e so DDL esperancosa.
RSpec.describe "Constraints do banco" do
  let(:connection) { ActiveRecord::Base.connection }

  def unique = SecureRandom.alphanumeric(12).downcase

  def create_operator
    connection.select_value(<<~SQL.squish)
      INSERT INTO operators (name, slug, email, encrypted_password, active, created_at, updated_at)
      VALUES ('Agencia Teste', '#{unique}', '#{unique}@exemplo.com', 'x', true, now(), now())
      RETURNING id
    SQL
  end

  def create_tour(operator_id, base_price_cents: 13_500, duration_minutes: 240)
    connection.select_value(<<~SQL.squish)
      INSERT INTO tours (operator_id, title, slug, category, duration_minutes,
                         base_price_cents, meeting_point, min_age, includes_lunch,
                         active, created_at, updated_at)
      VALUES (#{operator_id}, 'Catamara no Canion', '#{unique}', 0, #{duration_minutes},
              #{base_price_cents}, 'Pier do Rio do Sal', 0, false, true, now(), now())
      RETURNING id
    SQL
  end

  def create_departure(tour_id, capacity: 10, seats_taken: 0, starts_at: "now() + interval '10 days'")
    connection.select_value(<<~SQL.squish)
      INSERT INTO departures (tour_id, starts_at, capacity, seats_taken, status, created_at, updated_at)
      VALUES (#{tour_id}, #{starts_at}, #{capacity}, #{seats_taken}, 0, now(), now())
      RETURNING id
    SQL
  end

  def create_booking(departure_id, adults: 2, children_5_9: 0, children_0_4: 0,
                     unit_price_cents: 13_500, total_cents: 27_000, deposit_cents: 8_100)
    connection.select_value(<<~SQL.squish)
      INSERT INTO bookings (departure_id, code, customer_name, customer_email,
                            adults, children_5_9, children_0_4,
                            unit_price_cents, total_cents, deposit_cents,
                            status, created_at, updated_at)
      VALUES (#{departure_id}, '#{unique}', 'Turista', 'turista@exemplo.com',
              #{adults}, #{children_5_9}, #{children_0_4},
              #{unit_price_cents}, #{total_cents}, #{deposit_cents},
              0, now(), now())
      RETURNING id
    SQL
  end

  let(:operator_id) { create_operator }
  let(:tour_id)     { create_tour(operator_id) }

  describe "departures" do
    it "aceita ocupacao dentro da capacidade" do
      expect { create_departure(tour_id, capacity: 10, seats_taken: 10) }.not_to raise_error
    end

    # A constraint mais importante do projeto.
    it "recusa seats_taken acima da capacidade" do
      expect { create_departure(tour_id, capacity: 10, seats_taken: 11) }
        .to raise_error(ActiveRecord::StatementInvalid, /departures_seats_within_capacity/)
    end

    it "recusa seats_taken negativo" do
      expect { create_departure(tour_id, capacity: 10, seats_taken: -1) }
        .to raise_error(ActiveRecord::StatementInvalid, /departures_seats_within_capacity/)
    end

    it "recusa capacidade zero ou negativa" do
      expect { create_departure(tour_id, capacity: 0) }
        .to raise_error(ActiveRecord::StatementInvalid, /departures_capacity_positive/)
    end

    it "recusa duas saidas do mesmo passeio no mesmo instante" do
      create_departure(tour_id, starts_at: "'2026-12-25 08:00:00'")

      expect { create_departure(tour_id, starts_at: "'2026-12-25 08:00:00'") }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "bookings" do
    let(:departure_id) { create_departure(tour_id, capacity: 20) }

    it "recusa reserva sem nenhum passageiro" do
      expect { create_booking(departure_id, adults: 0, children_5_9: 0, children_0_4: 0) }
        .to raise_error(ActiveRecord::StatementInvalid, /bookings_party_not_empty/)
    end

    it "recusa contagem negativa de passageiros" do
      expect { create_booking(departure_id, adults: -1, children_5_9: 2) }
        .to raise_error(ActiveRecord::StatementInvalid, /bookings_party_counts_non_negative/)
    end

    it "recusa sinal maior que o total" do
      expect { create_booking(departure_id, total_cents: 10_000, deposit_cents: 10_001) }
        .to raise_error(ActiveRecord::StatementInvalid, /bookings_deposit_within_total/)
    end

    it "recusa codigo repetido" do
      code = unique
      connection.execute(<<~SQL.squish)
        INSERT INTO bookings (departure_id, code, customer_name, customer_email,
                              adults, children_5_9, children_0_4,
                              unit_price_cents, total_cents, deposit_cents,
                              status, created_at, updated_at)
        VALUES (#{departure_id}, '#{code}', 'A', 'a@exemplo.com', 1, 0, 0,
                13500, 13500, 4050, 0, now(), now())
      SQL

      expect {
        connection.execute(<<~SQL.squish)
          INSERT INTO bookings (departure_id, code, customer_name, customer_email,
                                adults, children_5_9, children_0_4,
                                unit_price_cents, total_cents, deposit_cents,
                                status, created_at, updated_at)
          VALUES (#{departure_id}, '#{code}', 'B', 'b@exemplo.com', 1, 0, 0,
                  13500, 13500, 4050, 0, now(), now())
        SQL
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "payments" do
    let(:departure_id) { create_departure(tour_id, capacity: 20) }
    let(:booking_id)   { create_booking(departure_id) }

    it "recusa estorno maior que o valor cobrado" do
      expect {
        connection.execute(<<~SQL.squish)
          INSERT INTO payments (booking_id, amount_cents, status, refunded_amount_cents,
                                created_at, updated_at)
          VALUES (#{booking_id}, 8100, 3, 8101, now(), now())
        SQL
      }.to raise_error(ActiveRecord::StatementInvalid, /payments_refund_within_amount/)
    end

    it "recusa dois pagamentos para a mesma reserva" do
      connection.execute(<<~SQL.squish)
        INSERT INTO payments (booking_id, amount_cents, status, created_at, updated_at)
        VALUES (#{booking_id}, 8100, 0, now(), now())
      SQL

      expect {
        connection.execute(<<~SQL.squish)
          INSERT INTO payments (booking_id, amount_cents, status, created_at, updated_at)
          VALUES (#{booking_id}, 8100, 0, now(), now())
        SQL
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "stripe_events" do
    # E este indice -- nao um SELECT antes do INSERT -- que garante idempotencia:
    # duas entregas simultaneas do mesmo webhook passariam pelas duas leituras.
    it "recusa o mesmo evento do Stripe duas vezes" do
      event_id = "evt_#{unique}"

      connection.execute(<<~SQL.squish)
        INSERT INTO stripe_events (stripe_event_id, event_type, created_at, updated_at)
        VALUES ('#{event_id}', 'payment_intent.succeeded', now(), now())
      SQL

      expect {
        connection.execute(<<~SQL.squish)
          INSERT INTO stripe_events (stripe_event_id, event_type, created_at, updated_at)
          VALUES ('#{event_id}', 'payment_intent.succeeded', now(), now())
        SQL
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
