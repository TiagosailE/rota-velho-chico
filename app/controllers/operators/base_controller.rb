class Operators::BaseController < ApplicationController
  before_action :authenticate_operator!

  # Le no layout (application.html.erb) pra trocar o header inteiro pelo do
  # painel. So os controllers que realmente herdam daqui (area autenticada)
  # setam isso -- login/recuperacao de senha do operador passam pelo Devise
  # puro (Operators::SessionsController, Devise::PasswordsController), nunca
  # por este before_action, entao continuam com o header publico normal.
  before_action { @operator_panel = true }
end
