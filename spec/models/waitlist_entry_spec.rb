require "rails_helper"

RSpec.describe WaitlistEntry, type: :model do
  it { is_expected.to belong_to(:departure) }
  it { is_expected.to belong_to(:booking).optional }
  it { is_expected.to validate_presence_of(:customer_name) }
  it { is_expected.to validate_presence_of(:customer_email) }
  it { is_expected.to validate_numericality_of(:adults).is_greater_than_or_equal_to(0) }

  it "recusa grupo vazio" do
    entry = build(:waitlist_entry, adults: 0, children_5_9: 0, children_0_4: 0)

    expect(entry).not_to be_valid
    expect(entry.errors[:base]).to include(I18n.t("activerecord.errors.models.waitlist_entry.attributes.base.empty_party"))
  end

  it "aceita grupo so de criancas" do
    entry = build(:waitlist_entry, adults: 0, children_5_9: 2, children_0_4: 0)

    expect(entry).to be_valid
  end
end
