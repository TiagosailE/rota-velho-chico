class AddLunchToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :lunch_count, :integer, null: false, default: 0

    # Snapshot do preco por pessoa no momento da reserva -- mesma logica dos
    # outros snapshots desta tabela (docs/architecture.md, secao 1.4). Se o
    # operador mudar tours.lunch_price_cents depois, reservas antigas nao mudam.
    add_column :bookings, :lunch_unit_price_cents, :integer, null: false, default: 0

    add_check_constraint :bookings, "lunch_count >= 0",
      name: "bookings_lunch_count_non_negative"

    add_check_constraint :bookings, "lunch_unit_price_cents >= 0",
      name: "bookings_lunch_unit_price_non_negative"

    # Nao da pra pedir almoco para mais gente do que a propria reserva tem.
    add_check_constraint :bookings, "lunch_count <= adults + children_5_9 + children_0_4",
      name: "bookings_lunch_count_within_party"
  end
end
