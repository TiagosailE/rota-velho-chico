class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      # index: true por padrao do references, mas queremos unique: uma
      # reserva so pode gerar uma avaliacao (has_one no lado de Booking).
      t.references :booking, null: false, foreign_key: true, index: { unique: true }
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end

    add_check_constraint :reviews, "rating BETWEEN 1 AND 5", name: "reviews_rating_range"
  end
end
