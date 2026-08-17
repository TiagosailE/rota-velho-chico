class CreateWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :waitlist_entries do |t|
      # index: false: o indice composto [departure_id, status] abaixo cobre
      # a busca por fila pendente de uma saida (PromoteWaitlistJob).
      t.references :departure, null: false, foreign_key: true, index: false

      # Setado so na promocao (WaitlistEntry -> Booking). unique: uma
      # entrada de fila promove no maximo uma reserva.
      t.references :booking, foreign_key: true, index: { unique: true }

      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone

      t.integer :adults, null: false, default: 0
      t.integer :children_5_9, null: false, default: 0
      t.integer :children_0_4, null: false, default: 0

      # enum: pending: 0, promoted: 1
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :waitlist_entries, [ :departure_id, :status ]

    add_check_constraint :waitlist_entries,
      "adults >= 0 AND children_5_9 >= 0 AND children_0_4 >= 0",
      name: "waitlist_entries_party_counts_non_negative"

    add_check_constraint :waitlist_entries,
      "adults + children_5_9 + children_0_4 > 0",
      name: "waitlist_entries_party_not_empty"
  end
end
