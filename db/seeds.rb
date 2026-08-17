# Dados de demonstracao baseados em pesquisa publica sobre operadores de
# turismo em Paulo Afonso (BA). Nomes de agencia, precos e horarios sao
# fabricados para o MVP -- nao ha afiliacao com nenhum operador real (ver
# aviso no README). Idempotente: pode rodar mais de uma vez sem duplicar.

DEPARTURE_OFFSETS_IN_DAYS = (1..10).map { |i| i * 9 } # 10 saidas por passeio, ate 90 dias a frente

# A senha dos operadores de demonstracao NAO pode viver neste arquivo: ele e
# versionado num repositorio publico, e as mesmas seeds rodam no ambiente
# publicado -- uma senha literal aqui e uma credencial valida entregue a
# qualquer pessoa que abra o repo, com acesso ao painel que edita preco,
# cancela saida e dispara estorno de verdade no Stripe.
#
# Em desenvolvimento/teste a senha fixa continua (banco local, sem valor pra
# ninguem, e os specs dependem dela). Fora disso ela e obrigatoria via
# ambiente, e a ausencia interrompe o seed em vez de cair num padrao
# adivinhavel -- falha fechada, nao aberta.
SEED_OPERATOR_PASSWORD = ENV.fetch("SEED_OPERATOR_PASSWORD") do
  unless Rails.env.local?
    raise "Defina SEED_OPERATOR_PASSWORD para semear operadores fora de desenvolvimento."
  end

  "password123"
end

operators = [
  {
    name: "Catamarã Paulo Afonso Turismo",
    slug: "catamara-paulo-afonso",
    email: "contato@catamarapauloafonso.example.com",
    phone: "+55 75 3281-1000",
    whatsapp: "+55 75 99100-1000",
    bio: "Passeios de barco pelo cânion do Rio São Francisco, saindo do " \
         "Pier do Povoado Rio do Sal."
  },
  {
    name: "Raso da Catarina Expedições",
    slug: "raso-da-catarina-expedicoes",
    email: "contato@rasodacatarina.example.com",
    phone: "+55 75 3281-2000",
    whatsapp: "+55 75 99100-2000",
    bio: "Expedições 4x4 pelo Raso da Catarina, com foco em observação de " \
         "aves e paisagem do sertão."
  },
  {
    name: "Sertão Vivo Turismo Cultural",
    slug: "sertao-vivo-cultural",
    email: "contato@sertaovivocultural.example.com",
    phone: "+55 75 3281-3000",
    whatsapp: "+55 75 99100-3000",
    bio: "Roteiros culturais e históricos em Paulo Afonso: energia, memória " \
         "e o sertão baiano."
  },
  {
    name: "Aventura Serra do Umbuzeiro",
    slug: "aventura-serra-umbuzeiro",
    email: "contato@aventuraumbuzeiro.example.com",
    phone: "+55 75 3281-4000",
    whatsapp: "+55 75 99100-4000",
    bio: "Trilhas e esportes de aventura na Serra do Umbuzeiro."
  }
].map do |attrs|
  operator = Operator.find_or_create_by!(email: attrs[:email]) do |o|
    o.name = attrs[:name]
    o.slug = attrs[:slug]
    o.phone = attrs[:phone]
    o.whatsapp = attrs[:whatsapp]
    o.bio = attrs[:bio]
    o.active = true
    o.password = SEED_OPERATOR_PASSWORD # Devise exige senha na criacao; banco 100% novo sem isso falha aqui
  end

  # Fora do bloco de criacao de proposito: roda em toda execucao, nao so na
  # primeira, entao um banco com operadores semeados antes do Devise
  # existir (senha placeholder invalida) tambem fica utilizavel.
  operator.update!(password: SEED_OPERATOR_PASSWORD)
  operator
end

catamara, raso_da_catarina, sertao_vivo, aventura_umbuzeiro = operators

