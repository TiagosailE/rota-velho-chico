Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :tours, only: [ :index, :show ], param: :slug

  resources :departures, only: [] do
    resources :bookings, only: [ :new, :create ]
  end

  resource :booking_lookup, only: [ :new, :create ]

  post "bookings/:code/pay", to: "checkout#create", as: :pay_booking
  get "checkout/success", to: "checkout#success", as: :checkout_success
  get "checkout/cancel", to: "checkout#cancel", as: :checkout_cancel

  post "bookings/:code/cancel", to: "booking_cancellations#create", as: :cancel_booking

  post "stripe/webhook", to: "stripe_webhooks#create"

  root "tours#index"
end
