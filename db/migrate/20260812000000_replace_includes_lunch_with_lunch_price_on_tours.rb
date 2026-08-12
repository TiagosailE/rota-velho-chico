class ReplaceIncludesLunchWithLunchPriceOnTours < ActiveRecord::Migration[8.1]
  def change
    remove_column :tours, :includes_lunch, :boolean, null: false, default: false

    # Nulo = passeio nao oferece almoco como opcional. Presente = preco por
    # pessoa do add-on. Mesmo padrao de departures.price_override_cents.
    add_column :tours, :lunch_price_cents, :integer

    add_check_constraint :tours, "lunch_price_cents IS NULL OR lunch_price_cents > 0",
      name: "tours_lunch_price_positive"
  end
end
