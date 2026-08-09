# Dados de demonstracao baseados em pesquisa publica sobre operadores de
# turismo em Paulo Afonso (BA). Nomes de agencia, precos e horarios sao
# fabricados para o MVP -- nao ha afiliacao com nenhum operador real (ver
# aviso no README). Idempotente: pode rodar mais de uma vez sem duplicar.

DEPARTURE_OFFSETS_IN_DAYS = (1..10).map { |i| i * 9 } # 10 saidas por passeio, ate 90 dias a frente

operators = [
  {
    name: "Catamara Paulo Afonso Turismo",
    slug: "catamara-paulo-afonso",
    email: "contato@catamarapauloafonso.example.com",
    phone: "+55 75 3281-1000",
    whatsapp: "+55 75 99100-1000",
    bio: "Passeios de barco pelo canion do Rio Sao Francisco, saindo do " \
         "Pier do Povoado Rio do Sal."
  },
  {
    name: "Raso da Catarina Expedicoes",
    slug: "raso-da-catarina-expedicoes",
    email: "contato@rasodacatarina.example.com",
    phone: "+55 75 3281-2000",
    whatsapp: "+55 75 99100-2000",
    bio: "Expedicoes 4x4 pelo Raso da Catarina, com foco em observacao de " \
         "aves e paisagem do sertao."
  },
  {
    name: "Sertao Vivo Turismo Cultural",
    slug: "sertao-vivo-cultural",
    email: "contato@sertaovivocultural.example.com",
    phone: "+55 75 3281-3000",
    whatsapp: "+55 75 99100-3000",
    bio: "Roteiros culturais e historicos em Paulo Afonso: energia, memoria " \
         "e o sertao baiano."
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
  end

  # Fora do bloco de criacao de proposito: roda em toda execucao, nao so na
  # primeira, entao um banco com operadores semeados antes do Devise
  # existir (senha placeholder invalida) tambem fica utilizavel.
  operator.update!(password: "password123") # senha de desenvolvimento, nunca usada em producao
  operator
end

catamara, raso_da_catarina, sertao_vivo, aventura_umbuzeiro = operators

tours = [
  {
    operator: catamara,
    title: "Catamara no Canion",
    slug: "catamara-no-canion",
    category: :boat,
    description: "Passeio de catamara pelo canion do Rio Sao Francisco, com " \
                  "parede de granito de ate 170 metros e parada de 2 horas " \
                  "para banho no Espaco Ecologico Vale do Sal. Almoco em " \
                  "buffet livre disponivel como opcional, pago a bordo.",
    duration_minutes: 240,
    base_price_cents: 13_500,
    meeting_point: "Pier do Povoado Rio do Sal",
    min_age: 0,
    includes_lunch: false,
    departure_hour: 8
  },
  {
    operator: catamara,
    title: "Por do Sol de Lancha no Canion",
    slug: "por-do-sol-de-lancha",
    category: :boat,
    description: "Passeio curto de lancha pelo trecho navegavel mais alto " \
                  "do Rio Sao Francisco, com o por do sol entre os " \
                  "paredoes do canion.",
    duration_minutes: 90,
    base_price_cents: 9_000,
    meeting_point: "Marina Central de Paulo Afonso",
    min_age: 5,
    includes_lunch: false,
    departure_hour: 16
  },
  {
    operator: raso_da_catarina,
    title: "Raso da Catarina 4x4",
    slug: "raso-da-catarina-4x4",
    category: :offroad,
    description: "Expedicao 4x4 saindo da Pousada Aconchego do Raso, com " \
                  "revoada da arara-azul-de-lear ao amanhecer, passagem " \
                  "pelo Canion Seco da Baixa do Chico e pela comunidade " \
                  "indigena pankarare, alem de paredoes de arenito e " \
                  "mirantes.",
    duration_minutes: 240,
    base_price_cents: 18_000,
    meeting_point: "Pousada Aconchego do Raso",
    min_age: 5,
    includes_lunch: false,
    departure_hour: 5
  },
  {
    operator: sertao_vivo,
    title: "Complexo Hidreletrico da CHESF",
    slug: "complexo-chesf",
    category: :cultural,
    description: "Visita guiada ao complexo hidreletrico da CHESF em Paulo " \
                  "Afonso, com explicacao sobre a geracao de energia no " \
                  "Rio Sao Francisco.",
    duration_minutes: 90,
    base_price_cents: 6_000,
    meeting_point: "Portaria de Visitantes da CHESF",
    min_age: 10,
    includes_lunch: false,
    departure_hour: 9
  },
  {
    operator: sertao_vivo,
    title: "Rota do Cangaco",
    slug: "rota-do-cangaco",
    category: :cultural,
    description: "Passeio a pe pelo centro de Paulo Afonso com guia local, " \
                  "contando a historia do cangaco e a memoria de Lampiao " \
                  "na regiao.",
    duration_minutes: 120,
    base_price_cents: 7_000,
    meeting_point: "Praca da Biblia, Centro de Paulo Afonso",
    min_age: 0,
    includes_lunch: false,
    departure_hour: 9
  },
  {
    operator: aventura_umbuzeiro,
    title: "Serra do Umbuzeiro",
    slug: "serra-do-umbuzeiro",
    category: :hiking,
    description: "Trilha e esportes de aventura na Serra do Umbuzeiro, com " \
                  "vista panoramica do sertao baiano.",
    duration_minutes: 300,
    base_price_cents: 12_000,
    meeting_point: "Base da Serra do Umbuzeiro",
    min_age: 12,
    includes_lunch: false,
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

puts "Seeds: #{Operator.count} operadores, #{Tour.count} passeios, #{Departure.count} saidas."
