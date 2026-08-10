require "rails_helper"

RSpec.describe "Locale switching", type: :request do
  it "usa pt-BR por padrao, sem locale na URL do link do passeio" do
    tour = create(:tour)

    get tours_path

    expect(response.body).to include(I18n.t("tours.index.title", locale: :"pt-BR"))
    expect(response.body).to include(%(href="#{tour_path(tour.slug)}"))
  end

  it "troca para ingles via parametro de URL e propaga o locale nos links" do
    tour = create(:tour)

    get tours_path(locale: "en")

    expect(response.body).to include(I18n.t("tours.index.title", locale: :en))
    expect(response.body).to include(tour_path(tour.slug, locale: "en"))
  end

  it "cai para pt-BR quando o locale da URL e invalido" do
    get tours_path(locale: "fr")

    expect(response.body).to include(I18n.t("tours.index.title", locale: :"pt-BR"))
  end
end
