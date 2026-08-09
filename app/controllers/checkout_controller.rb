class CheckoutController < ApplicationController
  def create
    booking = Booking.find_by!(code: params[:code])

    if booking.confirmed? || booking.payment&.succeeded?
      flash[:alert] = t("checkout.errors.not_payable")
      redirect_to(new_booking_lookup_path) and return
    end

    checkout_url = CheckoutSessionCreator.new(
      booking:,
      success_url: checkout_success_url(code: booking.code),
      cancel_url: checkout_cancel_url(code: booking.code)
    ).call

    redirect_to checkout_url, allow_other_host: true
  rescue Stripe::StripeError
    flash[:alert] = t("checkout.errors.unavailable")
    redirect_to new_booking_lookup_path
  end

  def success
    @code = params[:code]
  end

  def cancel
    @code = params[:code]
  end
end
