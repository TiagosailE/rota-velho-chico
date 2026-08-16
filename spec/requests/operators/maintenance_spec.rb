require "rails_helper"

# Ferramenta temporaria (ver PROGRESS.md) -- spec cobre so autenticacao e
# que o job certo e enfileirado, sem rodar o job de verdade aqui (isso e
# coberto no spec do proprio ResetDemoPhotosJob).
RSpec.describe "Operators::Maintenance", type: :request do
  include ActiveJob::TestHelper

  describe "GET /operators/maintenance/reset_photos" do
    it "redireciona para o login quando nao autenticado" do
      get operators_maintenance_reset_photos_path

      expect(response).to redirect_to(new_operator_session_path)
    end

    it "enfileira o job de reset das fotos" do
      operator = create(:operator)
      sign_in operator

      expect {
        get operators_maintenance_reset_photos_path
      }.to have_enqueued_job(ResetDemoPhotosJob)

      expect(response).to redirect_to(operators_root_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("operators.maintenance.reset_photos.success"))
    end
  end
end
