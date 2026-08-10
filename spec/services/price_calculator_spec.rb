require_relative "../../app/services/price_calculator"

# Ruby puro: sem rails_helper de proposito, para o spec rodar em milissegundos
# (NOTES.md, convencoes de teste).
RSpec.describe PriceCalculator do
  def calculator(unit:, adults: 0, children_5_9: 0, children_0_4: 0)
    described_class.new(
      unit_price_cents: unit,
      adults:,
      children_5_9:,
      children_0_4:
    )
  end

  describe "tabela de casos etarios" do
    # 0-4 gratis, 5-9 metade, 10+ integral. Sinal = 30% do total.
    [
      # cenario                         unit    ad  5_9  0_4    total   sinal
      [ "so adultos",                   13_500,  2,   0,   0,  27_000,  8_100 ],
      [ "so criancas de 5 a 9",          9_999,  0,   3,   0,  15_000,  4_500 ],
      [ "so bebes de 0 a 4",            13_500,  0,   0,   3,       0,      0 ],
      [ "grupo vazio",                  13_500,  0,   0,   0,       0,      0 ],
      [ "grupo misto",                  13_500,  2,   1,   2,  33_750, 10_125 ],
      [ "familia grande",                9_900,  4,   2,   1,  49_500, 14_850 ],
      [ "preco impar, adulto e crianca", 13_501,  1,   1,   0,  20_252,  6_076 ],
      [ "preco impar, so crianca",      13_501,  0,   1,   1,   6_751,  2_025 ]
    ].each do |cenario, unit, adults, children_5_9, children_0_4, total, deposit|
      it "#{cenario}: total #{total}, sinal #{deposit}" do
        subject = calculator(unit:, adults:, children_5_9:, children_0_4:)

        expect(subject.total_cents).to eq(total)
        expect(subject.deposit_cents).to eq(deposit)
      end
    end
  end

  describe "arredondamento da meia-entrada" do
    it "arredonda para cima em preco impar em vez de truncar" do
      # 13_501 / 2 = 6_750,5. Divisao inteira daria 6_750 e vazaria um centavo
      # por crianca.
      subject = calculator(unit: 13_501, children_5_9: 1)

      expect(subject.total_cents).to eq(6_751)
    end

    it "arredonda uma vez por crianca, nao no total" do
      subject = calculator(unit: 13_501, children_5_9: 2)

      expect(subject.total_cents).to eq(13_502)
    end
  end

  describe "bebes de 0 a 4" do
    it "nao alteram o total nem o sinal" do
      sem_bebes = calculator(unit: 13_500, adults: 2, children_5_9: 1)
      com_bebes = calculator(unit: 13_500, adults: 2, children_5_9: 1, children_0_4: 4)

      expect(com_bebes.total_cents).to eq(sem_bebes.total_cents)
      expect(com_bebes.deposit_cents).to eq(sem_bebes.deposit_cents)
    end
  end

  describe "sinal" do
    it "e 30% do total" do
      expect(described_class::DEPOSIT_RATE).to eq(0.30)
    end

    it "arredonda para o centavo mais proximo" do
      # 20_252 * 0,30 = 6_075,6
      subject = calculator(unit: 13_501, adults: 1, children_5_9: 1)

      expect(subject.deposit_cents).to eq(6_076)
    end

    it "devolve inteiro, nunca float" do
      subject = calculator(unit: 13_501, adults: 1, children_5_9: 1)

      expect(subject.deposit_cents).to be_an(Integer)
    end
  end
end
