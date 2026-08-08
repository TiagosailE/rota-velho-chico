require "rails_helper"

RSpec.describe Tour, type: :model do
  subject { create(:tour) }

  it { is_expected.to belong_to(:operator) }
  it { is_expected.to have_many(:departures) }

  it do
    expect(subject).to define_enum_for(:category)
      .with_values(boat: 0, offroad: 1, hiking: 2, cultural: 3)
  end

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }

  it { is_expected.to validate_presence_of(:duration_minutes) }
  it { is_expected.to validate_numericality_of(:duration_minutes).is_greater_than(0) }

  it { is_expected.to validate_presence_of(:base_price_cents) }
  it { is_expected.to validate_numericality_of(:base_price_cents).is_greater_than(0) }

  it { is_expected.to validate_presence_of(:meeting_point) }

  it { is_expected.to validate_numericality_of(:min_age).is_greater_than_or_equal_to(0) }
end
