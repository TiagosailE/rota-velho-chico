# Ruby puro (Prawn), sem ActiveRecord alem da leitura das bookings -- mesmo
# espirito do PriceCalculator/RefundPolicy: nao e regra de negocio, mas
# tambem nao pertence ao controller nem a view.
class DepartureManifestPdf
  def initialize(departure)
    @departure = departure
    @bookings = departure.bookings.where(status: [ :pending, :confirmed ]).order(:customer_name)
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 40) do |pdf|
      pdf.text @departure.tour.title, size: 18, style: :bold
      pdf.text @departure.starts_at.strftime("%d/%m/%Y %H:%M"), size: 12
      pdf.text @departure.tour.meeting_point, size: 10, color: "666666"
      pdf.move_down 12
      pdf.text I18n.t("operators.departures.manifest.total_passengers", count: total_passengers), size: 10, style: :bold
      pdf.move_down 8

      # Larguras explicitas -- sem isso o prawn-table divide o espaco
      # igualmente entre as 7 colunas, e "Nome"/"Telefone" ficam estreitos
      # demais pra um nome ou telefone real sem quebrar no meio da palavra.
      pdf.table(table_rows, header: true, column_widths: [ 55, 125, 95, 50, 55, 55, 75 ]) do
        row(0).font_style = :bold
        row(0).background_color = "EEEEEE"
        cells.padding = 6
        cells.size = 9
      end
    end.render
  end

  private

  def total_passengers
    @bookings.sum { |booking| booking.adults + booking.children_5_9 + booking.children_0_4 }
  end

  def table_rows
    header = [
      I18n.t("operators.departures.show.code"),
      I18n.t("bookings.new.customer_name"),
      I18n.t("operators.departures.manifest.phone"),
      I18n.t("bookings.new.adults"),
      I18n.t("operators.departures.manifest.children_5_9"),
      I18n.t("operators.departures.manifest.children_0_4"),
      I18n.t("bookings.confirmation.status")
    ]

    rows = @bookings.map do |booking|
      [
        booking.code,
        booking.customer_name,
        booking.customer_phone.presence || I18n.t("operators.departures.manifest.phone_missing"),
        booking.adults.to_s,
        booking.children_5_9.to_s,
        booking.children_0_4.to_s,
        I18n.t("bookings.confirmation.status_#{booking.status}")
      ]
    end

    [ header ] + rows
  end
end
