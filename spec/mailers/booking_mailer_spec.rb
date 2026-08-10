require "rails_helper"

RSpec.describe BookingMailer, type: :mailer do
  describe "#departure_cancelled" do
    it "monta o e-mail com passeio, data, codigo e destinatario" do
      departure = create(:departure, starts_at: 10.days.from_now.change(hour: 9))
      booking = create(:booking, departure:, customer_email: "ana@exemplo.com", status: :cancelled)

      mail = described_class.departure_cancelled(booking)

      expect(mail.to).to eq([ "ana@exemplo.com" ])
      expect(mail.subject).to eq(I18n.t("booking_mailer.departure_cancelled.subject"))
      expect(mail.body.encoded).to include(departure.tour.title)
      expect(mail.body.encoded).to include(booking.code)
    end

    it "menciona o estorno so quando a reserva foi de fato estornada" do
      booking = create(:booking, status: :refunded)

      mail = described_class.departure_cancelled(booking)

      expect(mail.body.encoded).to include(I18n.t("booking_mailer.departure_cancelled.refunded"))
    end

    it "nao menciona estorno quando a reserva so foi cancelada" do
      booking = create(:booking, status: :cancelled)

      mail = described_class.departure_cancelled(booking)

      expect(mail.body.encoded).not_to include(I18n.t("booking_mailer.departure_cancelled.refunded"))
    end
  end
end
