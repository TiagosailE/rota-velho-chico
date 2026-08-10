require "rails_helper"

RSpec.describe "Operators::TourPhotos", type: :request do
  let(:operator) { create(:operator) }
  let(:tour) { create(:tour, operator: operator) }

  def uploaded(fixture = "tour_photo.jpg", type = "image/jpeg")
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/#{fixture}"), type)
  end

  describe "autenticacao" do
    it "redireciona para o login quando nao autenticado" do
      post operators_tour_photos_path(tour), params: { tour_photo: { images: [ uploaded ] } }

      expect(response).to redirect_to(new_operator_session_path)
    end
  end

  describe "escopo do operador" do
    it "devolve 404 ao enviar foto para passeio de outro operador" do
      alheio = create(:tour, operator: create(:operator))
      sign_in operator

      post operators_tour_photos_path(alheio), params: { tour_photo: { images: [ uploaded ] } }

      expect(response).to have_http_status(:not_found)
      expect(alheio.tour_photos).to be_empty
    end

    it "devolve 404 ao reordenar foto de passeio de outro operador" do
      alheio = create(:tour, operator: create(:operator))
      foto_alheia = create(:tour_photo, tour: alheio)
      sign_in operator

      patch move_down_operators_tour_photo_path(alheio, foto_alheia)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /operators/tours/:tour_id/photos" do
    before { sign_in operator }

    it "anexa varias fotos de uma vez, na ordem de envio" do
      post operators_tour_photos_path(tour), params: { tour_photo: { images: [ uploaded, uploaded ] } }

      expect(response).to redirect_to(edit_operators_tour_path(tour))
      expect(tour.tour_photos.pluck(:position)).to eq([ 0, 1 ])
    end

    it "recusa arquivo que nao e imagem sem gravar nada" do
      post operators_tour_photos_path(tour),
           params: { tour_photo: { images: [ uploaded("not_an_image.txt", "text/plain") ] } }

      follow_redirect!
      expect(tour.tour_photos).to be_empty
      expect(response.body).to include("recusado")
    end
  end

  describe "PATCH /operators/tours/:tour_id/photos/:id" do
    before { sign_in operator }

    it "atualiza o texto alternativo" do
      photo = create(:tour_photo, tour: tour)

      patch operators_tour_photo_path(tour, photo), params: { tour_photo: { alt_text: "Canion ao amanhecer" } }

      expect(photo.reload.alt_text).to eq("Canion ao amanhecer")
    end

    # position fora do permit: a ordem so muda pelos botoes, que sabem adiar
    # a constraint de unicidade.
    it "ignora position vinda do formulario" do
      photo = create(:tour_photo, tour: tour)

      patch operators_tour_photo_path(tour, photo), params: { tour_photo: { alt_text: "x", position: 9 } }

      expect(photo.reload.position).to eq(0)
    end
  end

  describe "reordenacao" do
    before { sign_in operator }

    it "promove a segunda foto a capa" do
      primeira = create(:tour_photo, tour: tour)
      segunda = create(:tour_photo, tour: tour)

      patch move_up_operators_tour_photo_path(tour, segunda)

      expect(response).to redirect_to(edit_operators_tour_path(tour))
      expect(tour.reload.cover_photo).to eq(segunda)
      expect(primeira.reload.position).to eq(1)
    end

    it "desce a capa uma posicao" do
      primeira = create(:tour_photo, tour: tour)
      segunda = create(:tour_photo, tour: tour)

      patch move_down_operators_tour_photo_path(tour, primeira)

      expect(tour.reload.cover_photo).to eq(segunda)
    end

    it "nao quebra ao subir a foto que ja e capa" do
      primeira = create(:tour_photo, tour: tour)

      patch move_up_operators_tour_photo_path(tour, primeira)

      expect(response).to redirect_to(edit_operators_tour_path(tour))
      expect(primeira.reload.position).to eq(0)
    end
  end

  describe "DELETE /operators/tours/:tour_id/photos/:id" do
    before { sign_in operator }

    it "remove a foto" do
      photo = create(:tour_photo, tour: tour)

      expect { delete operators_tour_photo_path(tour, photo) }
        .to change { tour.tour_photos.count }.from(1).to(0)
    end
  end
end
