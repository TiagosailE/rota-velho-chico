class CreateStripeEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :stripe_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type, null: false
      t.datetime :processed_at

      t.timestamps
    end

    # O motivo desta tabela existir: o Stripe reenvia webhooks. E o indice
    # unico -- nao um SELECT antes do INSERT -- que garante a idempotencia,
    # porque duas entregas simultaneas passariam pelas duas verificacoes.
    add_index :stripe_events, :stripe_event_id, unique: true
  end
end
