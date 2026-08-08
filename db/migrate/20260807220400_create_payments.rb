class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      # has_one: uma reserva tem no maximo um pagamento.
      t.references :booking, null: false, foreign_key: true, index: { unique: true }

      t.string :stripe_payment_intent_id
      t.integer :amount_cents, null: false

      # enum: pending: 0, succeeded: 1, failed: 2, refunded: 3
      t.integer :status, null: false, default: 0

      t.datetime :paid_at

      t.string :stripe_refund_id
      t.integer :refunded_amount_cents
      t.datetime :refunded_at

      t.timestamps
    end

    # Nulos nao colidem em indice unico no Postgres, entao isso impede
    # duplicata de intent/refund sem atrapalhar as linhas ainda sem id.
    add_index :payments, :stripe_payment_intent_id, unique: true
    add_index :payments, :stripe_refund_id, unique: true

    add_check_constraint :payments, "amount_cents >= 0",
      name: "payments_amount_non_negative"

    # Nao se estorna mais do que se cobrou.
    add_check_constraint :payments,
      "refunded_amount_cents IS NULL OR (refunded_amount_cents >= 0 AND refunded_amount_cents <= amount_cents)",
      name: "payments_refund_within_amount"
  end
end
