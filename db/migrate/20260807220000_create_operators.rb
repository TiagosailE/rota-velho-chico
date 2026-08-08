class CreateOperators < ActiveRecord::Migration[8.1]
  def change
    create_table :operators do |t|
      t.string :name, null: false
      t.string :slug, null: false

      # Colunas do Devise (database_authenticatable, recoverable, rememberable).
      # A gem entra na semana 3; as colunas ficam prontas desde ja.
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.string :phone
      t.string :whatsapp
      t.text :bio
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :operators, :slug, unique: true
    add_index :operators, :email, unique: true
    add_index :operators, :reset_password_token, unique: true
  end
end
