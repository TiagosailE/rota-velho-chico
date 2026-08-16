class AttachDemoPhotoJob < ApplicationJob
  queue_as :default

  # Uma foto por execucao: e o que mantem o pico de memoria baixo o
  # suficiente pra instancia gratuita aguentar, e faz uma falha custar so
  # uma foto em vez do lote inteiro.
  #
  # O caminho do arquivo sai do catalogo (DemoPhotos), nunca de concatenacao
  # com o que chegou no argumento: slug e posicao que nao casem com uma
  # entrada conhecida devolvem nil e o job para antes de tocar no disco.
  #
  # Idempotente pela position: reexecutar o reset depois de uma falha
  # parcial nao duplica o que ja subiu.
  def perform(slug, position)
    entry = DemoPhotos.entry(slug, position)
    return if entry.nil?

    tour = Tour.find_by(slug: slug)
    return if tour.nil? || tour.tour_photos.exists?(position: position)

    File.open(entry[:path]) do |image|
      tour.tour_photos.create!(image: image, alt_text: entry[:alt], position: position)
    end
  end
end
