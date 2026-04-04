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

  # External callbacks (payment providers / fiscal providers)
  namespace :callbacks do
    post "/payments", to: "events#payment"
    post "/fiscal_receipts", to: "events#fiscal_receipt"
  end

  # Dashboard routes (временные заглушки для тестирования)
  # Manager (office/shift) dashboard
  namespace :manager do
    get "/", to: "dashboard#show", as: :dashboard

    post "/switch_tenant", to: "tenant_context#update", as: :switch_tenant

    get "/orders", to: "orders#index", as: :orders
    get "/orders/:id", to: "orders#show", as: :order

    namespace :finance do
      get "/payments", to: "payments#index", as: :payments
      get "/refunds", to: "refunds#index", as: :refunds
      get "/fiscal_receipts", to: "fiscal_receipts#index", as: :fiscal_receipts
    end

    get "/shifts", to: "shifts#index", as: :shifts
    get "/shifts/:id", to: "shifts#show", as: :shift
    get "/shifts/:id/close", to: "close_wizard#show", as: :close_shift
    post "/shifts/:id/close", to: "close_wizard#update"

    get "/inventory", to: "inventory#index", as: :inventory
    get "/menu", to: "menu#index", as: :menu
    get "/reports", to: "reports#index", as: :reports

    resources :staff_members, path: "staff", controller: "staff", only: %i[index new create edit update]
    get "/devices", to: "devices#index", as: :devices
    post "/devices", to: "devices#create"
    patch "/devices/:id/tv_mode", to: "devices#update_tv_mode", as: :device_tv_mode

    get "/incidents", to: "incidents#index", as: :incidents

    get "/tv_board_settings", to: "tv_board_settings#edit", as: :tv_board_settings
    patch "/tv_board_settings", to: "tv_board_settings#update"
  end

  # TV board (без логина) - подключение по device_token
  get "/tv_board", to: "tv_boards#show", as: :tv_board

  get "/manager", to: redirect("/manager/")
  namespace :prep_kitchen do
    get "/", to: "dashboard#show", as: :dashboard
    get "/queue", to: "queue#index", as: :queue
    get "/recipes", to: "recipes#index", as: :recipes
    get "/inventory", to: "inventory#index", as: :inventory
    patch "/inventory/:id/min_qty", to: "inventory#update_min_qty", as: :inventory_min_qty
    get "/movements", to: "movements#index", as: :movements
    get "/movements/new", to: "movements#new", as: :new_movement
    post "/movements", to: "movements#create"
    post "/movements/:id/confirm", to: "movements#confirm", as: :confirm_movement
    post "/movements/:id/cancel", to: "movements#cancel", as: :cancel_movement
    get "/stop_list", to: "stop_list#index", as: :stop_list
    patch "/stop_list/:id", to: "stop_list#update", as: :stop_list_item
    get "/incidents", to: "incidents#index", as: :incidents
    get "/reports", to: "reports#index", as: :reports
  end

  get "/prep_kitchen", to: redirect("/prep_kitchen/")
  # Не редиректить /admin → /admin/: это даёт бесконечный цикл со слэшем вместе с корнем namespace.
  namespace :platform, path: "admin" do
    root to: "dashboard#show"
    resources :organizations, only: %i[index new create edit update]
    resources :tenants, only: %i[index new create edit update] do
      member do
        post :open_as_manager
      end
    end
    resources :franchise_owners, only: %i[new create], path: "franchise_owners"
  end
  # Редирект /admin/ → /admin через get "/admin/" в Rails даёт второй маршрут на тот же GET /admin и цикл 301.
  # Корень platform уже обслуживает и /admin, и /admin/ (без отдельного redirect).

  # Health API — мониторинг точек для центральной админки (JSON)
  namespace :health do
    resources :tenants, only: [:index, :show]
  end

  # Barista namespace
  namespace :barista do
    get '/', to: 'dashboard#index', as: :dashboard
    get '/orders/history', to: 'orders#history', as: :orders_history
    get '/create-order', to: 'orders#new', as: :new_order
    post '/orders', to: 'orders#create'
    get '/menu', to: 'menu#index', as: :menu
    get '/reports', to: 'reports#index', as: :reports
    resources :orders, only: [:show] do
      member do
        patch :update_status
        post :cancel
      end
    end
    get '/shift', to: 'shifts#show', as: :shift
  end

  # Витрина (Svelte SPA, данные точки — ProductTenantSetting, заказы — mobile + orders)
  namespace :shop, path: "shop" do
    root to: "pages#home"
    namespace :api do
      get "categories", to: "categories#index"
      get "products", to: "products#index"
      get "products/:id", to: "products#show"
      post "cart/add", to: "cart#add"
      get "cart", to: "cart#show"
      delete "cart/items/:index", to: "cart#destroy"
      patch "cart/items/:index", to: "cart#update"
      post "orders", to: "orders#create"
      get "orders/history", to: "orders#history"
      get "orders/:id", to: "orders#show"
      post "promo_codes/apply", to: "promo_codes#apply"
      get "profile", to: "profile#show"
      get "favorites", to: "favorites#index"
      post "favorites", to: "favorites#create"
      delete "favorites/:product_id", to: "favorites#destroy"
    end
  end

  # Defines the root path route ("/")
  root 'auth/sessions#new'
end
