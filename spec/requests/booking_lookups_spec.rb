require "rails_helper"

RSpec.describe "BookingLookups", type: :request do
  describe "GET /booking_lookup/new" do
    it "mostra o formulario" do
      get new_booking_lookup_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /booking_lookup" do
    it "mostra a reserva quando codigo e e-mail batem" do
      booking = create(:booking, code: "ABCDEF", customer_email: "ana@exemplo.com")

      post booking_lookup_path, params: { code: "ABCDEF", email: "ana@exemplo.com" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(booking.code)
    end

    it "aceita e-mail em caixa diferente e codigo em minusculo" do
      booking = create(:booking, code: "ABCDEF", customer_email: "ana@exemplo.com")

      post booking_lookup_path, params: { code: "abcdef", email: "ANA@EXEMPLO.COM" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(booking.code)
    end

    it "recusa com mensagem generica quando o e-mail nao bate" do
      create(:booking, code: "ABCDEF", customer_email: "ana@exemplo.com")

      post booking_lookup_path, params: { code: "ABCDEF", email: "outra@exemplo.com" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("booking_lookups.not_found"))
    end

    it "recusa com a mesma mensagem generica quando o codigo nao existe" do
      post booking_lookup_path, params: { code: "ZZZZZZ", email: "ana@exemplo.com" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("booking_lookups.not_found"))
    end
  end
end
