require "rails_helper"

RSpec.describe BookingMailer, type: :mailer do
  describe "#booking_created" do
    it "monta o e-mail com passeio, data, codigo, ponto de encontro e destinatario" do
      departure = create(:departure, starts_at: 10.days.from_now.change(hour: 9))
      booking = create(:booking, departure:, customer_email: "ana@exemplo.com")

      mail = described_class.booking_created(booking)

      expect(mail.to).to eq([ "ana@exemplo.com" ])
      expect(mail.subject).to eq(I18n.t("booking_mailer.booking_created.subject", code: booking.code))
      expect(mail.body.encoded).to include(departure.tour.title)
      expect(mail.body.encoded).to include(booking.code)
      expect(mail.body.encoded).to include(departure.tour.meeting_point)
    end
  end

  describe "#payment_received" do
    it "monta o e-mail com o valor do sinal e o restante a pagar a agencia" do
      booking = create(:booking, customer_email: "ana@exemplo.com", total_cents: 27_000, deposit_cents: 8_100, status: :confirmed)

      mail = described_class.payment_received(booking)

      expect(mail.to).to eq([ "ana@exemplo.com" ])
      expect(mail.subject).to eq(I18n.t("booking_mailer.payment_received.subject", code: booking.code))
      expect(mail.body.encoded).to include(ApplicationController.helpers.format_price_cents(8_100))
      expect(mail.body.encoded).to include(ApplicationController.helpers.format_price_cents(18_900))
    end
  end

  describe "#departure_reminder" do
    it "monta o e-mail quando a reserva esta confirmada e a saida ainda nao aconteceu" do
      departure = create(:departure, starts_at: 2.days.from_now.change(hour: 9))
      booking = create(:booking, departure:, customer_email: "ana@exemplo.com", status: :confirmed)

      mail = described_class.departure_reminder(booking)

      expect(mail.to).to eq([ "ana@exemplo.com" ])
      expect(mail.body.encoded).to include(departure.tour.meeting_point)
    end

    it "nao envia quando a reserva nao esta confirmada" do
      departure = create(:departure, starts_at: 2.days.from_now)
      booking = create(:booking, departure:, status: :pending)

      expect { described_class.departure_reminder(booking).deliver_now }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end

    it "nao envia quando a saida ja aconteceu -- job agendado que atrasou" do
      departure = create(:departure, starts_at: 1.day.ago)
      booking = create(:booking, departure:, status: :confirmed)

      expect { described_class.departure_reminder(booking).deliver_now }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe "#review_request" do
    it "monta o e-mail quando a reserva e avaliavel" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, customer_email: "ana@exemplo.com", status: :confirmed)

      mail = described_class.review_request(booking)

      expect(mail.to).to eq([ "ana@exemplo.com" ])
      expect(mail.body.encoded).to include(departure.tour.title)
    end

    it "nao envia quando a reserva ja foi avaliada" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, status: :confirmed)
      create(:review, booking:)

      expect { described_class.review_request(booking).deliver_now }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end

    it "nao envia quando a saida ainda nao aconteceu" do
      departure = create(:departure, starts_at: 2.days.from_now)
      booking = create(:booking, departure:, status: :confirmed)

      expect { described_class.review_request(booking).deliver_now }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

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
