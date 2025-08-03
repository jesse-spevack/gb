Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Mount ActionCable server for real-time updates
  mount ActionCable.server => "/cable"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  resource :session, only: [ :new, :create, :destroy ]
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: redirect("/")

  resources :assignments, only: [ :index, :show, :new, :create, :destroy ]
  resources :assignment_summaries, only: [ :show ]
  resources :rubrics, only: [ :show ]
  resources :student_works, only: [ :show ]

  # Documentation
  get "/docs/:id", to: "docs#show", as: :doc

  # Google
  namespace :google do
    resource :credentials, only: [ :show ]
  end

  # Marketing
  root "home#index"



  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
