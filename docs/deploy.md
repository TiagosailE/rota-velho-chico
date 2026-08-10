# Deploy — Rota Velho Chico

Deploy via [Kamal 2](https://kamal-deploy.org/) para uma única VPS. Sem
domínio por enquanto — acesso direto pelo IP; sem load balancer nem múltiplos
servidores, porque o tráfego alvo (portfólio, demonstração) não justifica.

## Visão geral

Um único host roda dois containers gerenciados pelo Kamal: a aplicação Rails
(via [Thruster](https://github.com/basecamp/thruster) na porta 80) e um
accessory Postgres. O Solid Queue processa jobs dentro do próprio processo
Puma (`SOLID_QUEUE_IN_PUMA: true`) — não há um servidor de job separado.

```
Internet ──> :80 (Thruster/Puma, container "app")
                     │
                     └──> Postgres (container "db", só 127.0.0.1:5432)
```

## 1. Pré-requisitos (uma vez só)

- **Conta na [Hetzner Cloud](https://www.hetzner.com/cloud/)** (ou outro provedor com Ubuntu 22.04+/24.04 e Docker).
- **Chave SSH local.** Se não tiver: `ssh-keygen -t ed25519 -C "rota-velho-chico"`.
- **Personal Access Token do GitHub** com escopo `write:packages`, para o Kamal
  publicar a imagem no GitHub Container Registry (`ghcr.io`) — mesma conta do
  repositório, sem cadastro em outro serviço.
  [github.com/settings/tokens](https://github.com/settings/tokens) → *Generate new token (classic)*.

## 2. Criar a VPS

Hetzner Cloud Console → *Add Server*:

- **Localização:** a mais próxima do público alvo (ex.: São Paulo/Ashburn).
- **Imagem:** Ubuntu 24.04.
- **Tipo:** CX22 (2 vCPU, 4 GB RAM, ~€4/mês) — suficiente para uma app Rails
  pequena com Postgres no mesmo host.
- **Chave SSH:** adicione a chave pública gerada no passo 1.
- **Sem volume adicional, sem load balancer, sem rede privada** — um host
  simples é o que essa fase precisa.

Anote o **IP público** gerado.

## 3. Preencher a configuração

Dois arquivos já estão prontos, com placeholders explícitos:

**`config/deploy.yml`** — troque as duas ocorrências de
`SUBSTITUA_PELO_IP_DA_VPS` (em `servers.web` e em `accessories.db.host`)
pelo IP anotado no passo 2.

**Variáveis de ambiente locais**, antes de rodar qualquer comando do Kamal
(o parser de secrets do Kamal não suporta guarda de "falha se não definido" —
testado; se esquecer, a senha vai vazia silenciosamente, então confira com
`bin/kamal secrets print` antes de prosseguir):

```bash
export KAMAL_REGISTRY_PASSWORD=ghp_xxx   # o token do passo 1
export POSTGRES_PASSWORD=$(openssl rand -hex 32)
```

Guarde o valor de `POSTGRES_PASSWORD` gerado (num gerenciador de senhas) —
ele não fica salvo em lugar nenhum além da VPS depois do deploy.

## 4. Primeiro deploy

```bash
bin/kamal setup
```

Isso provisiona o Docker na VPS (se ainda não tiver), sobe o accessory
Postgres, builda e publica a imagem, e sobe a aplicação. `bin/docker-entrypoint`
roda `bin/rails db:prepare` no boot do container, que cria as 4 bases
(`primary`/`cache`/`queue`/`cable`) sozinho — não precisa migrar manualmente.

Deploys seguintes (depois que a VPS já está configurada):

```bash
bin/kamal deploy
```

## 5. Verificação pós-deploy

```bash
bin/kamal app logs        # segue os logs da aplicação
bin/kamal console         # abre bin/rails console no servidor
bin/kamal dbc              # abre bin/rails dbconsole
```

Acesse `http://<IP-da-VPS>/` — deve mostrar a listagem de passeios. Rode as
seeds uma vez (`bin/kamal app exec "bin/rails db:seed"`) se quiser dados de
demonstração em produção.

## O que ainda falta (fora do escopo desta etapa)

- **Domínio e HTTPS.** Sem domínio, não há certificado Let's Encrypt pra
  emitir — o `proxy:` do `config/deploy.yml` fica comentado. Quando houver
  um domínio, descomentar `proxy: { ssl: true, host: <dominio> }` e apontar o
  DNS (registro A) para o IP da VPS.
- **Stripe em modo produção.** As credenciais de teste (`bin/rails
  credentials:edit`, chave `stripe:`) continuam vazias até o Stripe ser
  configurado de verdade — ver `PROGRESS.md`, Dias 11-12.
- **Backup do Postgres.** O accessory `db` guarda dados no volume Docker
  `data` — sobrevive a redeploys, mas não a perda da VPS. Sem rotina de
  backup automatizada ainda.
