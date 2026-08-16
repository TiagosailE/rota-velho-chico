# Ferramenta temporaria, uso unico: o Render free tier nao da Shell nem
# "one-off jobs" (recursos pagos), entao nao da pra rodar
# `TourPhoto.destroy_all && bin/rails db:seed` direto no servidor depois da
# migracao do Active Storage pro Cloudflare R2. Essa acao faz o mesmo por
# HTTP, atras do login que o painel do operador ja exige. Remover depois de
# usada uma vez -- ver PROGRESS.md.
class Operators::MaintenanceController < Operators::BaseController
  def reset_photos
    TourPhoto.destroy_all
    Rails.application.load_seed

    redirect_to operators_root_path, notice: t("operators.maintenance.reset_photos.success")
  end
end
