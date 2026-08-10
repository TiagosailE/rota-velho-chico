class CreateTourPhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :tour_photos do |t|
      t.references :tour, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :alt_text

      t.timestamps
    end

    # Existe um model proprio em vez de has_many_attached :photos direto no
    # Tour porque o Active Storage nao guarda ordem nem texto alternativo.
    # Ordem importa: a foto de position 0 e a capa do card e do hero. E o
    # alt_text importa porque a galeria seria uma regressao de acessibilidade
    # sem ele (ver o trabalho dos Dias 17-18).
    #
    # DEFERRABLE, e nao um add_index unique comum, por causa da reordenacao:
    # trocar a foto 0 com a 1 passa por um estado intermediario com duas
    # fotos na mesma position. Com :immediate a constraint continua sendo
    # checada na hora por padrao (comportamento identico ao de um indice
    # unico normal), e so a troca pede SET CONSTRAINTS ... DEFERRED para
    # adiar a checagem ate o commit. A alternativa seria mover uma das fotos
    # para uma position temporaria fora do caminho -- tres UPDATEs e um valor
    # magico, em vez de dois UPDATEs e a garantia do banco intacta.
    add_unique_constraint :tour_photos, [ :tour_id, :position ],
                          deferrable: :immediate, name: "tour_photos_unique_position"

    add_check_constraint :tour_photos, "position >= 0", name: "tour_photos_position_non_negative"
  end
end
