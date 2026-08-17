require "rails_helper"

RSpec.describe Operator, type: :model do
  subject { create(:operator) }

  it { is_expected.to have_many(:tours) }
  it { is_expected.to have_many(:departures).through(:tours) }
  it { is_expected.to have_many(:bookings).through(:tours) }

  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }

  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
end
