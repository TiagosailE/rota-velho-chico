class FixDemoAccentsJob < ApplicationJob
  queue_as :default

  # Correcao pontual, uso unico: db/seeds.rb e demo_photos.rb foram escritos
  # sem acentuacao (achado real, nao so estetico -- ver PROGRESS.md). Como
  # find_or_create_by! so seta atributos na criacao, o texto ja publicado no
  # Render precisa ser corrigido nos registros existentes, nao só na fonte.
  # Duplicar essas strings aqui (em vez de importar de db/seeds.rb) e
  # deliberado: essa ferramenta e removida depois do uso unico, nao vale
  # criar um modulo compartilhado so pra isso.
  OPERATOR_FIXES = {
    "contato@catamarapauloafonso.example.com" => {
      name: "Catamarã Paulo Afonso Turismo",
      bio: "Passeios de barco pelo cânion do Rio São Francisco, saindo do " \
           "Pier do Povoado Rio do Sal."
    },
    "contato@rasodacatarina.example.com" => {
      name: "Raso da Catarina Expedições",
      bio: "Expedições 4x4 pelo Raso da Catarina, com foco em observação de " \
           "aves e paisagem do sertão."
    },
    "contato@sertaovivocultural.example.com" => {
      name: "Sertão Vivo Turismo Cultural",
      bio: "Roteiros culturais e históricos em Paulo Afonso: energia, memória " \
           "e o sertão baiano."
    }
  }.freeze

  TOUR_FIXES = {
    "catamara-no-canion" => {
      title: "Catamarã no Cânion",
      description: "Passeio de catamarã pelo cânion do Rio São Francisco, com " \
                    "parede de granito de até 170 metros e parada de 2 horas " \
                    "para banho no Espaço Ecológico Vale do Sal. Almoço em " \
                    "buffet livre disponível como opcional na reserva."
    },
    "por-do-sol-de-lancha" => {
      title: "Pôr do Sol de Lancha no Cânion",
      description: "Passeio curto de lancha pelo trecho navegável mais alto " \
                    "do Rio São Francisco, com o pôr do sol entre os " \
                    "paredões do cânion."
    },
    "raso-da-catarina-4x4" => {
      description: "Expedição 4x4 saindo da Pousada Aconchego do Raso, com " \
                    "revoada da arara-azul-de-lear ao amanhecer, passagem " \
                    "pelo Cânion Seco da Baixa do Chico e pela comunidade " \
                    "indígena Pankararé, além de paredões de arenito e " \
                    "mirantes."
    },
    "complexo-chesf" => {
      title: "Complexo Hidrelétrico da CHESF",
      description: "Visita guiada ao complexo hidrelétrico da CHESF em Paulo " \
                    "Afonso, com explicação sobre a geração de energia no " \
                    "Rio São Francisco."
    },
    "rota-do-cangaco" => {
      title: "Rota do Cangaço",
      description: "Passeio a pé pelo centro de Paulo Afonso com guia local, " \
                    "contando a história do cangaço e a memória de Lampião " \
                    "na região.",
      meeting_point: "Praça da Bíblia, Centro de Paulo Afonso"
    },
    "serra-do-umbuzeiro" => {
      description: "Trilha e esportes de aventura na Serra do Umbuzeiro, com " \
                    "vista panorâmica do sertão baiano."
    }
  }.freeze

  def perform
    OPERATOR_FIXES.each do |email, attrs|
      Operator.find_by(email:)&.update!(attrs)
    end

    TOUR_FIXES.each do |slug, attrs|
      Tour.find_by(slug:)&.update!(attrs)
    end

    fix_photo_alt_texts
  end

  private

  def fix_photo_alt_texts
    TourPhoto.joins(:tour).find_each do |photo|
      entry = DemoPhotos.entry(photo.tour.slug, photo.position)
      photo.update!(alt_text: entry[:alt]) if entry
    end
  end
end
