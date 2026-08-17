class Operator < ApplicationRecord
  # :validatable ja cobre presenca, unicidade e formato de email, por isso
  # nao ha validacao manual de email aqui. :registerable habilita o
  # autocadastro (v3, lado da oferta do marketplace) -- Operators::RegistrationsController
  # neutraliza edit/update/destroy de proposito, ainda nao construidos.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :registerable

  has_many :tours
  has_many :departures, through: :tours
  has_many :bookings, through: :tours

  before_validation :generate_slug, on: :create

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :stripe_account_id, uniqueness: true, allow_nil: true

  # Autocadastro entra como active: false (aprovacao manual, unico jeito que
  # existe hoje -- nao ha painel de admin. Operator.find_by(email:
  # "...").update!(active: true) via console). Contas semeadas continuam
  # active: true, o default do schema, sem passar por aqui.
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :pending_approval
  end

  private

  # So roda quando slug nao veio preenchido (autocadastro) -- seeds/console
  # continuam escolhendo o proprio slug, como sempre.
  def generate_slug
    return if slug.present?
    return if name.blank?

    base = name.parameterize
    candidate = base
    suffix = 1

    while Operator.exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end

    self.slug = candidate
  end
end
