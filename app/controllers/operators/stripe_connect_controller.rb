class Operators::StripeConnectController < Operators::BaseController
  def create
    redirect_to_onboarding
  end

  # Account Link expira em poucos minutos -- refresh_url e o que o Stripe
  # chama quando o operador volta com o link vencido em vez de completar o
  # onboarding. Mesma logica do create: gera um link novo pra mesma conta.
  def refresh
    redirect_to_onboarding
  end

  # return_url: operador voltou do onboarding hospedado, completo ou nao
  # (da pra fechar a aba no meio). Consulta o status real na API em vez de
  # assumir sucesso so por ter voltado.
  def return
    account = Stripe::Account.retrieve(current_operator.stripe_account_id)
    current_operator.update!(stripe_charges_enabled: account.charges_enabled)

    if account.charges_enabled
      redirect_to operators_root_path, notice: t("operators.stripe_connect.return.success")
    else
      redirect_to operators_root_path, alert: t("operators.stripe_connect.return.incomplete")
    end
  end

  private

  def redirect_to_onboarding
    ensure_stripe_account!

    account_link = Stripe::AccountLink.create(
      account: current_operator.stripe_account_id,
      refresh_url: operators_stripe_connect_refresh_url,
      return_url: operators_stripe_connect_return_url,
      type: "account_onboarding"
    )

    redirect_to account_link.url, allow_other_host: true
  rescue Stripe::StripeError
    redirect_to operators_root_path, alert: t("operators.stripe_connect.errors.unavailable")
  end

  # Reexecutavel: se o operador ja tem conta mas abandonou o onboarding no
  # meio, so gera um link novo pra mesma conta -- nao cria uma segunda.
  def ensure_stripe_account!
    return if current_operator.stripe_account_id.present?

    account = Stripe::Account.create(
      type: "express",
      country: "BR",
      email: current_operator.email,
      capabilities: { card_payments: { requested: true }, transfers: { requested: true } }
    )
    current_operator.update!(stripe_account_id: account.id)
  end
end
