class Operator < ApplicationRecord
  # Sem :registerable -- contas sao semeadas, sem cadastro publico de
  # operador no MVP (CLAUDE.md). :validatable ja cobre presenca, unicidade
  # e formato de email, por isso nao ha validacao manual de email aqui.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :tours

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
