class CheckoutSessionCreator
  def initialize(booking:, success_url:, cancel_url:)
    @booking = booking
    @success_url = success_url
    @cancel_url = cancel_url
  end

  # Devolve a URL da sessao de checkout hospedada pelo Stripe. Deixa
  # Stripe::StripeError subir -- falha de rede/API nao e regra de negocio,
  # quem chama decide como tratar.
  def call
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
      status: :pending
    )

    session.url
  end

  private

  def line_item_name
    I18n.t("checkout.line_item_name", tour: @booking.departure.tour.title)
  end
end
