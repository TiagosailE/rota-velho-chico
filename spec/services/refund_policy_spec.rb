# Ruby puro, sem rails_helper (roda em milissegundos). Precisa so da extensao
# pontual do ActiveSupport para 48.hours funcionar fora do boot completo do
# Rails -- nao carrega banco nem app.
require "active_support/core_ext/integer/time"
require_relative "../../app/services/refund_policy"

RSpec.describe RefundPolicy do
  def policy(delta:, cancelled_by_operator: false)
    cancelled_at = Time.now
    described_class.new(
      departure_starts_at: cancelled_at + delta,
      cancelled_at:,
      cancelled_by_operator:
    )
  end

  describe "cancelamento pelo turista" do
    [
      [ "mais de 48h antes", 49.hours, true ],
      [ "menos de 48h antes", 47.hours, false ],
      [ "exatamente 48h antes", 48.hours, false ],
      [ "48h e 1 minuto antes", 48.hours + 1.minute, true ],
      [ "47h59 antes", 47.hours + 59.minutes, false ],
      [ "saida ja passou", -1.hour, false ]
    ].each do |cenario, delta, expected|
      it "#{cenario}: refundable? #{expected}" do
        expect(policy(delta:).refundable?).to eq(expected)
      end
    end
  end

  describe "cancelamento pelo operador" do
    it "sempre estorna, mesmo em cima da hora" do
      expect(policy(delta: 1.minute, cancelled_by_operator: true).refundable?).to be(true)
    end

    it "sempre estorna, mesmo com a saida ja passada" do
      expect(policy(delta: -1.hour, cancelled_by_operator: true).refundable?).to be(true)
    end
  end
end
