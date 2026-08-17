class ApplicationMailer < ActionMailer::Base
  default from: "reservas@rotavelhochico.example.com"
  layout "mailer"

  # Mailers nao herdam helpers de controller automaticamente -- sem isso,
  # format_price_cents (ToursHelper) nao existe dentro de uma view de e-mail.
  helper ToursHelper
end
