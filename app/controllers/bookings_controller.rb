class BookingsController < ApplicationController
  # Reserva nasce `pending` e ja ocupa vaga -- pagar e um passo posterior.
  # Um laco contra este endpoint esgota a capacidade de todas as saidas sem
  # gastar um centavo, e as vagas so voltam quando alguem cancela na mao.
  # E o unico limite aqui que protege disponibilidade, nao dado pessoal.
  rate_limit to: 10, within: 10.minutes, only: :create,
             with: -> {
               redirect_to new_departure_booking_path(params[:departure_id]),
                           alert: t("rate_limit.exceeded")
             }

  def new
    @departure = active_departure
    @booking = Booking.new(adults: 1, children_5_9: 0, children_0_4: 0, lunch_count: 0)
    @calculator = calculator_for(@booking)
  end

  # GET, sem escrita nenhuma -- so recalcula o resumo a cada mudanca nos
  # campos de quantidade (Stimulus troca o src do turbo-frame). PriceCalculator
  # continua a unica fonte de verdade do dinheiro: o JS nao calcula nada,
  # so dispara um novo request (NOTES.md, invariante 1).
  def price_summary
    @departure = active_departure
    # O Stimulus controller manda o FormData do formulario inteiro, entao os
    # campos chegam aninhados em booking[...], igual ao POST de create --
    # nao like os campos soltos.
    preview_params = params.fetch(:booking, {})
    @calculator = PriceCalculator.new(
      unit_price_cents: @departure.unit_price_cents,
      adults: preview_params[:adults].to_i,
      children_5_9: preview_params[:children_5_9].to_i,
      children_0_4: preview_params[:children_0_4].to_i,
      lunch_count: preview_params[:lunch_count].to_i,
      lunch_price_cents: @departure.tour.lunch_price_cents
    )
    render partial: "bookings/price_summary", locals: { calculator: @calculator }, layout: false
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
      @calculator = calculator_for(@booking)
      flash.now[:alert] = t("bookings.errors.#{result.error}")
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordInvalid => e
    @booking = e.record
    @calculator = calculator_for(@booking)
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

  def calculator_for(booking)
    PriceCalculator.new(
      unit_price_cents: @departure.unit_price_cents,
      adults: booking.adults.to_i,
      children_5_9: booking.children_5_9.to_i,
      children_0_4: booking.children_0_4.to_i,
      lunch_count: booking.lunch_count.to_i,
      lunch_price_cents: @departure.tour.lunch_price_cents
    )
  end

  def booking_params
    params.require(:booking).permit(:customer_name, :customer_email, :customer_phone,
                                     :adults, :children_5_9, :children_0_4, :lunch_count)
  end
end
