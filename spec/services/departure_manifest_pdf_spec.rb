require "rails_helper"

RSpec.describe DepartureManifestPdf do
  describe "#render" do
    it "lista reservas pendentes e confirmadas, com codigo, nome e telefone" do
      departure = create(:departure)
      create(:booking, departure:, code: "ABC123", customer_name: "Ana Turista",
                        customer_phone: "+55 75 90000-0000", status: :confirmed)
      create(:booking, departure:, code: "DEF456", customer_name: "Beto Turista",
                        customer_phone: nil, status: :pending)

      text = PDF::Inspector::Text.analyze(described_class.new(departure).render).strings.join(" ")

      expect(text).to include("ABC123")
      expect(text).to include("Ana Turista")
      expect(text).to include("+55 75 90000-0000")
      expect(text).to include("DEF456")
      expect(text).to include("Beto Turista")
    end

    it "nao inclui reserva cancelada ou reembolsada" do
      departure = create(:departure)
      create(:booking, departure:, code: "GHI789", status: :cancelled)
      create(:booking, departure:, code: "JKL012", status: :refunded)

      text = PDF::Inspector::Text.analyze(described_class.new(departure).render).strings.join(" ")

      expect(text).not_to include("GHI789")
      expect(text).not_to include("JKL012")
    end

    it "mostra o nome do passeio, ponto de encontro e total de passageiros" do
      tour = create(:tour, title: "Catamara Teste", meeting_point: "Pier de Teste")
      departure = create(:departure, tour:)
      create(:booking, departure:, adults: 2, children_5_9: 1, children_0_4: 0, status: :confirmed)

      text = PDF::Inspector::Text.analyze(described_class.new(departure).render).strings.join(" ")

      expect(text).to include("Catamara Teste")
      expect(text).to include("Pier de Teste")
      expect(text).to include(I18n.t("operators.departures.manifest.total_passengers", count: 3))
    end

    it "mostra telefone ausente com o marcador de vazio, nao uma celula em branco" do
      departure = create(:departure)
      create(:booking, departure:, customer_phone: nil, status: :confirmed)

      strings = PDF::Inspector::Text.analyze(described_class.new(departure).render).strings

      expect(strings).to include(I18n.t("operators.departures.manifest.phone_missing"))
    end
  end
end
