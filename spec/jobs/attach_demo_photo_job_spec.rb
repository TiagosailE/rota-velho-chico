require "rails_helper"

RSpec.describe AttachDemoPhotoJob do
  let(:slug) { "catamara-no-canion" }
  let(:entry) { DemoPhotos.entry(slug, 0) }

  describe "#perform" do
    it "anexa a foto do catalogo na position pedida" do
      tour = create(:tour, slug: slug)

      described_class.new.perform(slug, 0)

      attached = tour.tour_photos.sole
      expect(attached.position).to eq(0)
      expect(attached.alt_text).to eq(entry[:alt])
      expect(attached.image).to be_attached
    end

    it "nao duplica quando a position ja foi preenchida" do
      tour = create(:tour, slug: slug)
      create(:tour_photo, tour:, position: 0)

      expect { described_class.new.perform(slug, 0) }.not_to change(TourPhoto, :count)
    end

    it "ignora slug que nao esta no catalogo, sem tocar no disco" do
      expect { described_class.new.perform("passeio-inventado", 0) }.not_to change(TourPhoto, :count)
    end

    it "ignora posicao que nao existe no catalogo" do
      create(:tour, slug: slug)

      expect { described_class.new.perform(slug, 99) }.not_to change(TourPhoto, :count)
    end

    it "ignora quando o passeio do catalogo nao existe no banco" do
      expect { described_class.new.perform(slug, 0) }.not_to change(TourPhoto, :count)
    end
  end
end
