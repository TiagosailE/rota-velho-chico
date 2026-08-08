class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      # index: false: o indice composto [departure_id, status] abaixo cobre
      # as buscas por departure_id.
      t.references :departure, null: false, foreign_key: true, index: false

      # Lido por telefone e WhatsApp -- alfabeto sem caracteres ambiguos.
      t.string :code, null: false

      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone

      t.integer :adults, null: false, default: 0
      t.integer :children_5_9, null: false, default: 0
      t.integer :children_0_4, null: false, default: 0

      # Snapshots do momento da reserva. Se o operador reajustar o preco
      # depois, reservas antigas nao mudam. Ver docs/architecture.md, secao 1.4.
      t.integer :unit_price_cents, null: false
      t.integer :total_cents, null: false
      t.integer :deposit_cents, null: false

      # enum: pending: 0, confirmed: 1, cancelled: 2, refunded: 3
      t.integer :status, null: false, default: 0

      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :bookings, :code, unique: true
    add_index :bookings, :customer_email
    add_index :bookings, [ :departure_id, :status ]

    add_check_constraint :bookings,
      "adults >= 0 AND children_5_9 >= 0 AND children_0_4 >= 0",
      name: "bookings_party_counts_non_negative"

    # Reserva sem ninguem nao existe.
    add_check_constraint :bookings,
      "adults + children_5_9 + children_0_4 > 0",
      name: "bookings_party_not_empty"

    add_check_constraint :bookings,
      "unit_price_cents >= 0 AND total_cents >= 0 AND deposit_cents >= 0",
      name: "bookings_money_non_negative"

    # O sinal e uma fracao do total, nunca mais que ele.
    add_check_constraint :bookings, "deposit_cents <= total_cents",
      name: "bookings_deposit_within_total"
  end
end
