class Departure < ApplicationRecord
  belongs_to :tour
  has_many :bookings

  enum :status, scheduled: 0, cancelled: 1, completed: 2

  validates :starts_at, presence: true, uniqueness: { scope: :tour_id }
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :price_override_cents, numericality: { greater_than: 0 }, allow_nil: true

  # seats_taken nao tem validacao de modelo de proposito: a mutacao real
  # acontece via increment! dentro de um lock (BookingCreator), que pula
  # validacoes. A CHECK constraint do banco e a unica linha de defesa contra
  # overbooking -- ver CLAUDE.md, invariante 3.

  def unit_price_cents
    price_override_cents || tour.base_price_cents
  end
end
