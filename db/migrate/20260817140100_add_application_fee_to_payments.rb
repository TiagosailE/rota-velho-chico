class AddApplicationFeeToPayments < ActiveRecord::Migration[8.1]
  def change
    # Snapshot do momento do checkout, mesmo espirito do unit_price_cents da
    # Booking (docs/architecture.md 1.4) -- se a taxa da plataforma mudar
    # depois, pagamento ja criado nao muda, e o estorno (reverse_transfer +
    # refund_application_fee) precisa saber exatamente quanto devolver.
    add_column :payments, :application_fee_cents, :integer

    add_check_constraint :payments,
      "application_fee_cents IS NULL OR application_fee_cents >= 0",
      name: "payments_application_fee_non_negative"
  end
end
