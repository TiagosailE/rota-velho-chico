class Tour < ApplicationRecord
  belongs_to :operator
  has_many :departures
  has_many :bookings, through: :departures
  has_many :reviews, through: :bookings
  has_many :tour_photos, -> { order(:position) }, dependent: :destroy

  enum :category, boat: 0, offroad: 1, hiking: 2, cultural: 3

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :base_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :meeting_point, presence: true
  validates :min_age, numericality: { greater_than_or_equal_to: 0 }
  validates :lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # A foto de menor position e a capa: e ela que aparece no card do catalogo
  # e no topo da pagina de detalhe. Nil quando o passeio ainda nao tem foto,
  # e a view cai no placeholder.
  def cover_photo
    tour_photos.first
  end

  def coordinates?
    lat.present? && lng.present?
  end

  # Nil (nao 0) quando nao ha avaliacao nenhuma -- a view usa isso pra
  # decidir se mostra o selo de nota ou nada, em vez de mostrar "0.0".
  def average_rating
    reviews.average(:rating)&.round(1)
  end

  # Atributo virtual para o formulario do operador aceitar reais em vez de
  # centavos -- base_price_cents continua sendo a fonte da verdade.
  def base_price_reais
    base_price_cents && (base_price_cents / 100.0)
  end

  def base_price_reais=(value)
    self.base_price_cents = value.present? ? (value.to_f * 100).round : nil
  end
end
