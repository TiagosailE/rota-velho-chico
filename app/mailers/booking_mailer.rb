class BookingMailer < ApplicationMailer
  def departure_cancelled(booking)
    @booking = booking

    mail to: booking.customer_email, subject: t("booking_mailer.departure_cancelled.subject")
  end
end
