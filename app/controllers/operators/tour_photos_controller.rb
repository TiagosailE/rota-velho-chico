class Operators::TourPhotosController < Operators::BaseController
  before_action :set_tour
  before_action :set_photo, only: [ :update, :destroy, :move_up, :move_down ]

  # Aceita varios arquivos de uma vez: o operador acabou de voltar do passeio
  # com o celular cheio de foto, obrigar um upload por vez seria hostil.
  def create
    photos = Array(params[:tour_photo][:images]).reject(&:blank?)
    saved = photos.map { |image| @tour.tour_photos.create(image: image) }
    rejected = saved.count { |photo| !photo.persisted? }

    if rejected.zero?
      redirect_to edit_operators_tour_path(@tour), notice: t("operators.tour_photos.create.success", count: saved.size)
    else
      redirect_to edit_operators_tour_path(@tour), alert: t("operators.tour_photos.create.rejected", count: rejected)
    end
  end

  # update!, e nao um if/else: alt_text e texto livre, sem validacao que
  # possa reprovar. Um ramo de erro aqui seria codigo morto -- se falhar, e
  # porque algo impossivel aconteceu, e ai excecao e a resposta certa.
  def update
    @photo.update!(photo_params)
    redirect_to edit_operators_tour_path(@tour), notice: t("operators.tour_photos.update.success")
  end

  def destroy
    @photo.destroy
    redirect_to edit_operators_tour_path(@tour), notice: t("operators.tour_photos.destroy.success")
  end

  def move_up
    @photo.move_up!
    redirect_to edit_operators_tour_path(@tour)
  end

  def move_down
    @photo.move_down!
    redirect_to edit_operators_tour_path(@tour)
  end

  private

  # Duplo escopo: operador -> tour -> foto. Nunca TourPhoto.find direto.
  def set_tour
    @tour = current_operator.tours.find(params[:tour_id])
  end

  def set_photo
    @photo = @tour.tour_photos.find(params[:id])
  end

  # Sem :position -- ordem muda so por move_up!/move_down!, que sabem adiar a
  # constraint de unicidade. Um campo livre aqui furaria isso.
  def photo_params
    params.require(:tour_photo).permit(:alt_text)
  end
end
