require "rails_helper"

RSpec.describe ResetDemoPhotosJob do
  describe "#perform" do
    it "apaga as fotos existentes e roda as seeds de novo" do
      tour = create(:tour)
      create(:tour_photo, tour:)
      allow(Rails.application).to receive(:load_seed)

      described_class.new.perform

      expect(TourPhoto.count).to eq(0)
      expect(Rails.application).to have_received(:load_seed)
    end
  end
end
