# Segurança

O que o app protege, de quem, e as decisões tomadas para isso. Complementa
`docs/architecture.md` (que descreve o domínio) e o README (que resume as
decisões de engenharia).

---

## 1. O que há para proteger

| Ativo | Por que importa |
|---|---|
| Dados pessoais do turista | Nome, e-mail e telefone de quem reservou. Nunca ficam atrás de login: a credencial é o par código + e-mail. |
| Dinheiro | O sinal de 30% e o estorno passam pelo Stripe. Um cancelamento indevido devolve dinheiro de verdade. |
| Disponibilidade de vagas | Reserva nasce `pending` e já ocupa vaga. Vaga ocupada indevidamente é receita perdida pelo operador. |
| Sessão do operador | Quem entra no painel edita preço, cancela saída e dispara estorno em cascata. |

Três atores: o **visitante anônimo** (a maior parte do site), o **turista com
um código** (consulta, paga, cancela, avalia) e o **operador autenticado**
(painel). Não existe papel de administrador.

## 2. Controles que já vinham do desenho

- **CSRF** ligado por padrão do Rails em todo formulário; a única exceção é o
  webhook do Stripe, que se autentica por assinatura HMAC (`StripeWebhooksController`).
- **Escopo do operador**: todo acesso a dado no painel parte de
  `current_operator` (invariante 7 do contrato interno), então um operador
  não alcança passeio de outro nem trocando o id na URL.
- **Consulta exige código + e-mail**, nunca só o código, e a resposta é a
  mesma para código inexistente e para e-mail errado — não entrega se um
  código existe. Não há `GET /bookings/:code` público.
- **Idempotência do webhook** por índice único em `stripe_events`, com a
  assinatura verificada mesmo em desenvolvimento.
- **Integridade sob concorrência**: `seats_taken` só muda dentro de
  `SELECT ... FOR UPDATE`, com `CHECK` constraints no banco como última
  linha de defesa.
- **CI barra regressão**: `bin/ci` roda Brakeman, `bundler-audit` e
  `importmap audit` a cada execução, e falha o build no primeiro aviso.

## 3. O que esta rodada fechou

### 3.1 Credencial de operador publicada no repositório

`db/seeds.rb` trazia a senha dos quatro operadores de demonstração escrita no
arquivo. O repositório é público e as mesmas seeds rodam no ambiente
publicado: qualquer pessoa que abrisse o repo tinha login válido no painel —
com acesso a editar preço, cancelar saída e disparar estorno.

A senha passou a vir de `SEED_OPERATOR_PASSWORD`. Em desenvolvimento e teste
existe um valor padrão (banco local, sem valor para ninguém, e os specs
dependem dele); fora disso a variável é obrigatória e a ausência **interrompe
o seed** em vez de cair num padrão adivinhável.

### 3.2 Rotas de manutenção de uso único

`operators/maintenance/reset_photos` e `.../fix_accents` existiam porque o
plano gratuito do Render não dá acesso a shell. Já cumpriram o propósito, e
estavam atrás de um login que o item anterior tornava público. Rotas,
controller, jobs e specs foram removidos — o histórico do Git guarda o
código se a necessidade voltar.

### 3.3 HTTPS obrigatório

`config.force_ssl` estava comentado em produção. Sem ele não há HSTS, não há
redirecionamento de HTTP para HTTPS e — o que mais pesa — o cookie de sessão
do operador não é marcado `secure`. Ligado junto com `assume_ssl` (os dois
caminhos de deploy terminam TLS num proxy à frente) e com `/up` fora do
redirecionamento, para não quebrar o health check.

A contrapartida está anotada em `config/deploy.yml`: o deploy por Kamal está
configurado sem proxy nem domínio, e num acesso por IP em HTTP puro o cookie
`secure` não volta do navegador — o login do operador falharia em silêncio.
Esse caminho de deploy ainda não existe (a VPS nunca foi criada); o ambiente
publicado hoje é o Render, que serve HTTPS.

### 3.4 Content Security Policy

Não havia nenhuma: o initializer estava inteiro comentado. A política agora é
montada a partir do que o site carrega de verdade — `script-src 'self'` com
nonce (o importmap gera um `<script>` inline), Google Fonts e a folha do
Leaflet nas diretivas de estilo e fonte, `frame-ancestors 'none'`,
`object-src 'none'`.

