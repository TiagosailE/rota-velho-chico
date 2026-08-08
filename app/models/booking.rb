class Booking < ApplicationRecord
  belongs_to :departure
  has_one :payment

  enum :status, pending: 0, confirmed: 1, cancelled: 2, refunded: 3

  validates :code, presence: true, uniqueness: true
  validates :customer_name, presence: true
  validates :customer_email, presence: true
  validates :adults, :children_5_9, :children_0_4,
            numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price_cents, :total_cents, :deposit_cents,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :party_not_empty
  validate :deposit_within_total

  private

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
