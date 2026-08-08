class CreateTours < ActiveRecord::Migration[8.1]
  def change
    create_table :tours do |t|
      t.references :operator, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description

      # enum: boat: 0, offroad: 1, hiking: 2, cultural: 3
      t.integer :category, null: false, default: 0

      t.integer :duration_minutes, null: false
      t.integer :base_price_cents, null: false
      t.string :meeting_point, null: false
      t.integer :min_age, null: false, default: 0
      t.boolean :includes_lunch, null: false, default: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :tours, :slug, unique: true
    add_index :tours, :category

    add_check_constraint :tours, "duration_minutes > 0",
      name: "tours_duration_positive"
    add_check_constraint :tours, "base_price_cents > 0",
      name: "tours_base_price_positive"
    add_check_constraint :tours, "min_age >= 0",
      name: "tours_min_age_non_negative"
  end
end
