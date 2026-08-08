# Arquitetura — Rota Velho Chico

Referência técnica de arquitetura e das decisões de design do projeto.

---

## 1. Modelo de domínio

```
Operator ──< Tour ──< Departure ──< Booking ──o Payment
   (agência)  (passeio)  (saída)     (reserva)    (sinal/estorno)

StripeEvent  (isolada — só idempotência de webhook)
```

Cardinalidade: `Operator` 1─N `Tour` 1─N `Departure` 1─N `Booking` 1─1 `Payment`.

### 1.1 `operators`

Agência local. Autenticação via Devise (`database_authenticatable`, `recoverable`, `rememberable`, `validatable`). **Sem `registerable`** — contas são semeadas; não há cadastro público de operador no MVP.

| Coluna | Tipo | Notas |
|---|---|---|
| `name` | string | not null |
| `slug` | string | not null, índice único |
| `email` | string | not null, índice único |
| `encrypted_password` | string | not null |
| `reset_password_token` | string | índice único |
| `reset_password_sent_at` | datetime | |
| `remember_created_at` | datetime | |
| `phone`, `whatsapp` | string | contato público |
| `bio` | text | |
| `active` | boolean | not null, default `true` |

### 1.2 `tours`

O passeio como produto — sem data.

| Coluna | Tipo | Notas |
|---|---|---|
| `operator_id` | bigint | FK not null, índice |
| `title` | string | not null |
| `slug` | string | not null, índice único |
| `description` | text | |
| `category` | integer | enum, not null, índice |
| `duration_minutes` | integer | not null, `CHECK > 0` |
| `base_price_cents` | integer | not null, `CHECK > 0` |
| `meeting_point` | string | not null |
| `min_age` | integer | not null, default `0` |
| `includes_lunch` | boolean | not null, default `false` |
| `active` | boolean | not null, default `true` |

`category`: `boat: 0`, `offroad: 1`, `hiking: 2`, `cultural: 3`.

> **Almoço.** No MVP é um booleano — o almoço está ou não incluso no preço. Os dados reais têm buffet opcional a R$ 75, o que na verdade é um *add-on* por pessoa. Modelar add-on corretamente exige tabela própria e mexe no `PriceCalculator`; ficou no backlog para não inflar a Semana 1. Se for implementar, é mudança de schema, não de booleano.

### 1.3 `departures`

Uma saída datada. **É aqui que mora a concorrência.**

| Coluna | Tipo | Notas |
|---|---|---|
| `tour_id` | bigint | FK not null |
| `starts_at` | datetime | not null, índice |
| `capacity` | integer | not null, `CHECK > 0` |
| `seats_taken` | integer | not null, default `0` |
| `status` | integer | enum, not null, default `0` |
| `price_override_cents` | integer | nullable, `CHECK > 0` quando presente |

`status`: `scheduled: 0`, `cancelled: 1`, `completed: 2`.

**Índices e constraints:**
- Único composto `[tour_id, starts_at]` — o mesmo passeio não sai duas vezes no mesmo instante.
- Índice `[starts_at]` para a busca pública por data.
- **`CHECK (seats_taken >= 0 AND seats_taken <= capacity)`** — a rede de segurança do banco.

**Preço unitário efetivo:**
```ruby
# app/models/departure.rb
def unit_price_cents
  price_override_cents || tour.base_price_cents
end
```
Todo cálculo passa por aqui. Nunca leia `tour.base_price_cents` diretamente fora deste método.

### 1.4 `bookings`

| Coluna | Tipo | Notas |
|---|---|---|
| `departure_id` | bigint | FK not null, índice |
| `code` | string | not null, índice único |
| `customer_name` | string | not null |
| `customer_email` | string | not null, índice (consulta por código+e-mail) |
| `customer_phone` | string | |
| `adults` | integer | not null, default `0` |
| `children_5_9` | integer | not null, default `0` |
| `children_0_4` | integer | not null, default `0` |
| `unit_price_cents` | integer | not null — **snapshot** |
| `total_cents` | integer | not null — **snapshot** |
| `deposit_cents` | integer | not null — **snapshot** |
| `status` | integer | enum, not null, default `0` |
| `cancelled_at` | datetime | nullable |

`status`: `pending: 0`, `confirmed: 1`, `cancelled: 2`, `refunded: 3`.

**Constraints:** contadores `>= 0`, e `CHECK (adults + children_5_9 + children_0_4 > 0)` — reserva vazia não existe.

**Sobre os três snapshots de preço:** se o operador reajustar o passeio em março, uma reserva de janeiro tem que continuar valendo o que valia em janeiro. Sem esses campos, qualquer relatório financeiro passado muda sozinho quando alguém edita um preço. É defeito clássico de sistema de reserva.

### 1.5 `payments`

