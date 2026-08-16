require "rails_helper"

# Ferramenta temporaria (ver PROGRESS.md) -- spec cobre so autenticacao e
# que os dois passos certos rodam, sem reexecutar db/seeds.rb de verdade
# aqui (isso e responsabilidade do proprio seeds, nao desta rota).
RSpec.describe "Operators::Maintenance", type: :request do
  describe "GET /operators/maintenance/reset_photos" do
    it "redireciona para o login quando nao autenticado" do
      get operators_maintenance_reset_photos_path

      expect(response).to redirect_to(new_operator_session_path)
    end

    it "apaga as fotos existentes e roda as seeds de novo" do
      operator = create(:operator)
      tour = create(:tour, operator:)
      create(:tour_photo, tour:)
      sign_in operator

      allow(Rails.application).to receive(:load_seed)

      get operators_maintenance_reset_photos_path

      expect(TourPhoto.count).to eq(0)
      expect(Rails.application).to have_received(:load_seed)
      expect(response).to redirect_to(operators_root_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("operators.maintenance.reset_photos.success"))
    end
  end
end
