# Ferramenta temporaria, uso unico: o Render free tier nao da Shell nem
# "one-off jobs" (recursos pagos), entao nao da pra rodar
# `TourPhoto.destroy_all && bin/rails db:seed` direto no servidor depois da
# migracao do Active Storage pro Cloudflare R2. Essa acao faz o mesmo por
# HTTP, atras do login que o painel do operador ja exige. Remover depois de
# usada uma vez -- ver PROGRESS.md.
#
# So enfileira -- nao roda no proprio request. Rodando sincrono (primeira
# versao desta ferramenta), a instancia gratuita (512MB RAM, 0.1 CPU)
# devolveu 500 tentando reenviar as 19 fotos de uma vez dentro da mesma
# requisicao web. Ver ResetDemoPhotosJob.
class Operators::MaintenanceController < Operators::BaseController
  def reset_photos
    ResetDemoPhotosJob.perform_later

    redirect_to operators_root_path, notice: t("operators.maintenance.reset_photos.success")
  end

  # Mesma justificativa da acao acima (sem Shell no Render free tier), pra
  # corrigir a acentuacao de operadores/passeios/fotos ja publicados. Ver
  # FixDemoAccentsJob. Remover depois de usada -- ver PROGRESS.md.
  def fix_accents
    FixDemoAccentsJob.perform_later

    redirect_to operators_root_path, notice: t("operators.maintenance.fix_accents.success")
  end
end
