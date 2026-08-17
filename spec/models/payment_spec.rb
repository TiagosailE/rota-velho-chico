require "rails_helper"

RSpec.describe Payment, type: :model do
  subject { create(:payment) }

  it { is_expected.to belong_to(:booking) }

  it do
    expect(subject).to define_enum_for(:status)
      .with_values(pending: 0, succeeded: 1, failed: 2, refunded: 3)
  end

  it { is_expected.to validate_presence_of(:amount_cents) }
  it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_numericality_of(:application_fee_cents).is_greater_than_or_equal_to(0).allow_nil }

  it { is_expected.to validate_uniqueness_of(:stripe_payment_intent_id).allow_nil }
  it { is_expected.to validate_uniqueness_of(:stripe_refund_id).allow_nil }

  describe "estorno nao pode passar do valor cobrado" do
    it "e invalido quando o valor estornado e maior que o cobrado" do
      payment = build(:payment, amount_cents: 8_100, refunded_amount_cents: 8_101)

      expect(payment).not_to be_valid
      expect(payment.errors[:refunded_amount_cents]).to be_present
    end

    it "e valido quando o valor estornado e igual ao cobrado" do
      payment = build(:payment, amount_cents: 8_100, refunded_amount_cents: 8_100)

      expect(payment).to be_valid
    end

    it "e valido sem estorno" do
      payment = build(:payment, refunded_amount_cents: nil)

      expect(payment).to be_valid
    end
  end
end
