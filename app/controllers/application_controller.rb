class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  # Operator e o unico model Devise -- turista nao tem login (NOTES.md).
  def after_sign_in_path_for(_resource)
    operators_root_path
  end

  # Locale por parametro de URL, com fallback para pt-BR (architecture.md,
  # secao 7). default_url_options propaga o locale atual nos links gerados,
  # mas so quando difere do padrao -- URL fica limpa em pt-BR.
  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  private

  def switch_locale(&action)
    locale = params[:locale]
    locale = I18n.default_locale unless I18n.available_locales.map(&:to_s).include?(locale)
    I18n.with_locale(locale, &action)
  end
end
