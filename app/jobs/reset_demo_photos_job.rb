class ResetDemoPhotosJob < ApplicationJob
  queue_as :default

  # Trabalho pesado (destroy + reenvio de 19 fotos pro R2) tirado da
  # requisicao web de proposito: rodando sincrono dentro do controller
  # (versao anterior desta ferramenta), a instancia gratuita do Render
  # (512MB RAM, 0.1 CPU) devolveu 500 sem excecao limpa no log -- padrao de
  # timeout/OOM, nao bug de logica (os purge jobs completaram normalmente
  # antes do request morrer). Ver PROGRESS.md.
  def perform
    TourPhoto.destroy_all
    Rails.application.load_seed
  end
end
