class ResetDemoPhotosJob < ApplicationJob
  queue_as :default

  # Nao anexa nada aqui: so limpa e enfileira um job por foto. Anexar as 19
  # de uma vez (versao anterior, via load_seed) matava o processo no meio --
  # a instancia gratuita do Render tem 512MB/0.1CPU e roda o Solid Queue
  # dentro do proprio Puma, entao subir todas de uma vez sobrecarregava. O
  # sintoma nao era erro claro: sobravam registros commitados no banco
  # apontando pra arquivos que nunca chegaram no R2, e a pagina quebrava com
  # ActiveStorage::FileNotFoundError na hora de gerar a variante.
  #
  # A position vai explicita (indice na lista) em vez de deixar o model
  # calcular a proxima: com varios jobs rodando em paralelo, dois poderiam
  # ler o mesmo "maximo atual" e colidir no indice unico de
  # (tour_id, position).
  def perform
    TourPhoto.destroy_all

    DemoPhotos::BY_TOUR_SLUG.each do |slug, photos|
      next unless Tour.exists?(slug: slug)

      photos.each_index do |position|
        AttachDemoPhotoJob.perform_later(slug, position)
      end
    end
  end
end
