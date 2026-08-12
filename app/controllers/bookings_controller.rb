class BookingsController < ApplicationController
  def new
    @departure = active_departure
    @booking = Booking.new(adults: 1, children_5_9: 0, children_0_4: 0, lunch_count: 0)
  end

  def create
    @departure = active_departure

    result = BookingCreator.new(
      departure: @departure,
      customer_name: booking_params[:customer_name],
      customer_email: booking_params[:customer_email],
      customer_phone: booking_params[:customer_phone],
      adults: booking_params[:adults].to_i,
      children_5_9: booking_params[:children_5_9].to_i,
      children_0_4: booking_params[:children_0_4].to_i,
      lunch_count: booking_params[:lunch_count].to_i
    ).call

    if result.success?
      flash[:booking_id] = result.value.id
      redirect_to booking_confirmation_path
    else
      @booking = Booking.new(booking_params)
      flash.now[:alert] = t("bookings.errors.#{result.error}")
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordInvalid => e
    @booking = e.record
    flash.now[:alert] = @booking.errors.full_messages.to_sentence
    render :new, status: :unprocessable_content
  end

  # GET separado do POST que cria/consulta/cancela a reserva -- Turbo exige
  # redirect numa resposta de sucesso pra formulario fora de frame (senao
  # lanca "Form responses must redirect to another location" e a pagina
  # trava sem navegar, so descoberto testando de verdade no navegador). O
  # id vem da flash, nunca da URL/params -- codigo publico na URL furaria a
  # regra de "consulta so com codigo + e-mail" do architecture.md 3.1.
  def confirmation
    @booking = Booking.find_by(id: flash[:booking_id])
    redirect_to root_path if @booking.nil?
  end

  private

  def active_departure
    Departure.joins(:tour).merge(Tour.where(active: true)).find(params[:departure_id])
  end

  def booking_params
    params.require(:booking).permit(:customer_name, :customer_email, :customer_phone,
                                     :adults, :children_5_9, :children_0_4, :lunch_count)
  end
end
