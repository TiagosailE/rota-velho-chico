class TourPhoto < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :tour

  # As variantes sao preprocessadas para a primeira visita nao pagar a conta
  # de gerar tres tamanhos -- o catalogo e a primeira tela que o turista ve.
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 200, 150 ], preprocessed: true
    attachable.variant :card,  resize_to_fill: [ 800, 600 ], preprocessed: true
    attachable.variant :hero,  resize_to_fill: [ 1600, 1000 ], preprocessed: true
  end

  validates :image, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validate :image_must_be_a_supported_type

  before_validation :assign_next_position, on: :create

  # Devolvem false quando a foto ja esta na ponta -- nao ter vizinho nao e
  # erro, e o operador clicando "subir" na primeira foto.
  def move_up!
    swap_with(tour.tour_photos.where("position < ?", position).order(position: :desc).first)
  end

  def move_down!
    swap_with(tour.tour_photos.where("position > ?", position).order(:position).first)
  end

  private

  def swap_with(neighbour)
    return false if neighbour.nil?

    transaction do
      # Adia a unicidade ate o fim do bloco: no meio da troca as duas fotos
      # ocupam a mesma position por um instante.
      self.class.connection.execute("SET CONSTRAINTS tour_photos_unique_position DEFERRED")

      neighbour_position = neighbour.position
      neighbour.update!(position: position)
      update!(position: neighbour_position)

      # Volta ao modo imediato ainda dentro da transacao, para uma eventual
      # violacao estourar aqui e nao la no commit, longe da causa.
      self.class.connection.execute("SET CONSTRAINTS tour_photos_unique_position IMMEDIATE")
    end

    true
  end

  # Sem isso o operador poderia anexar PDF ou executavel: o formulario aceita
  # o que o navegador mandar, e o accept do HTML e so uma sugestao.
  def image_must_be_a_supported_type
    return unless image.attached?
    return if ALLOWED_CONTENT_TYPES.include?(image.content_type)

    errors.add(:image, :invalid_content_type)
  end

  # Sem tour nao ha fila onde entrar: deixa position nil e o registro cai nas
  # validacoes de tour e de position, em vez de estourar num nil.tour_photos.
  def assign_next_position
    return if position.present? || tour.nil?

    self.position = (tour.tour_photos.maximum(:position) || -1) + 1
  end
end
