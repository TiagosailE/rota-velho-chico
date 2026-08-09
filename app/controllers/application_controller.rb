class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Operator e o unico model Devise -- turista nao tem login (CLAUDE.md).
  def after_sign_in_path_for(_resource)
    operators_root_path
  end
end
