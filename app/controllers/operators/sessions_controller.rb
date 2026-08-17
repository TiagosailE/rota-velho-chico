# Existe unicamente para limitar tentativas de login. Nenhum comportamento do
# Devise e sobrescrito -- new/create/destroy continuam os do gem.
class Operators::SessionsController < Devise::SessionsController
  # Devise nao tem bloqueio de conta ligado (o modulo :lockable ficou de fora
  # em architecture.md), entao sem isto nada impede varrer senhas comuns
  # contra as contas de operador. 10 tentativas em 3 minutos nao atrapalha
  # quem so errou a senha.
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_operator_session_path, alert: t("rate_limit.exceeded") }
end
