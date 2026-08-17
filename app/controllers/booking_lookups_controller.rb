class BookingLookupsController < ApplicationController
  # O par codigo + e-mail e a unica credencial do turista, e o codigo tem 6
  # posicoes. A resposta ja e a mesma para codigo errado e para e-mail errado
  # (nao entrega se um codigo existe), mas sem limite de tentativas ainda da
  # pra varrer combinacoes ate cair na reserva de outra pessoa.
  rate_limit to: 10, within: 5.minutes, only: :create,
             with: -> { redirect_to new_booking_lookup_path, alert: t("rate_limit.exceeded") }

  def new
  end

  def create
    code = params[:code].to_s.strip.upcase
    email = params[:email].to_s.strip
    booking = Booking.find_by(code:)

    if booking && booking.customer_email.casecmp?(email)
      flash[:booking_id] = booking.id
      redirect_to booking_confirmation_path
    else
      flash.now[:alert] = t("booking_lookups.not_found")
      render :new, status: :unprocessable_content
    end
  end
end
