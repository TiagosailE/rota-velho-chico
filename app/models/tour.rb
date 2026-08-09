class Tour < ApplicationRecord
  belongs_to :operator
  has_many :departures

  enum :category, boat: 0, offroad: 1, hiking: 2, cultural: 3

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :base_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :meeting_point, presence: true
  validates :min_age, numericality: { greater_than_or_equal_to: 0 }

  # Atributo virtual para o formulario do operador aceitar reais em vez de
  # centavos -- base_price_cents continua sendo a fonte da verdade.
  def base_price_reais
    base_price_cents && (base_price_cents / 100.0)
  end

  def base_price_reais=(value)
    self.base_price_cents = value.present? ? (value.to_f * 100).round : nil
  end
end
