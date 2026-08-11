class AddStripeCheckoutSessionIdToPayments < ActiveRecord::Migration[8.1]
  def change
    # session.payment_intent vem nil na criacao da Checkout Session -- so e
    # preenchido quando o pagamento e concluido (confirmado testando contra
    # a API de verdade, nao documentacao). Por isso stripe_payment_intent_id
    # nao serve pra correlacionar o webhook de volta ao Payment: o id da
    # sessao e a unica coisa que existe desde a criacao.
    add_column :payments, :stripe_checkout_session_id, :string, null: false

    add_index :payments, :stripe_checkout_session_id, unique: true
  end
end
