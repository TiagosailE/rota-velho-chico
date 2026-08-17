class Departure < ApplicationRecord
  belongs_to :tour
  has_many :bookings
  has_many :waitlist_entries

  enum :status, scheduled: 0, cancelled: 1, completed: 2

  validates :starts_at, presence: true, uniqueness: { scope: :tour_id }
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :price_override_cents, numericality: { greater_than: 0 }, allow_nil: true
  validate :capacity_not_below_seats_taken

  # seats_taken nao tem validacao de modelo de proposito: a mutacao real
  # acontece via increment! dentro de um lock (BookingCreator), que pula
  # validacoes. A CHECK constraint do banco e a unica linha de defesa contra
  # overbooking -- ver NOTES.md, invariante 3.

  def unit_price_cents
    price_override_cents || tour.base_price_cents
  end

  def full?
    seats_taken >= capacity
  end

  # Atributo virtual para o formulario do operador aceitar reais em vez de
  # centavos -- price_override_cents continua sendo a fonte da verdade.
  def price_override_reais
    price_override_cents && (price_override_cents / 100.0)
  end

  def price_override_reais=(value)
    self.price_override_cents = value.present? ? (value.to_f * 100).round : nil
  end

  private

  # Sem isso, o operador reduzindo a capacidade abaixo das vagas ja
  # ocupadas estoura a CHECK constraint do banco como excecao crua em vez
  # de erro de formulario -- cenario alcancavel pelo painel (Dias 14-15),
  # nao hipotetico.
  def capacity_not_below_seats_taken
    return if capacity.nil? || seats_taken.nil?
    return if capacity >= seats_taken

    errors.add(:capacity, :below_seats_taken)
  end
end
