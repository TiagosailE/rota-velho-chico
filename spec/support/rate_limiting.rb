# frozen_string_literal: true

# O contador do `rate_limit` vive numa store de cache com escopo de processo
# (config/environments/test.rb), entao ele atravessa exemplos: um spec que
# faz varios POST no mesmo endpoint deixaria o proximo comecando ja perto do
# limite, e a suite falharia em ordem aleatoria por um motivo que nao tem
# nada a ver com o teste. Zerar antes de cada exemplo isola os contadores.
RSpec.configure do |config|
  config.before do
    ActionController::Base.cache_store.clear
  end
end