| Coluna | Tipo | Notas |
|---|---|---|
| `booking_id` | bigint | FK not null, **índice único** (`has_one`) |
| `stripe_payment_intent_id` | string | índice único |
| `amount_cents` | integer | not null |
| `status` | integer | enum, not null, default `0` |
| `paid_at` | datetime | |
| `stripe_refund_id` | string | índice único, nullable |
| `refunded_amount_cents` | integer | nullable |
| `refunded_at` | datetime | nullable |

`status`: `pending: 0`, `succeeded: 1`, `failed: 2`, `refunded: 3`.

### 1.6 `stripe_events`

Existe por um motivo só: o Stripe reenvia webhooks. Sem isso, uma reserva pode ser confirmada — ou estornada — duas vezes.

| Coluna | Tipo | Notas |
|---|---|---|
| `stripe_event_id` | string | not null, **índice único** |
| `event_type` | string | not null |
| `processed_at` | datetime | nullable |

Fluxo: verifica assinatura → tenta inserir o evento → se o índice único recusar, já foi processado, responde 200 e para.

---

## 2. Service objects

Regra de negócio em `app/services/`. Controllers orquestram e traduzem; models validam e associam.

Contrato de retorno para falhas de regra de negócio:
```ruby
Result = Struct.new(:success?, :value, :error)
```
Lotado ou fora do prazo é `Result` com `error` simbólico. Exceção fica para o que não deveria acontecer.

### 2.1 `PriceCalculator` — Ruby puro

```ruby
PriceCalculator.new(
  unit_price_cents:,   # Integer já resolvido por Departure#unit_price_cents
  adults:,
  children_5_9:,
  children_0_4:
)
#total_cents   -> Integer
#deposit_cents -> Integer
```

Recebe um inteiro, **não** um `Departure` — é o que a mantém sem ActiveRecord e testável em milissegundos.

Regras (coletadas dos operadores):

| Faixa | Cobrança |
|---|---|
| 0–4 anos | gratuito (vai no colo) |
| 5–9 anos | 50% |
| 10+ anos | integral |

```
total_cents   = adults * unit + children_5_9 * (unit / 2.0).round
deposit_cents = (total_cents * 0.30).round
```

Arredondamento é **explícito**. `unit / 2` com inteiros trunca e vaza centavos; com R$ 135,00 dá exato, com preço ímpar não. Fixe `DEPOSIT_RATE = 0.30` como constante.

### 2.2 `BookingCreator` — o coração

```ruby
BookingCreator.new(
  departure:,
  customer_name:, customer_email:, customer_phone:,
  adults:, children_5_9:, children_0_4:
)
#call -> Result(success?, booking, error)
```

Erros possíveis: `:sold_out`, `:departure_not_scheduled`, `:departure_in_the_past`, `:invalid_party`.

```ruby
def call
  @departure.with_lock do          # SELECT ... FOR UPDATE
    seats = @adults + @children_5_9 + @children_0_4
    return Result.new(false, nil, :sold_out) if
      @departure.seats_taken + seats > @departure.capacity

    booking = Booking.create!(...)  # com os snapshots de preço
    @departure.increment!(:seats_taken, seats)
    Result.new(true, booking, nil)
  end
end
```

**Três camadas de defesa:**
1. Lock pessimista — seção crítica mínima: lê, valida, grava, commita.
2. `CHECK` no banco — recusa mesmo se a aplicação errar.
3. Teste de concorrência com threads reais (seção 5).

**Dentro do lock não entra:** chamada ao Stripe, envio de e-mail, nada de I/O externo. O lock segura uma linha do Postgres; uma chamada HTTP lenta lá dentro serializa o sistema inteiro.

**Crianças de 0 a 4 anos contam como vaga**, embora não paguem — é contagem de colete e capacidade legal da embarcação. A assimetria com o `PriceCalculator` é intencional.

### 2.3 `RefundPolicy` — Ruby puro

```ruby
RefundPolicy.new(
  departure_starts_at:,
  cancelled_at:,
  cancelled_by_operator: false
)
#refundable? -> Boolean
```

| Situação | Sinal |
|---|---|
| > 48h antes da saída | estornado |
| < 48h antes | retido pelo operador |
| saída cancelada pelo operador | sempre estornado |

`WINDOW = 48.hours`. Recebe timestamps, não models — pura e trivial de testar nas bordas (47h59, 48h01).

### 2.4 `DepartureCanceller`

```ruby
DepartureCanceller.new(departure:)
#call -> Result(success?, cancelled_count, error)
```

Ordem importa:

1. **Numa transação:** `departure` → `cancelled`; todas as `bookings` ativas → `cancelled`; `seats_taken` → `0`.
2. **Depois de commitar:** enfileira um job por reserva para estornar no Stripe e avisar por e-mail.

O estorno **não** acontece na transação. Se o Stripe demorar ou cair, o banco não pode ficar com transação aberta — e um job que falhou pode ser reprocessado, uma transação abortada no meio de 40 estornos não.

---

## 3. Fluxos

### 3.1 Reserva (turista, sem login)

```
busca → detalhe do passeio → calendário (Turbo Frame)
     → formulário → BookingCreator → booking (pending)
     → Stripe Payment Intent (sinal 30%)
     → webhook payment_intent.succeeded → booking (confirmed) + e-mail com o código
```

