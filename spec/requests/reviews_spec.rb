require "rails_helper"

RSpec.describe "Reviews", type: :request do
  describe "POST /bookings/:code/review" do
    it "cria a avaliacao e mostra agradecimento quando elegivel" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :confirmed)

      post review_booking_path("ABCDEF"), params: { email: "ana@exemplo.com", review: { rating: 4, comment: "Muito bom" } }

      expect(response).to redirect_to(booking_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("reviews.thanks"))
      expect(booking.reload.review).to have_attributes(rating: 4, comment: "Muito bom")
    end

    it "recusa com mensagem generica quando o e-mail nao bate, sem criar avaliacao" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :confirmed)

      post review_booking_path("ABCDEF"), params: { email: "outra@exemplo.com", review: { rating: 5 } }

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("booking_lookups.not_found"))
      expect(booking.reload.review).to be_nil
    end

    it "recusa quando a reserva ainda esta pendente" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :pending)

      post review_booking_path("ABCDEF"), params: { email: "ana@exemplo.com", review: { rating: 5 } }

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("reviews.errors.not_reviewable"))
      expect(booking.reload.review).to be_nil
    end

    it "recusa quando a saida ainda nao aconteceu" do
      departure = create(:departure, starts_at: 2.days.from_now)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :confirmed)

      post review_booking_path("ABCDEF"), params: { email: "ana@exemplo.com", review: { rating: 5 } }

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("reviews.errors.not_reviewable"))
    end

    it "recusa uma segunda avaliacao para a mesma reserva" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :confirmed)
      create(:review, booking:)

      post review_booking_path("ABCDEF"), params: { email: "ana@exemplo.com", review: { rating: 5 } }

      expect(response).to redirect_to(new_booking_lookup_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("reviews.errors.not_reviewable"))
    end

    it "recusa nota fora do intervalo permitido" do
      departure = create(:departure, starts_at: 2.days.ago)
      booking = create(:booking, departure:, code: "ABCDEF", customer_email: "ana@exemplo.com", status: :confirmed)

      post review_booking_path("ABCDEF"), params: { email: "ana@exemplo.com", review: { rating: 9 } }

      expect(response).to redirect_to(new_booking_lookup_path)
      expect(booking.reload.review).to be_nil
    end
  end
end
