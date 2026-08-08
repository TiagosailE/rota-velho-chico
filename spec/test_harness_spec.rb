# frozen_string_literal: true

require "rails_helper"

# Guarda-corpo do proprio arranjo de testes.
#
# Os pre-requisitos do spec de overbooking (docs/architecture.md secao 5) falham
# de formas que apontam para o BookingCreator quando o problema esta no setup.
# Este spec faz cada um deles falhar aqui, de forma obvia, antes de virar uma
# caca ao fantasma la.
RSpec.describe "Arranjo da suite de testes" do
  it "envolve os exemplos comuns numa transacao" do
    expect(self.class.use_transactional_tests).to be(true)
  end

  it "tem pool de conexoes com folga para as 20 threads do spec de overbooking" do
    expect(ActiveRecord::Base.connection_pool.size).to be >= 25
  end

  describe "exemplos marcados com :concurrency", :concurrency do
    it "rodam sem a transacao envolvente" do
      expect(self.class.use_transactional_tests).to be(false)
    end

    it "executam todos os blocos e devolvem os retornos em ordem" do
      expect(run_concurrently(8) { |index, _connection| index * 2 })
        .to eq([ 0, 2, 4, 6, 8, 10, 12, 14 ])
    end

    it "devolvem as conexoes ao pool" do
      run_concurrently(8) { |_index, connection| connection.select_value("select 1") }

      expect(ActiveRecord::Base.connection_pool.stat[:busy]).to be <= 1
    end
  end
end
