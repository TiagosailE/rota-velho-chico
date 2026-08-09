class BookingsController < ApplicationController
  def new
    @departure = active_departure
    @booking = Booking.new(adults: 1, children_5_9: 0, children_0_4: 0)
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
      children_0_4: booking_params[:children_0_4].to_i
    ).call

    if result.success?
      @booking = result.value
      render :confirmation
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

  private

  def active_departure
    Departure.joins(:tour).merge(Tour.where(active: true)).find(params[:departure_id])
  end

  def booking_params
    params.require(:booking).permit(:customer_name, :customer_email, :customer_phone,
                                     :adults, :children_5_9, :children_0_4)
  end
end
