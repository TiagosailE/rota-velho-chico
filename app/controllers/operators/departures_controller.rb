class Operators::DeparturesController < Operators::BaseController
  before_action :set_tour
  before_action :set_departure, only: [ :show, :edit, :update ]

  def new
    @departure = @tour.departures.new
  end

  def create
    @departure = @tour.departures.new(departure_params)

    if @departure.save
      redirect_to operators_tour_departure_path(@tour, @departure), notice: t("operators.departures.create.success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @bookings = @departure.bookings.order(:created_at)
    @occupancy_percentage = (@departure.seats_taken * 100.0 / @departure.capacity).round
  end

  def edit
  end

  def update
    if @departure.update(departure_params)
      redirect_to operators_tour_departure_path(@tour, @departure), notice: t("operators.departures.update.success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Duplo escopo: operador -> tour -> saida. Nunca Departure.find direto.
  def set_tour
    @tour = current_operator.tours.find(params[:tour_id])
  end

  def set_departure
    @departure = @tour.departures.find(params[:id])
  end

  # Sem :status nem :seats_taken -- status muda so via BookingCreator/
  # BookingCanceller/DepartureCanceller (Dia 16), seats_taken so dentro de
  # lock. Expor os dois aqui abriria caminho pra inconsistencia.
  def departure_params
    params.require(:departure).permit(:starts_at, :capacity, :price_override_reais)
  end
end
