class AddStripeConnectToOperators < ActiveRecord::Migration[8.1]
  def change
    add_column :operators, :stripe_account_id, :string
    add_column :operators, :stripe_charges_enabled, :boolean, null: false, default: false

    add_index :operators, :stripe_account_id, unique: true
  end
end
