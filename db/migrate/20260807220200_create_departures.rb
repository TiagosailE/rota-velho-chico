class CreateDepartures < ActiveRecord::Migration[8.1]
  def change
    create_table :departures do |t|
      # index: false porque o indice composto [tour_id, starts_at] abaixo ja
      # atende as buscas por tour_id (prefixo mais a esquerda).
      t.references :tour, null: false, foreign_key: true, index: false

      t.datetime :starts_at, null: false
      t.integer :capacity, null: false
      t.integer :seats_taken, null: false, default: 0

      # enum: scheduled: 0, cancelled: 1, completed: 2
      t.integer :status, null: false, default: 0

      t.integer :price_override_cents

      t.timestamps
    end

    # Busca publica por data.
    add_index :departures, :starts_at

    # O mesmo passeio nao sai duas vezes no mesmo instante.
    add_index :departures, [ :tour_id, :starts_at ], unique: true

    add_check_constraint :departures, "capacity > 0",
      name: "departures_capacity_positive"

    # A ULTIMA LINHA DE DEFESA contra overbooking. O caminho normal e o lock
    # pessimista no BookingCreator; esta constraint existe para o caso de a
    # aplicacao errar. Nao remova para simplificar nem para fazer teste passar.
    # Ver docs/architecture.md, secao 5 (Concorrencia).
    add_check_constraint :departures, "seats_taken >= 0 AND seats_taken <= capacity",
      name: "departures_seats_within_capacity"

    add_check_constraint :departures, "price_override_cents IS NULL OR price_override_cents > 0",
      name: "departures_price_override_positive"
  end
end
