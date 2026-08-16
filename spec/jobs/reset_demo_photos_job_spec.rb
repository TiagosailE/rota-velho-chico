require "rails_helper"

RSpec.describe ResetDemoPhotosJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "apaga as fotos existentes" do
      tour = create(:tour)
      create(:tour_photo, tour:)

      described_class.new.perform

      expect(TourPhoto.count).to eq(0)
    end

    it "enfileira um job por foto do catalogo, com a position explicita" do
      create(:tour, slug: "catamara-no-canion")
      photos = DemoPhotos::BY_TOUR_SLUG.fetch("catamara-no-canion")

      expect { described_class.new.perform }
        .to have_enqueued_job(AttachDemoPhotoJob).with("catamara-no-canion", 0)
        .and have_enqueued_job(AttachDemoPhotoJob).exactly(photos.size).times
    end

    it "ignora slug do catalogo que nao existe no banco" do
      expect { described_class.new.perform }.not_to have_enqueued_job(AttachDemoPhotoJob)
    end
  end
end
