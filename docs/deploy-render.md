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

## 4. Configurar o Cloudflare R2 (fotos persistentes)

O disco local do plano gratuito do Render **não sobrevive** a um ciclo de
sono/acordar do serviço -- toda vez que isso acontece, os arquivos enviados
somem, mesmo que o registro continue no banco (é isso que faz a imagem
aparecer "quebrada" em vez de simplesmente não existir). Por isso o Active
Storage de produção aponta para o Cloudflare R2 (`config/storage.yml`,
service `cloudflare`) em vez de disco -- API compatível com S3, camada
gratuita de 10GB, sem custo.

1. Crie uma conta grátis em [dash.cloudflare.com](https://dash.cloudflare.com)
   (sem cartão pedido pro R2).
2. No menu lateral, **R2 Object Storage** → **Create bucket**. Nome
   sugerido: `rota-velho-chico`. Região: automática.
3. **Manage R2 API tokens** → **Create API token**. Permissão: **Object
   Read & Write**, escopo limitado a esse bucket (não precisa de acesso a
   conta inteira). Anote os três valores que aparecem **uma vez só**:
   Access Key ID, Secret Access Key, e o Endpoint (formato
   `https://<account_id>.r2.cloudflarestorage.com`).
4. No terminal Ubuntu, dentro do projeto:

   ```bash
   bin/rails credentials:edit
   ```

   Adicione (mantendo o que já existe, como `stripe:`):

   ```yaml
   cloudflare:
     endpoint: https://<account_id>.r2.cloudflarestorage.com
     access_key_id: <access key id do passo 3>
     secret_access_key: <secret access key do passo 3>
     bucket: rota-velho-chico
   ```

   Salve e feche o editor -- isso criptografa direto em
   `config/credentials.yml.enc`, que já é versionado (a chave de
   descriptografia é o `RAILS_MASTER_KEY`, que o Render já tem desde o
   Blueprint). Só precisa `git add`/commit/push desse arquivo -- nada de
   variável de ambiente nova no Render.

## 5. Popular com dados de demonstração

Antes de semear, defina `SEED_OPERATOR_PASSWORD` nas variáveis de ambiente do
serviço (**Environment** no dashboard). A senha dos operadores de
demonstração não vive no repositório -- ele é público, e uma senha escrita
lá é login válido no painel para qualquer pessoa que abra o código. Sem a
variável definida, o seed para com erro em vez de cair numa senha padrão
(ver `docs/security.md`, seção 3.1).

Pela aba **Shell** do serviço no dashboard do Render (ou `render.com`'s
CLI, se preferir):

```bash
bin/rails db:seed
```

Se você já tinha rodado `db:seed` **antes** de configurar o R2, os
registros de foto no banco apontam pra arquivos que não existem mais no
service antigo (`local`) -- `db:seed` não reenvia sozinho porque já vê
`tour_photos` cadastradas. Limpe e rode de novo:

```bash
bin/rails runner "TourPhoto.destroy_all" && bin/rails db:seed
```

## 6. Verificação

A URL fica em `https://rota-velho-chico.onrender.com` (ou similar --
o Render mostra o link exato no dashboard). Deve mostrar a listagem de
passeios, com fotos. Primeiro acesso depois de um período sem tráfego
demora ~1 min (o serviço estava dormindo) -- normal do plano gratuito,
não é bug.

## Limitações conhecidas deste caminho (leia antes de mostrar pra alguém)

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
