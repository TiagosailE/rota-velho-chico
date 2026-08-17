class CheckoutSessionCreator
  # Comissao da plataforma sobre o sinal -- 15% fica na faixa que
  # marketplaces de turismo/hospedagem cobram (Booking/Airbnb ficam por
  # volta de 15-20%). Constante isolada aqui de proposito: ajustar a taxa e
  # mudar um numero, nao tocar o resto do fluxo de checkout.
  COMMISSION_RATE = 0.15

  def initialize(booking:, success_url:, cancel_url:)
    @booking = booking
    @success_url = success_url
    @cancel_url = cancel_url
  end

  # Devolve a URL da sessao de checkout hospedada pelo Stripe. Deixa
  # Stripe::StripeError subir -- falha de rede/API nao e regra de negocio,
  # quem chama decide como tratar. Quem chama tambem garante que o operador
  # ja completou o onboarding do Connect (CheckoutController) -- este
  # servico nao reconfere, e confia no contrato como o BookingCreator confia
  # que os parametros de reserva ja passaram por validacao basica.
  def call
    application_fee = application_fee_cents

    # payment_method_types de proposito omitido, nao travado em ["card"] --
    # sem esse parametro, o Checkout resolve sozinho os metodos habilitados
    # nas configuracoes da conta Stripe (Settings > Payment methods) pra
    # moeda/pais da sessao. Confirmado contra a API de teste de verdade:
    # hoje resolve pra ["card"] porque o Pix ainda nao esta ligado na conta;
    # no dia que for ligado, passa a incluir "pix" sozinho, sem deploy.
    # Fixar a lista aqui (`payment_method_types: ["card", "pix"]`) foi
    # tentado e rejeitado pela API com "ensure the provided type is
    # activated in your dashboard" -- travar um metodo nao habilitado
    # quebraria o checkout inteiro (cartao incluso) ate a ativacao
    # acontecer, o oposto do que se quer aqui.
    session = Stripe::Checkout::Session.create(
      mode: "payment",
      line_items: [ {
        price_data: {
          currency: "brl",
          unit_amount: @booking.deposit_cents,
          product_data: { name: line_item_name }
        },
        quantity: 1
      } ],
      # Destination charge: o sinal entra na conta da plataforma e e
      # transferido pra conta conectada do operador, descontada a comissao.
      # Estorno (BookingCanceller) precisa desfazer os dois lados do split.
      payment_intent_data: {
        application_fee_amount: application_fee,
        transfer_data: { destination: operator.stripe_account_id }
      },
      success_url: @success_url,
      cancel_url: @cancel_url
    )

    # session.payment_intent vem nil aqui -- Stripe so cria o PaymentIntent
    # quando o pagamento e concluido, nao na criacao da sessao (confirmado
    # contra a API de verdade). Por isso o id da sessao, nao o do intent, e
    # o que correlaciona esse Payment ao webhook de confirmacao.
    #
    # Reaproveita o Payment existente (has_one, indice unico em booking_id)
    # em vez de criar outro -- turista pode cancelar no Stripe e tentar de
    # novo, isso so troca a sessao que estamos rastreando.
    payment = @booking.payment || @booking.build_payment
    payment.update!(
      stripe_checkout_session_id: session.id,
      stripe_payment_intent_id: session.payment_intent,
      amount_cents: @booking.deposit_cents,
      application_fee_cents: application_fee,
      status: :pending
    )

    session.url
  end

  private

  def operator
    @booking.departure.tour.operator
  end

  def application_fee_cents
    (@booking.deposit_cents * COMMISSION_RATE).round
  end

  def line_item_name
    I18n.t("checkout.line_item_name", tour: @booking.departure.tour.title)
  end
end
