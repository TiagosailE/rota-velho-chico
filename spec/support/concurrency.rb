# frozen_string_literal: true

# Suporte aos specs de concorrencia (prevencao de overbooking).
#
# Um spec marcado com `:concurrency` dispara threads REAIS contra o Postgres.
# Isso conflita com o setup padrao do RSpec de tres formas, todas descritas em
# docs/architecture.md secao 5. Duas sao resolvidas aqui; a terceira (pool de
# conexoes maior que o numero de threads) esta em config/database.yml.

module ConcurrencyHelper
  # Roda o bloco em `count` threads simultaneas e devolve os retornos na ordem
  # das threads.
  #
  # Duas coisas que o teste precisa e que um `Thread.new` solto nao da:
  #
  #   * Cada thread pega uma conexao do pool via `with_connection` e a devolve
  #     no fim. Sem isso o pool vaza e os exemplos seguintes travam.
  #   * Uma barreira segura todas as threads ate a ultima estar pronta. Sem ela
  #     as threads arrancam escalonadas, a disputa real quase nao acontece e o
  #     teste passa mesmo com o lock quebrado -- um falso verde, que e pior que
  #     um vermelho.
  #
  # O bloco recebe (indice, conexao); ignore o que nao usar.
  #
  #   results = run_concurrently(20) { BookingCreator.new(...).call }
  #
  # Excecao levantada numa thread sobe aqui, via Thread#value.
  def run_concurrently(count)
    gate = Queue.new

    threads = Array.new(count) do |index|
      Thread.new do
        gate.pop # espera a largada
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          yield(index, connection)
        end
      end
    end

    count.times { gate << :go } # larga todas de uma vez
    threads.map(&:value)
  end
end

RSpec.configure do |config|
  # 1. TRANSACAO ENVOLVENTE. Com `use_transactional_fixtures`, o exemplo roda
  #    dentro de uma transacao que nunca commita. Cada thread pega a propria
  #    conexao e portanto NAO enxerga os dados criados pelo teste -- as threads
  #    quebram por registro inexistente, nao por overbooking. O sintoma nao
  #    parece o problema.
  #
  #    `prepend_before` e obrigatorio: ele roda antes do hook do rspec-rails
  #    que abre a transacao, que e o unico instante em que mudar a flag ainda
  #    surte efeito.
  config.prepend_before(:each, :concurrency) do
    self.class.use_transactional_tests = false
  end

  # 2. LIMPEZA. Sem transacao, nada e revertido sozinho.
  config.after(:each, :concurrency) do
    connection = ActiveRecord::Base.connection
    tables = connection.tables - %w[schema_migrations ar_internal_metadata]
    connection.truncate_tables(*tables) if tables.any?
  end

  config.include ConcurrencyHelper, :concurrency
end
