class WaitlistEntry < ApplicationRecord
  belongs_to :departure
  belongs_to :booking, optional: true

  enum :status, pending: 0, promoted: 1

  validates :customer_name, presence: true
  validates :customer_email, presence: true
  validates :adults, :children_5_9, :children_0_4,
            numericality: { greater_than_or_equal_to: 0 }
  validate :party_not_empty

  private

  def party_not_empty
    return if [ adults, children_5_9, children_0_4 ].compact.sum.positive?

    errors.add(:base, :empty_party)
  end
end
