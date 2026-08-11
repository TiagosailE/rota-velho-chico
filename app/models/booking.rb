class Booking < ApplicationRecord
  # Sem 0/O, 1/I/L -- o codigo e lido por telefone e WhatsApp (NOTES.md).
  CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789".chars.freeze
  CODE_LENGTH = 6

  belongs_to :departure
  has_one :payment
  has_one :review

  enum :status, pending: 0, confirmed: 1, cancelled: 2, refunded: 3

  before_validation :generate_code, on: :create

  validates :code, presence: true, uniqueness: true
  validates :customer_name, presence: true
  validates :customer_email, presence: true
  validates :adults, :children_5_9, :children_0_4,
            numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price_cents, :total_cents, :deposit_cents,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :party_not_empty
  validate :deposit_within_total

  # So avalia quem realmente foi: reserva confirmada, saida ja aconteceu,
  # e ainda sem avaliacao (has_one :review + indice unico impedem duas,
  # mas checar aqui evita cair no erro de unicidade pra dar a mensagem
  # certa). Nao usa departure.completed? porque nada no app transiciona
  # esse enum automaticamente hoje -- ver NOTES.md/architecture.md, so
  # existe o valor. Comparar com starts_at no passado (Time.current,
  # invariante 5 do NOTES.md) e o que realmente reflete "o passeio ja
  # aconteceu".
  def reviewable?
    confirmed? && departure.starts_at.past? && review.nil?
  end

  private

  def generate_code
    return if code.present?

    loop do
      candidate = Array.new(CODE_LENGTH) { CODE_ALPHABET.sample }.join
      next if Booking.exists?(code: candidate)

      self.code = candidate
      break
    end
  end

  def party_not_empty
    return if [ adults, children_5_9, children_0_4 ].compact.sum.positive?

    errors.add(:base, :empty_party)
  end

  def deposit_within_total
    return if deposit_cents.nil? || total_cents.nil?
    return if deposit_cents <= total_cents

    errors.add(:deposit_cents, :greater_than_total)
  end
end
