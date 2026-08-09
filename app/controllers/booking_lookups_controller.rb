class BookingLookupsController < ApplicationController
  def new
  end

  def create
    code = params[:code].to_s.strip.upcase
    email = params[:email].to_s.strip
    booking = Booking.find_by(code:)

    if booking && booking.customer_email.casecmp?(email)
      @booking = booking
      render "bookings/confirmation"
    else
      flash.now[:alert] = t("booking_lookups.not_found")
      render :new, status: :unprocessable_content
    end
  end
end
