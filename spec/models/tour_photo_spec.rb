require "rails_helper"

RSpec.describe TourPhoto, type: :model do
  subject { create(:tour_photo) }

  it { is_expected.to belong_to(:tour) }
  it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }

  it "exige uma imagem anexada" do
    photo = build(:tour_photo, image: nil)

    expect(photo).not_to be_valid
    expect(photo.errors[:image]).to be_present
  end

  it "recusa arquivo que nao e imagem" do
    photo = build(:tour_photo, image: Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/not_an_image.txt"), "text/plain"
    ))

    expect(photo).not_to be_valid
    expect(photo.errors[:image]).to be_present
  end

  describe "position" do
    it "numera a primeira foto de um passeio como 0" do
      photo = create(:tour_photo)

      expect(photo.position).to eq(0)
    end

    it "coloca cada foto nova no fim da fila do passeio" do
      tour = create(:tour)
      create(:tour_photo, tour: tour)
      create(:tour_photo, tour: tour)

      expect(create(:tour_photo, tour: tour).position).to eq(2)
    end

    it "numera de forma independente em passeios diferentes" do
      create(:tour_photo, tour: create(:tour))

      expect(create(:tour_photo, tour: create(:tour)).position).to eq(0)
    end

    it "respeita a position informada explicitamente" do
      expect(create(:tour_photo, position: 7).position).to eq(7)
    end

    it "e invalida sem passeio, em vez de estourar ao calcular a posicao" do
      photo = build(:tour_photo, tour: nil)

      expect(photo).not_to be_valid
      expect(photo.errors[:tour]).to be_present
    end

    it "impede duas fotos na mesma posicao do mesmo passeio" do
      tour = create(:tour)
      create(:tour_photo, tour: tour, position: 0)

      expect { create(:tour_photo, tour: tour, position: 0) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    # A constraint existe porque position e manipulada por troca direta na
    # reordenacao -- um bug de sinal ali viraria posicao negativa silenciosa.
    it "impede position negativa no banco" do
      photo = build(:tour_photo, position: -1)
      photo.save(validate: false)
    rescue ActiveRecord::StatementInvalid => e
      expect(e.message).to include("tour_photos_position_non_negative")
    else
      raise "esperava a CHECK constraint recusar position negativa"
    end
  end

  describe "reordenacao" do
    let(:tour) { create(:tour) }
    let!(:primeira) { create(:tour_photo, tour: tour) }
    let!(:segunda) { create(:tour_photo, tour: tour) }
    let!(:terceira) { create(:tour_photo, tour: tour) }

    it "troca a foto com a anterior ao subir" do
      expect(segunda.move_up!).to be(true)

      expect(segunda.reload.position).to eq(0)
      expect(primeira.reload.position).to eq(1)
    end

    it "troca a foto com a seguinte ao descer" do
      expect(segunda.move_down!).to be(true)

      expect(segunda.reload.position).to eq(2)
      expect(terceira.reload.position).to eq(1)
    end

    it "nao faz nada ao subir a primeira foto" do
      expect(primeira.move_up!).to be(false)
      expect(tour.tour_photos.pluck(:position)).to eq([ 0, 1, 2 ])
    end

    it "nao faz nada ao descer a ultima foto" do
      expect(terceira.move_down!).to be(false)
      expect(tour.tour_photos.pluck(:position)).to eq([ 0, 1, 2 ])
    end

    it "muda a capa do passeio ao promover outra foto" do
      terceira.move_up!
      terceira.move_up!

      expect(tour.reload.cover_photo).to eq(terceira)
    end

    it "nunca deixa duas fotos na mesma posicao" do
      segunda.move_up!
      terceira.move_up!

      positions = tour.tour_photos.pluck(:position)
      expect(positions).to eq(positions.uniq)
    end
  end

  describe "variantes" do
    it "expoe as tres variantes usadas nas views" do
      expect(subject.image.variant(:thumb)).to be_present
      expect(subject.image.variant(:card)).to be_present
      expect(subject.image.variant(:hero)).to be_present
    end
  end
end
