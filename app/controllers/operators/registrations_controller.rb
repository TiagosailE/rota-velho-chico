class Operators::RegistrationsController < Devise::RegistrationsController
  # Manda pro login em vez do padrao (root) -- a conta ainda nao pode
  # autenticar (active: false), entao root deixaria a home publica sem
  # nenhuma explicacao do que aconteceu. Devise ja mostra a mensagem certa
  # sozinho (signed_up_but_pending_approval) porque active_for_authentication?
  # e inactive_message estao sobrescritos no model -- nao precisa repetir
  # logica de aprovacao aqui.
  def after_inactive_sign_up_path_for(_resource)
    new_operator_session_path
  end

  # Autoedicao/exclusao de conta fora de escopo por enquanto -- o painel
  # edita passeios e saidas, nao o proprio cadastro do operador. Nenhum link
  # aponta pra ca, mas as rotas do Devise existem (:registerable), entao
  # ficam neutralizadas em vez de meio-implementadas.
  def edit
    redirect_to operators_root_path
  end

  def update
    redirect_to operators_root_path
  end

  def destroy
    redirect_to operators_root_path
  end

  private

  # build_resource e o ponto certo pra forcar active: false -- roda antes
  # do save, junto da atribuicao dos outros parametros (sign_up_params).
  def build_resource(hash = {})
    super
    resource.active = false
  end

  def sign_up_params
    params.require(:operator).permit(:name, :email, :phone, :whatsapp, :bio, :password, :password_confirmation)
  end
end
