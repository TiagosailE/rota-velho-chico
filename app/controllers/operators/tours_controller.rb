class Operators::ToursController < Operators::BaseController
  before_action :set_tour, only: [ :edit, :update ]

  def index
    @tours = current_operator.tours.order(:title)
  end

  def new
    @tour = current_operator.tours.new
  end

  def create
    @tour = current_operator.tours.new(tour_params)

    if @tour.save
      redirect_to edit_operators_tour_path(@tour), notice: t("operators.tours.create.success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @tour.update(tour_params)
      redirect_to edit_operators_tour_path(@tour), notice: t("operators.tours.update.success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Nunca Tour.find direto -- sempre escopado pelo operador logado.
  def set_tour
    @tour = current_operator.tours.find(params[:id])
    @departures = @tour.departures.order(starts_at: :desc)
  end

  def tour_params
    params.require(:tour).permit(:title, :slug, :description, :category, :duration_minutes,
                                  :base_price_reais, :meeting_point, :min_age, :includes_lunch, :active,
                                  :lat, :lng)
  end
end
