Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication routes
  get '/login', to: 'auth/sessions#new', as: :login
  post '/login', to: 'auth/sessions#create'
  delete '/logout', to: 'auth/sessions#destroy', as: :logout

  # Dashboard routes (временные заглушки для тестирования)
  get '/barista', to: 'dashboards#barista', as: :barista_dashboard
  get '/manager', to: 'dashboards#manager', as: :manager_dashboard
  get '/prep_kitchen', to: 'dashboards#prep_kitchen', as: :prep_kitchen_dashboard
  get '/admin', to: 'dashboards#admin', as: :admin_dashboard

  # Defines the root path route ("/")
  root 'auth/sessions#new'
end
