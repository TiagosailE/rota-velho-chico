class PriceCalculator
  DEPOSIT_RATE = 0.30

  # Recebe o preco unitario ja resolvido (Departure#unit_price_cents), nao a
  # saida -- e o que mantem esta classe sem ActiveRecord. O mesmo vale para o
  # almoco: lunch_price_cents ja vem resolvido (Tour#lunch_price_cents), nao
  # o Tour inteiro.
  #
  # children_0_4 nao entra em nenhuma conta: bebe vai no colo e nao paga, mas
  # ocupa vaga. Quem conta assento e o BookingCreator; a assimetria e
  # intencional (NOTES.md, armadilhas). O argumento fica na assinatura para o
  # chamador descrever a composicao do grupo num lugar so.
  def initialize(unit_price_cents:, adults:, children_5_9:, children_0_4:,
                 lunch_count: 0, lunch_price_cents: 0)
    @unit_price_cents = unit_price_cents
    @adults = adults
    @children_5_9 = children_5_9
    @children_0_4 = children_0_4
    @lunch_count = lunch_count
    @lunch_price_cents = lunch_price_cents || 0
  end

  def total_cents
    @adults * @unit_price_cents + @children_5_9 * child_price_cents + lunch_total_cents
  end

  def deposit_cents
    (total_cents * DEPOSIT_RATE).round
  end

  # Sem desconto por idade: o preco do almoco e por pessoa que vai comer,
  # nao por faixa etaria do ingresso.
  def lunch_total_cents
    @lunch_count * @lunch_price_cents
  end

  private

  # Arredondamento explicito: com preco impar a divisao inteira truncaria e
  # vazaria centavos.
  def child_price_cents
    (@unit_price_cents / 2.0).round
  end
end
