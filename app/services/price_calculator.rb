class PriceCalculator
  DEPOSIT_RATE = 0.30

  # Recebe o preco unitario ja resolvido (Departure#unit_price_cents), nao a
  # saida -- e o que mantem esta classe sem ActiveRecord.
  #
  # children_0_4 nao entra em nenhuma conta: bebe vai no colo e nao paga, mas
  # ocupa vaga. Quem conta assento e o BookingCreator; a assimetria e
  # intencional (CLAUDE.md, armadilhas). O argumento fica na assinatura para o
  # chamador descrever a composicao do grupo num lugar so.
  def initialize(unit_price_cents:, adults:, children_5_9:, children_0_4:)
    @unit_price_cents = unit_price_cents
    @adults = adults
    @children_5_9 = children_5_9
    @children_0_4 = children_0_4
  end

  def total_cents
    @adults * @unit_price_cents + @children_5_9 * child_price_cents
  end

  def deposit_cents
    (total_cents * DEPOSIT_RATE).round
  end

  private

  # Arredondamento explicito: com preco impar a divisao inteira truncaria e
  # vazaria centavos.
  def child_price_cents
    (@unit_price_cents / 2.0).round
  end
end