O turista guarda o **código**. Consulta depois com código + e-mail — dois fatores fracos, mas suficientes para o caso de uso e sem custo de cadastro.

### 3.2 Cancelamento pelo turista

```
consulta por código+e-mail → RefundPolicy#refundable?
   true  → estorno no Stripe → booking refunded, vagas liberadas
   false → booking cancelled, sinal retido, vagas liberadas
```

Em ambos os casos as vagas voltam — a retenção do sinal é a penalidade, não o assento.

### 3.3 Cancelamento pelo operador (clima)

`DepartureCanceller` conforme 2.4. Estorno integral independente do prazo.

---

## 4. Máquinas de estado

**Booking**
```
pending ──(pagamento confirmado)──> confirmed
   │                                    │
   └────────(cancelamento)──────────────┴──> cancelled ──(estorno ok)──> refunded
```

**Departure**
```
scheduled ──> cancelled
     └──────> completed   (após starts_at)
```

Transições de `Booking` acontecem só em service objects. Nunca `booking.update(status: :confirmed)` espalhado por controller.

---

## 5. Concorrência

### Por que lock pessimista

Para o tráfego alvo, disputa por vaga é rara mas catastrófica quando acontece. Lock otimista exige laço de retry e ainda perde corrida sob carga. `SELECT ... FOR UPDATE` numa seção crítica de microssegundos é mais simples e correto. O trade-off (serializa reservas da *mesma* saída) é irrelevante aqui — saídas diferentes não se bloqueiam.

### Por que `seats_taken` desnormalizado

`departure.bookings.sum(...)` a cada requisição não escala e — mais importante — não é lockável de forma limpa: seria preciso travar a tabela de reservas inteira. Um contador na linha da saída é exatamente o que `FOR UPDATE` trava bem. O custo é o contador poder divergir; a `CHECK` constraint e os testes cobrem isso.

### O teste de 20 threads

20 threads disputam 10 vagas; exatamente 10 reservas devem existir.

Três pré-requisitos, todos causa de falha confusa se esquecidos:

1. **Transactional fixtures desligadas nesse spec.** Ligadas, o teste roda numa transação não commitada e as threads (cada uma em sua conexão) não enxergam a saída. Limpeza é manual.
2. **Pool de conexões > número de threads.** Padrão do Rails é 5. Com 20 threads o teste trava esperando conexão e falha por timeout, não por overbooking — sintoma que não parece o problema real.
3. **`ActiveRecord::Base.connection_pool.with_connection` em cada thread**, devolvendo a conexão ao pool no fim.

Instabilidade nesse teste é quase sempre um desses três, não o `BookingCreator`.

---

## 6. Pagamento

Sinal de **30%** via Stripe Payment Intents (modo teste).

- Valor em centavos, moeda `brl`.
- **Assinatura do webhook sempre verificada**, inclusive em desenvolvimento.
- Idempotência via `stripe_events` (1.6).
- Nenhum teste toca a rede — Stripe é stubado.

O sinal parcial não é só realismo de mercado: torna a regra de estorno **binária** (devolve ou não devolve) em vez de escalonada por percentual. Menos superfície de bug, política mais fácil de explicar.

---

## 7. i18n

pt-BR (padrão) e EN. Justificativa de negócio: a arara-azul-de-lear atrai observadores de aves estrangeiros — é o público internacional real de Paulo Afonso.

- Nenhum texto de usuário fora de `config/locales/`.
- Datas e moeda formatadas por locale (`R$ 135,00` / `R$ 135.00`).
- Locale por parâmetro de URL, com fallback para pt-BR.
- Nomes de rota permanecem em inglês.

---

## 8. Decisões e trade-offs

Matéria-prima da seção mais valiosa do README.

| Decisão | Alternativa descartada | Por quê |
|---|---|---|
| PostgreSQL | SQLite | Escritor único tornaria a demonstração de concorrência trivial e sem graça. `FOR UPDATE` é o que dá credibilidade à feature-estrela. |
| Lock pessimista | Lock otimista com retry | Disputa rara, custo de conflito alto, seção crítica curta. Mais simples e mais correto aqui. |
| `seats_taken` desnormalizado | `COUNT` nas reservas | Contagem não é lockável de forma limpa. Contador na linha é. |
| Sem login de turista | Devise para todo mundo | Quem reserva um catamarã não quer criar conta. Menos atrito, mais fiel ao mercado. |
| Sinal de 30% | Pagamento integral | Realista para agência de sertão e torna o estorno binário. |
| Snapshot de preço | Recalcular do `Tour` | Reserva passada não pode mudar quando o preço muda. |
| Serviços puros para preço/estorno | Métodos no model | Sem ActiveRecord, testam em milissegundos e a regra fica isolada da persistência. |
| Estorno em job | Estorno na transação | Chamada externa não pode segurar transação de banco. Job falho é reprocessável. |