Verificada em navegador com o site rodando, não só por leitura do header:
home, página de passeio (mapa com tiles do OpenStreetMap e galeria),
formulário de reserva com o resumo de preço ao vivo, consulta com toast de
erro, login e painel do operador, mais o fluxo completo de reserva até a
confirmação — zero violação no console.

### 3.5 Limite de tentativas

Não havia nenhum. O código da reserva tem 6 posições, e sem limite dá para
varrer combinações até cair na reserva de outra pessoa — para ler, cancelar
ou avaliar em nome dela. `rate_limit` (nativo do Rails 8, sem gem nova) entrou
em seis pontos: login do operador, consulta, cancelamento, avaliação,
pagamento e criação de reserva. O último protege disponibilidade, não dado
pessoal: reserva não paga já ocupa vaga, então um laço contra o endpoint
esgotaria as saídas de graça.

### 3.6 Dado pessoal no log

`filter_parameters` cobria e-mail e senha, mas não `customer_phone` nem
`customer_name`, que iam inteiros para o log de produção a cada reserva.

## 4. Aceito conscientemente

Nenhum destes é descuido; cada um foi pesado contra o custo de fechar.

- **`img-src` aceita qualquer `https:`.** As fotos saem do Active Storage por
  uma URL do próprio app que redireciona para o Cloudflare R2, e o mapa puxa
  tiles do OpenStreetMap. Fixar os hosts significaria escrever num arquivo
  versionado uma infraestrutura que hoje vive em `credentials`, e um erro ali
  derruba todas as fotos do site. Como `script-src` não deixa script de
  terceiro rodar, não sobra quem monte uma URL de exfiltração.
- **`style-src-attr 'unsafe-inline'`.** Dois atributos `style=` sobrevivem
  (barra de ocupação e duração do toast), ambos com valor calculado no
  servidor a partir de número, nunca de entrada do usuário. `<style>` inline
  continua bloqueado.
- **`form-action` não declarado.** O pagamento é um POST no próprio app que
  responde com redirecionamento para o Stripe Checkout, e o Chrome valida a
  diretiva também no destino do redirecionamento — declará-la quebraria o
  único fluxo que gera receita.
- **O código da reserva aparece no caminho da URL** em `/bookings/:code/pay`
  e afins, e caminho de URL vai para o log independentemente de
  `filter_parameters`. Tirar isso exigiria redesenhar as três rotas; o limite
  de tentativas reduz o valor prático de um código vazado.
- **Sem `lockable` no Devise.** Bloquear conta por tentativas erradas abre um
  jeito trivial de negar acesso ao operador legítimo. O limite por IP cobre a
  varredura de senha sem esse efeito colateral.

## 5. Fora do repositório

Estes não são código e não têm como ser aplicados por um deploy — ficam
registrados aqui para não se perderem:

1. **Definir `SEED_OPERATOR_PASSWORD` no ambiente publicado e rodar o seed de
   novo.** Enquanto isso não acontece, a senha que já está no histórico do Git
   continua valendo nas contas existentes: o item 3.1 fecha a porta para o
   futuro, não desfaz o que já foi publicado.
2. **`APP_HOST`** com o domínio real liga a proteção contra Host header
   forjado. Sem a variável o Rails não restringe nada — a ausência nunca
   derruba o site, só deixa de proteger.
3. **Bucket R2**: confirmar que não está com listagem pública e que o token
   usado pelo app tem escopo apenas do bucket do projeto.
4. **Stripe**: confirmar que as chaves do ambiente publicado são as de teste
   (o projeto é demonstração) e que o `webhook_secret` é o do endpoint real,
   não o de um `stripe listen` local.
5. **GitHub**: 2FA na conta, e *secret scanning* ligado — é gratuito em
   repositório público e avisa se uma chave for commitada por acidente.

## 6. Defeito conhecido, não corrigido aqui

`config.action_mailer.default_url_options` está como `example.com` em
produção: os links dentro dos e-mails de confirmação e cancelamento apontam
para um domínio que não é o do site. Não é falha de segurança e ficou de fora
para não misturar assuntos num mesmo diff, mas é real e quebra o e-mail.
