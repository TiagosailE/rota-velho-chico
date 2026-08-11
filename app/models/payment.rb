class Payment < ApplicationRecord
  belongs_to :booking

  enum :status, pending: 0, succeeded: 1, failed: 2, refunded: 3

  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stripe_checkout_session_id, presence: true, uniqueness: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true
  validates :stripe_refund_id, uniqueness: true, allow_nil: true
  validate :refund_within_amount

  private

  def refund_within_amount
    return if refunded_amount_cents.nil?
    return if refunded_amount_cents <= amount_cents

    errors.add(:refunded_amount_cents, :greater_than_amount)
  end
end