tours = [
  {
    operator: catamara,
    title: "Catamarã no Cânion",
    slug: "catamara-no-canion",
    category: :boat,
    description: "Passeio de catamarã pelo cânion do Rio São Francisco, com " \
                  "parede de granito de até 170 metros e parada de 2 horas " \
                  "para banho no Espaço Ecológico Vale do Sal. Almoço em " \
                  "buffet livre disponível como opcional na reserva.",
    duration_minutes: 240,
    base_price_cents: 13_500,
    meeting_point: "Pier do Povoado Rio do Sal",
    lat: -9.4130,
    lng: -38.2050,
    min_age: 0,
    lunch_price_cents: 7_500,
    departure_hour: 8
  },
  {
    operator: catamara,
    title: "Pôr do Sol de Lancha no Cânion",
    slug: "por-do-sol-de-lancha",
    category: :boat,
    description: "Passeio curto de lancha pelo trecho navegável mais alto " \
                  "do Rio São Francisco, com o pôr do sol entre os " \
                  "paredões do cânion.",
    duration_minutes: 90,
    base_price_cents: 9_000,
    meeting_point: "Marina Central de Paulo Afonso",
    lat: -9.4025,
    lng: -38.2260,
    min_age: 5,
    departure_hour: 16
  },
  {
    operator: raso_da_catarina,
    title: "Raso da Catarina 4x4",
    slug: "raso-da-catarina-4x4",
    category: :offroad,
    description: "Expedição 4x4 saindo da Pousada Aconchego do Raso, com " \
                  "revoada da arara-azul-de-lear ao amanhecer, passagem " \
                  "pelo Cânion Seco da Baixa do Chico e pela comunidade " \
                  "indígena Pankararé, além de paredões de arenito e " \
                  "mirantes.",
    duration_minutes: 240,
    base_price_cents: 18_000,
    meeting_point: "Pousada Aconchego do Raso",
    lat: -9.7450,
    lng: -38.5050,
    min_age: 5,
    departure_hour: 5
  },
  {
    operator: sertao_vivo,
    title: "Complexo Hidrelétrico da CHESF",
    slug: "complexo-chesf",
    category: :cultural,
    description: "Visita guiada ao complexo hidrelétrico da CHESF em Paulo " \
                  "Afonso, com explicação sobre a geração de energia no " \
                  "Rio São Francisco.",
    duration_minutes: 90,
    base_price_cents: 6_000,
    meeting_point: "Portaria de Visitantes da CHESF",
    lat: -9.39694,
    lng: -38.20222,
    min_age: 10,
    departure_hour: 9
  },
  {
    operator: sertao_vivo,
    title: "Rota do Cangaço",
    slug: "rota-do-cangaco",
    category: :cultural,
    description: "Passeio a pé pelo centro de Paulo Afonso com guia local, " \
                  "contando a história do cangaço e a memória de Lampião " \
                  "na região.",
    duration_minutes: 120,
    base_price_cents: 7_000,
    meeting_point: "Praça da Bíblia, Centro de Paulo Afonso",
    lat: -9.4000,
    lng: -38.2250,
    min_age: 0,
    departure_hour: 9
  },
  {
    operator: aventura_umbuzeiro,
    title: "Serra do Umbuzeiro",
    slug: "serra-do-umbuzeiro",
    category: :hiking,
    description: "Trilha e esportes de aventura na Serra do Umbuzeiro, com " \
                  "vista panorâmica do sertão baiano.",
    duration_minutes: 300,
    base_price_cents: 12_000,
    meeting_point: "Base da Serra do Umbuzeiro",
    lat: -9.4350,
    lng: -38.1850,
    min_age: 12,
    departure_hour: 7
  }
].map do |attrs|
  departure_hour = attrs.delete(:departure_hour)
  operator = attrs.delete(:operator)

  tour = Tour.find_or_create_by!(slug: attrs[:slug]) do |t|
    t.assign_attributes(attrs.merge(operator:, active: true))
  end

  [ tour, departure_hour ]
end

tours.each do |tour, departure_hour|
  DEPARTURE_OFFSETS_IN_DAYS.each do |offset|
    starts_at = offset.days.from_now.change(hour: departure_hour, min: 0, sec: 0)

    Departure.find_or_create_by!(tour:, starts_at:) do |departure|
      departure.capacity = 12
      departure.status = :scheduled
    end
  end
end

# Idempotente pelo mesmo motivo do resto do arquivo: so anexa se o passeio
# ainda nao tem foto nenhuma, senao rodar db:seed de novo duplicaria.
DemoPhotos::BY_TOUR_SLUG.each do |slug, photos|
  tour = Tour.find_by!(slug: slug)
  next if tour.tour_photos.any?

  photos.each_index do |position|
    entry = DemoPhotos.entry(slug, position)
    tour.tour_photos.create!(image: File.open(entry[:path]), alt_text: entry[:alt], position: position)
  end
end

puts "Seeds: #{Operator.count} operadores, #{Tour.count} passeios, #{Departure.count} saidas, #{TourPhoto.count} fotos."
