require "rails_helper"

# Caminho feliz da reserva, de ponta a ponta: busca -> detalhe -> calendario
# -> formulario -> confirmacao com codigo (CLAUDE.md, convencoes de teste).
RSpec.describe "Reserva de um passeio", type: :system do
  it "turista navega do catalogo ate a confirmacao com codigo" do
    departure = create(:departure, starts_at: 10.days.from_now.change(hour: 9), capacity: 10, seats_taken: 0)
    tour = departure.tour

    visit tours_path
    expect(page).to have_content(tour.title)

    click_on I18n.t("tours.index.card.details"), match: :first

    expect(page).to have_content(tour.title)
    expect(page).to have_content(tour.meeting_point)

    click_on I18n.t("tours.show.book"), match: :first

    expect(page).to have_content(I18n.t("bookings.new.title"))

    fill_in I18n.t("bookings.new.customer_name"), with: "Maria Turista"
    fill_in I18n.t("bookings.new.customer_email"), with: "maria@exemplo.com"
    fill_in I18n.t("bookings.new.adults"), with: 2
    fill_in I18n.t("bookings.new.children_5_9"), with: 0
    fill_in I18n.t("bookings.new.children_0_4"), with: 0

    click_on I18n.t("bookings.new.submit")

    expect(page).to have_content(I18n.t("bookings.confirmation.title"))
    booking = Booking.last
    expect(page).to have_content(booking.code)
    expect(booking.adults).to eq(2)
    expect(departure.reload.seats_taken).to eq(2)
  end
end
