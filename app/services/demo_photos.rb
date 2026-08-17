# Catalogo das fotos de demonstracao (arquivos versionados em
# db/seeds/photos/, creditos em db/seeds/photos/CREDITS.md).
#
# Vive em app/ e nao dentro de db/seeds.rb porque o job de manutencao
# tambem precisa da mesma lista para reanexar as fotos uma a uma -- ter a
# lista em dois lugares seria a receita para elas divergirem.
#
# A ordem de cada lista vira a ordem de exibicao: a primeira e a capa.
module DemoPhotos
  BY_TOUR_SLUG = {
    "catamara-no-canion" => [
      { file: "01.jpg", alt: "Barco passando entre paredões de rocha no cânion do Rio São Francisco" },
      { file: "02.jpg", alt: "Vista aérea de cânion com cachoeiras e barcos ancorados em água esverdeada" },
      { file: "03.jpg", alt: "Turistas de barco observando os paredões altos do cânion" },
      { file: "04.jpg", alt: "Vista aérea do Rio São Francisco cortando o cânion entre paredões de pedra" },
      { file: "05.jpg", alt: "Cachoeira caindo em piscina natural de pedra, parada para banho" }
    ],
    "por-do-sol-de-lancha" => [
      { file: "01.jpg", alt: "Lancha em silhueta contra o pôr do sol no rio" },
      { file: "02.jpg", alt: "Lancha navegando em águas calmas ao entardecer" },
      { file: "03.jpg", alt: "Represa do Rio São Francisco ao entardecer com vegetação de sertão" },
      { file: "04.jpg", alt: "Paisagem de sertão com lago ao pôr do sol" }
    ],
    "raso-da-catarina-4x4" => [
      { file: "01.jpg", alt: "Mirante de pedra com vegetação seca da caatinga ao fundo" },
      { file: "02.jpg", alt: "Estrada de terra na caatinga com mandacaru e cerca rural" },
      { file: "03.jpg", alt: "Cactos em contraluz ao amanhecer na caatinga baiana" }
    ],
    "complexo-chesf" => [
      { file: "01.jpg", alt: "Barragem de concreto com comportas liberando água" },
      { file: "02.jpg", alt: "Torres de transmissão de energia elétrica em paisagem rural" }
    ],
    "rota-do-cangaco" => [
      { file: "01.jpg", alt: "Casa simples de rua de cidade do interior nordestino" },
      { file: "02.jpg", alt: "Porteira de fazenda antiga em paisagem seca do sertão" }
    ],
    "serra-do-umbuzeiro" => [
      { file: "01.jpg", alt: "Serra rochosa com vegetação rala de campo rupestre" },
      { file: "02.jpg", alt: "Trilha de terra entre vegetação seca de serra" },
      { file: "03.jpg", alt: "Estrada de terra ao entardecer entre árvores do sertão" }
    ]
  }.freeze

  # Caminhos resolvidos aqui, a partir dos literais acima, e nao montados
  # depois com o que o chamador mandar: quem pede uma foto passa slug e
  # posicao, recebe um caminho que so pode ter saido desta lista. Sem isso,
  # um nome de arquivo vindo de fora viraria parte de um File.open.
  ENTRIES = BY_TOUR_SLUG.each_with_object({}) do |(slug, photos), catalog|
    photos.each_with_index do |photo, position|
      catalog[[ slug, position ]] = {
        alt: photo[:alt],
        path: Rails.root.join("db", "seeds", "photos", slug, photo[:file])
      }.freeze
    end
  end.freeze

  def self.entry(slug, position)
    ENTRIES[[ slug, position ]]
  end
end
