class BookingCancellationsController < ApplicationController
  # Mesma varredura da consulta, com consequencia pior: acertar o par aqui
  # cancela a reserva de outra pessoa e dispara estorno. O find_by! ainda
  # responde 404 para codigo inexistente e 302 para codigo valido com e-mail
  # errado, o que sozinho ja distingue os dois casos -- o limite e o que
  # torna essa diferenca inutil na pratica.
  rate_limit to: 10, within: 5.minutes, only: :create,
             with: -> { redirect_to new_booking_lookup_path, alert: t("rate_limit.exceeded") }

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
