class AddCoordinatesToTours < ActiveRecord::Migration[8.1]
  def change
    # Nullable de proposito: passeio existente nao ganha coordenada sozinho,
    # e um operador criando um passeio novo nao e obrigado a preencher --
    # a view so mostra o mapa quando os dois estao presentes.
    add_column :tours, :lat, :decimal, precision: 10, scale: 6
    add_column :tours, :lng, :decimal, precision: 10, scale: 6

    add_check_constraint :tours, "lat IS NULL OR lat BETWEEN -90 AND 90", name: "tours_lat_valid_range"
    add_check_constraint :tours, "lng IS NULL OR lng BETWEEN -180 AND 180", name: "tours_lng_valid_range"
  end
end
