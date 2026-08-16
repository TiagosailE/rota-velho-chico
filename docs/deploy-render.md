# Deploy de teste no Render (gratuito)

Caminho separado do [`deploy.md`](deploy.md) (Kamal + VPS paga). Este aqui é
para colocar o site no ar rapidamente, sem custo, para testar -- não é o
deploy recomendado para produção de verdade (ver limitações no fim).

## Por que Render e não outra plataforma gratuita

Pesquisado antes de escolher (agosto/2026):

| Plataforma | Realmente grátis? |
|---|---|
| **Render** | Sim -- sem cartão, web service + Postgres grátis |
| Fly.io | Não -- exige cartão até no plano "Hobby" desde 2024 |
| Railway | Só crédito de teste único (US$5), depois cobra |

Trade-off do Render: o web service gratuito **dorme após 15 min sem
tráfego** e demora ~1 min para acordar no próximo acesso; o Postgres
gratuito **expira em 30 dias** (dá pra recriar). Para "só testar" isso é
aceitável -- não é o que você quer para o site ficar sempre disponível.

## 1. Pré-requisito

Conta no [Render](https://render.com) (login com GitHub é o mais rápido --
sem cartão pedido).

## 2. Criar o Blueprint

O repositório já tem [`render.yaml`](../render.yaml) na raiz, configurado
para casar exatamente com `config/database.yml` (mesmo nome de banco,
mesmo usuário) -- zero mudança de código para este deploy.

1. Render Dashboard → **New** → **Blueprint**.
2. Conecte a conta do GitHub e escolha o repositório `rota-velho-chico`.
3. O Render lê o `render.yaml` sozinho e mostra os dois recursos que vai
   criar: o banco `rota-velho-chico-db` e o serviço web `rota-velho-chico`.
4. Ele vai pedir o valor de `RAILS_MASTER_KEY` (o `sync: false` no
   `render.yaml` é o que garante que essa chave não fica escrita no arquivo
   versionado) -- copie o conteúdo de `config/master.key` e cole.
5. **Apply** / **Create New Resources**.

## 3. Esperar o primeiro deploy

O Render builda a imagem a partir do `Dockerfile` já existente (o mesmo que
o Kamal usa) e sobe o container. `bin/docker-entrypoint` roda
`bin/rails db:prepare` no boot, que cria as 4 bases (`primary`/`cache`/
`queue`/`cable`) sozinho -- não precisa migrar na mão.

Acompanhe em **Logs**, na página do serviço. Primeiro build leva alguns
minutos (compila assets, `bootsnap precompile`).

## 4. Popular com dados de demonstração

Pela aba **Shell** do serviço no dashboard do Render (ou `render.com`'s
CLI, se preferir):

```bash
bin/rails db:seed
```

## 5. Verificação

A URL fica em `https://rota-velho-chico.onrender.com` (ou similar --
o Render mostra o link exato no dashboard). Deve mostrar a listagem de
passeios. Primeiro acesso depois de um período sem tráfego demora ~1 min
(o serviço estava dormindo) -- normal do plano gratuito, não é bug.

## Limitações conhecidas deste caminho (leia antes de mostrar pra alguém)

- **Fotos não persistem.** O Active Storage está configurado para disco
  local (`config/storage.yml`, `service: Disk`) -- funciona normalmente
  enquanto o container está de pé, mas o disco não é persistente no plano
  gratuito do Render: toda vez que o serviço dorme e acorda (ou é
  redeployado), o disco volta zerado e as fotos enviadas via
  `db:seed`/painel do operador somem. Pra corrigir de verdade, o Active
  Storage precisa apontar para um serviço externo (ex.: Cloudflare R2, que
  tem camada gratuita e é compatível com a API do S3) -- não implementado
  aqui porque não foi pedido; é o próximo passo se quiser que as fotos
  fiquem estáveis.
- **Sem Stripe real.** As chaves de teste do Stripe não estão nas
  credenciais deste ambiente -- pagamento vai mostrar a mensagem de
  indisponibilidade tratada no `CheckoutController` (ver `PROGRESS.md`),
  não vai quebrar, mas não completa de verdade.
- **Banco expira em 30 dias.** Passado esse prazo o Render dá 14 dias de
  carência antes de apagar; recriar o Blueprint resolve, mas perde os
  dados -- rode as seeds de novo.
- **Sem domínio próprio nem e-mail configurado.** URL é a do subdomínio
  `onrender.com`; e-mails (confirmação de reserva, cancelamento de saída)
  não têm SMTP real configurado, então só aparecem no log do serviço.
