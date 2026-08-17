Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  devise_for :operators, skip: [ :registrations ]

  # Plural para nao colidir com a constante do model Operator -- um
  # namespace :operator geraria controllers no modulo Operator::, que o
  # Zeitwerk nao consegue distinguir da classe do model.
  namespace :operators do
    root to: "tours#index"
    resources :tours, only: [ :index, :new, :create, :edit, :update ] do
      resources :departures, only: [ :new, :create, :show, :edit, :update, :destroy ]
      resources :photos, only: [ :create, :update, :destroy ], controller: "tour_photos" do
        member do
          patch :move_up
          patch :move_down
        end
      end
    end

    # Ferramenta temporaria, uso unico: recria as fotos das seeds depois da
    # migracao pro Cloudflare R2, sem precisar de Shell (recurso pago no
    # Render). Remover depois de usada -- ver PROGRESS.md.
    get "maintenance/reset_photos", to: "maintenance#reset_photos"

    # Ferramenta temporaria, uso unico: corrige a acentuacao de operadores/
    # passeios/fotos ja publicados no Render (db:seed nao atualiza registro
    # existente). Sem Shell no free tier -- mesma razao da rota acima.
    # Remover depois de usada -- ver PROGRESS.md.
    get "maintenance/fix_accents", to: "maintenance#fix_accents"
  end

  resources :tours, only: [ :index, :show ], param: :slug

  get "agencias/:slug", to: "operator_profiles#show", as: :operator_profile

  resources :departures, only: [] do
    resources :bookings, only: [ :new, :create ]
  end

  get "bookings/confirmation", to: "bookings#confirmation", as: :booking_confirmation

  resource :booking_lookup, only: [ :new, :create ]

  post "bookings/:code/pay", to: "checkout#create", as: :pay_booking
  get "checkout/success", to: "checkout#success", as: :checkout_success
  get "checkout/cancel", to: "checkout#cancel", as: :checkout_cancel

  post "bookings/:code/cancel", to: "booking_cancellations#create", as: :cancel_booking
  post "bookings/:code/review", to: "reviews#create", as: :review_booking

  post "stripe/webhook", to: "stripe_webhooks#create"

  root "tours#index"
end
