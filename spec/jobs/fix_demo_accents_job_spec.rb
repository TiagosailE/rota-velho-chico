require "rails_helper"

RSpec.describe FixDemoAccentsJob do
  describe "#perform" do
    it "corrige nome e bio do operador pelo e-mail" do
      operator = create(:operator, email: "contato@catamarapauloafonso.example.com", name: "Catamara", bio: "sem acento")

      described_class.new.perform

      operator.reload
      expect(operator.name).to eq("Catamarã Paulo Afonso Turismo")
      expect(operator.bio).to include("cânion")
    end

    it "corrige titulo e descricao do passeio pelo slug" do
      tour = create(:tour, slug: "rota-do-cangaco", title: "Rota do Cangaco", meeting_point: "Praca da Biblia")

      described_class.new.perform

      tour.reload
      expect(tour.title).to eq("Rota do Cangaço")
      expect(tour.meeting_point).to eq("Praça da Bíblia, Centro de Paulo Afonso")
    end

    it "ignora operador ou passeio que nao existe no banco" do
      expect { described_class.new.perform }.not_to raise_error
    end

    it "corrige o alt_text de foto de demonstracao pela posicao no catalogo" do
      tour = create(:tour, slug: "catamara-no-canion")
      photo = create(:tour_photo, tour:, position: 0, alt_text: "sem acento")

      described_class.new.perform

      expect(photo.reload.alt_text).to eq(DemoPhotos.entry("catamara-no-canion", 0)[:alt])
    end

    it "nao mexe no alt_text de foto fora do catalogo de demonstracao" do
      tour = create(:tour, slug: "sem-fotos-de-demo")
      photo = create(:tour_photo, tour:, position: 0, alt_text: "texto do operador")

      described_class.new.perform

      expect(photo.reload.alt_text).to eq("texto do operador")
    end
  end
end
