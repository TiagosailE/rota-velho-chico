class WaitlistEntriesController < ApplicationController
  # Mesmo limite do formulario de reserva -- protege a fila de spam, nao
  # dado pessoal (NOTES.md ja documenta o mesmo raciocinio em bookings#create).
  rate_limit to: 10, within: 10.minutes, only: :create,
             with: -> {
               redirect_to new_departure_booking_path(params[:departure_id]),
                           alert: t("rate_limit.exceeded")
             }

  def new
    @departure = active_departure
    redirect_to new_departure_booking_path(@departure) and return unless @departure.full?

    @waitlist_entry = WaitlistEntry.new(adults: 1, children_5_9: 0, children_0_4: 0)
  end

  def create
    @departure = active_departure
    redirect_to new_departure_booking_path(@departure) and return unless @departure.full?

    @waitlist_entry = @departure.waitlist_entries.new(waitlist_entry_params)

    if @waitlist_entry.save
      redirect_to tour_path(@departure.tour.slug), notice: t("waitlist_entries.create.success")
    else
      flash.now[:alert] = @waitlist_entry.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end
  end

  private

  def active_departure
    Departure.joins(:tour).merge(Tour.where(active: true)).find(params[:departure_id])
  end

  def waitlist_entry_params
    params.require(:waitlist_entry).permit(:customer_name, :customer_email, :customer_phone,
                                            :adults, :children_5_9, :children_0_4)
  end
end
