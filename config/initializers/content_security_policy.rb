# Be sure to restart your server when you modify this file.

# Politica montada a partir do que o site carrega de verdade, nao copiada de
# um exemplo generico. Cada origem externa abaixo esta aqui porque alguma
# pagina quebra sem ela -- o levantamento esta em docs/security.md.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.object_src  :none
    policy.base_uri    :self

    # O site nunca e legitimamente embutido em iframe. Cobre clickjacking de
    # forma mais forte que o X-Frame-Options que o Rails ja manda por padrao.
    policy.frame_ancestors :none

    # Fontes do Google (o CSS vem de fonts.googleapis.com, os arquivos .woff2
    # de fonts.gstatic.com) e a folha de estilo do Leaflet, que nao passa pelo
    # importmap -- ele so lida com JS -- e vem do CDN oficial com SRI.
    policy.style_src :self, "https://fonts.googleapis.com", "https://unpkg.com"
    policy.font_src  :self, "https://fonts.gstatic.com"

    # Atributo `style=` inline sobrevive em dois lugares (barra de ocupacao do
    # painel e duracao do toast), os dois com valor calculado no servidor a
    # partir de numero, nunca de entrada do usuario. Liberar so o atributo
    # mantem `<style>` inline bloqueado, que e o vetor que importa.
    policy.style_src_attr :unsafe_inline

    # Nenhum script de terceiro: Turbo, Stimulus e Leaflet sao servidos pelo
    # proprio app via importmap. O nonce configurado abaixo cobre o
    # <script type="importmap"> que o importmap-rails gera inline.
    policy.script_src :self

    # Turbo e o resumo de preco so falam com o proprio servidor.
    policy.connect_src :self

    # Aqui a politica e deliberadamente mais frouxa que o resto. As fotos
    # saem do Active Storage por uma URL do proprio app, que redireciona pro
    # Cloudflare R2, e o mapa puxa tiles do OpenStreetMap. Fixar esses hosts
    # significaria escrever num arquivo versionado uma infraestrutura que hoje
    # vive em credentials, e um erro ali derruba todas as fotos do site em
    # producao. `https:` ainda barra imagem em texto claro, e como script-src
    # acima nao deixa script de terceiro rodar, nao sobra quem monte uma URL
    # de exfiltracao.
    policy.img_src :self, :data, :https

    # form-action fica de fora de proposito: o pagamento e um POST no proprio
    # app que responde com redirect pro Stripe Checkout, e o Chrome valida a
    # politica tambem no destino do redirecionamento. Declarar a diretiva
    # quebraria o unico fluxo que gera receita.
  end

  # Nonce por requisicao. Sem isto o <script type="importmap"> inline e
  # bloqueado e o site fica sem JS nenhum -- nem Turbo, nem calendario, nem
  # mapa. SecureRandom em vez do id de sessao (exemplo padrao do Rails)
  # porque o visitante publico pode nao ter sessao ainda, e um nonce vazio
  # nao casa com nada.
  #
  # style-src entra na lista por causa do Turbo: ele cria em JS o <style> da
  # barra de progresso e copia o nonce da meta tag. Sem o nonce na diretiva,
  # toda navegacao geraria uma violacao de CSP no console. Nonce em style-src
  # nao anula o `self` acima -- as duas fontes valem em paralelo.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
