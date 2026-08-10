class BookingCancellationsController < ApplicationController
  def create
    booking = Booking.find_by!(code: params[:code])

    unless booking.customer_email.casecmp?(params[:email].to_s.strip)
      flash[:alert] = t("booking_lookups.not_found")
      redirect_to(new_booking_lookup_path) and return
    end

    result = BookingCanceller.new(booking:).call

    if result.success?
      flash[:booking_id] = result.value.id
      redirect_to booking_confirmation_path
    else
      flash[:alert] = t("bookings.cancellation.errors.#{result.error}")
      redirect_to new_booking_lookup_path
    end
  rescue Stripe::StripeError
    flash[:alert] = t("checkout.errors.unavailable")
    redirect_to new_booking_lookup_path
  end
end
