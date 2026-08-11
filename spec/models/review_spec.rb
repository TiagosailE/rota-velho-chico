require "rails_helper"

RSpec.describe Review, type: :model do
  subject { create(:review) }

  it { is_expected.to belong_to(:booking) }

  it { is_expected.to validate_presence_of(:rating) }
  it { is_expected.to validate_inclusion_of(:rating).in_range(1..5) }

  it "aceita comentario em branco" do
    review = build(:review, comment: nil)

    expect(review).to be_valid
  end

  it "recusa uma segunda avaliacao para a mesma reserva" do
    booking = create(:booking)
    create(:review, booking:)

    duplicate = build(:review, booking:)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
