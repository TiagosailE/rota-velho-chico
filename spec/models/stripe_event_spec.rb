require "rails_helper"

RSpec.describe StripeEvent, type: :model do
  subject { create(:stripe_event) }

  it { is_expected.to validate_presence_of(:stripe_event_id) }
  it { is_expected.to validate_uniqueness_of(:stripe_event_id) }
  it { is_expected.to validate_presence_of(:event_type) }
end
