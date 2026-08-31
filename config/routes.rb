Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication routes
  get "/login", to: "auth/sessions#new", as: :login
  post "/login", to: "auth/sessions#create"
  delete "/logout", to: "auth/sessions#destroy", as: :logout

  get "/payment/success", to: "payment_returns#success"
  get "/payment/fail", to: "payment_returns#fail"

  # External callbacks (payment providers / fiscal providers / SMS.ru)
  namespace :callbacks do
    post "/payments", to: "events#payment"
    post "/fiscal_receipts", to: "events#fiscal_receipt"
    post "/tbank", to: "tbank#notify"
    post "/sms_ru", to: "sms_ru#notify"
    post "/email/bounce", to: "email_bounces#bounce"
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
    post "/shifts/open", to: "shifts#create", as: :open_shift
    get "/shifts/:id", to: "shifts#show", as: :shift
    get "/shifts/:id/close", to: "close_wizard#show", as: :close_shift
    post "/shifts/:id/close", to: "close_wizard#update"

    get "/inventory", to: "inventory#index", as: :inventory
    get "/menu", to: "menu#index", as: :menu
    patch "/menu/settings/:id/price", to: "menu#update_price", as: :menu_setting_price
    get "/reports", to: "reports#index", as: :reports

    resources :staff_members, path: "staff", controller: "staff", only: %i[index new create edit update]
    get "/devices", to: "devices#index", as: :devices
    post "/devices", to: "devices#create"
    post "/devices/kiosk", to: "devices#create_kiosk", as: :devices_kiosk
    patch "/devices/:id/tv_mode", to: "devices#update_tv_mode", as: :device_tv_mode
    patch "/devices/:id/revoke", to: "devices#revoke", as: :device_revoke
    patch "/devices/:id/rotate_token", to: "devices#rotate_token", as: :device_rotate_token

    get "/incidents", to: "incidents#index", as: :incidents

    get "/tv_board_settings", to: "tv_board_settings#edit", as: :tv_board_settings
    patch "/tv_board_settings", to: "tv_board_settings#update"
  end

  # TV board (без логина) - подключение по device_token
  get "/tv_board", to: "tv_boards#show", as: :tv_board

  # Киоск (Flutter): auth по device_token → tenant; меню/заказ — /shop/api/*
  namespace :kiosk, path: "kiosk" do
    namespace :api do
      post "auth", to: "auth#create"
    end
  end

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
    get "/sales_points", to: "sales_points#index", as: :sales_points
    post "/sales_points", to: "sales_points#create"
    delete "/sales_points/:id", to: "sales_points#destroy", as: :sales_point
  end

  get "/prep_kitchen", to: redirect("/prep_kitchen/")
  # Не редиректить /admin → /admin/: это даёт бесконечный цикл со слэшем вместе с корнем namespace.
  namespace :platform, path: "admin" do
    root to: "dashboard#show"
    get "/menu", to: "menu#index", as: :menu
    post "/menu/categories", to: "menu#create_category", as: :menu_categories
    patch "/menu/categories/:id", to: "menu#update_category", as: :menu_category
    delete "/menu/categories/:id", to: "menu#destroy_category", as: :menu_category_destroy
    post "/menu/products", to: "menu#create_product", as: :menu_products
    patch "/menu/products/:id", to: "menu#update_product", as: :menu_product
    delete "/menu/products/:id", to: "menu#destroy_product", as: :menu_product_destroy
    post "/menu/modifier_groups", to: "menu#create_modifier_group", as: :menu_modifier_groups
    patch "/menu/modifier_groups/:id", to: "menu#update_modifier_group", as: :menu_modifier_group
    post "/menu/modifier_options", to: "menu#create_modifier_option", as: :menu_modifier_options
    patch "/menu/modifier_options/:id", to: "menu#update_modifier_option", as: :menu_modifier_option
    resources :organizations, only: %i[index new create edit update]
    resources :tenants, only: %i[index show new create edit update] do
      member do
        post :open_as_manager
        post :prep_kitchen_sales_point_links, to: "prep_kitchen_links#create"
        delete "prep_kitchen_sales_point_links/:sales_point_id", to: "prep_kitchen_links#destroy", as: :prep_kitchen_sales_point_link
      end
    end
    resources :franchise_owners, only: %i[new create], path: "franchise_owners"
    get "monitoring", to: "monitoring#index", as: :monitoring
    get "monitoring/:id", to: "monitoring#show", as: :monitoring_tenant
    get "monitoring/:id/events", to: "monitoring#events", as: :monitoring_tenant_events
    get "monitoring/:id/sessions", to: "tenant_sessions#show", as: :monitoring_tenant_sessions
    get "monitoring/:id/transactions", to: "tenant_transactions#show", as: :monitoring_tenant_transactions
    get "session", to: "session#show", as: :session
  end
  # Редирект /admin/ → /admin через get "/admin/" в Rails даёт второй маршрут на тот же GET /admin и цикл 301.
  # Корень platform уже обслуживает и /admin, и /admin/ (без отдельного redirect).

  # Health API — мониторинг точек для центральной админки (JSON)
  namespace :health do
    resources :tenants, only: [ :index, :show ] do
      member do
        get :events
        get :transactions
      end
    end
  end

  # Barista namespace
  namespace :barista do
    get "/", to: "dashboard#index", as: :dashboard
    get "/orders/history", to: "orders#history", as: :orders_history
    get "/create-order", to: "orders#new", as: :new_order
    post "/orders", to: "orders#create"
    get "/menu", to: "menu#index", as: :menu
    get "/reports", to: "reports#index", as: :reports
    resources :orders, only: [ :show ] do
      member do
        patch :update_status
        post :cancel
      end
    end
    get "/shift", to: "shifts#show", as: :shift
    post "/shift/open", to: "shifts#create", as: :open_shift
  end

  # Публичный блог
  namespace :blog do
    root "home#index"
    get "categories/:slug", to: "categories#show", as: :category
    resources :posts, param: :slug, only: %i[show new create edit update destroy]
    resource :session, only: %i[create destroy], controller: "sessions"
  end

  # Витрина (Svelte SPA, данные точки — ProductTenantSetting, заказы — mobile + orders)
  get "/firebase-messaging-sw.js", to: "shop/firebase_sw#show", defaults: { format: :js }

  namespace :shop, path: "shop" do
    get "manifest.webmanifest", to: "pwa#manifest", defaults: { format: :json }
    get "service-worker.js", to: "pwa#service_worker", defaults: { format: :js }
    root to: "pages#home"
    namespace :api do
      get "config", to: "config#show"
      get "tenants", to: "tenants#index"
      post "push/register", to: "push#register"
      get "debug", to: "debug#index" unless Rails.env.production?
      get "categories", to: "categories#index"
      get "frequent_products", to: "frequent_products#index"
      get "products", to: "products#index"
      get "products/:id", to: "products#show"
      post "cart/add", to: "cart#add"
      get "cart", to: "cart#show"
      delete "cart", to: "cart#clear"
      delete "cart/items/:index", to: "cart#destroy"
      patch "cart/items/:index", to: "cart#update"
      post "email_otp/send", to: "email_otp#send_code"
      post "email_otp/verify", to: "email_otp#verify"
      get "email_otp/status", to: "email_otp#status"
      post "phone_otp/init_callcheck", to: "phone_otp#init_callcheck"
      get "phone_otp/check_status", to: "phone_otp#check_status"
      post "phone_otp/send_sms", to: "phone_otp#send_sms"
      post "phone_otp/verify_sms", to: "phone_otp#verify_sms"
      # Legacy Profile link (SMS only)
      post "phone_otp/send", to: "phone_otp#send_code"
      post "phone_otp/verify", to: "phone_otp#verify"
      get "phone_otp/status", to: "phone_otp#status"
      post "orders", to: "orders#create"
      post "payments/new_card", to: "payments#new_card"
      post "payments/one_click", to: "payments#one_click"
      post "payments/sbp/init", to: "payments#sbp_init"
      post "payments/sbp/charge", to: "payments#sbp_charge"
      post "payments/widget_init", to: "payments#widget_init"
      get "payments/status/:order_id", to: "payments#status"
      get "payments/card_config", to: "payments#card_config"
      get "user/cards", to: "user_cards#index"
      get "orders/history", to: "orders#history"
      get "orders/active", to: "orders#active"
      post "session/reconnect", to: "session#reconnect"
      post "session/refresh", to: "session#refresh"
      delete "session", to: "session#destroy"
      post "orders/:id/abandon", to: "orders#abandon"
      post "orders/:id/cancel", to: "orders#cancel"
      post "orders/:id/finalize", to: "orders#finalize"
      get "orders/:id/wallet_pass", to: "orders#wallet_pass"
      get "orders/:id", to: "orders#show"
      post "orders/:order_id/email", to: "orders/email#create"
      post "promo_codes/apply", to: "promo_codes#apply"
      get "profile", to: "profile#show"
      patch "profile", to: "profile#update"
      post "profile/link_email", to: "profile#link_email"
      post "profile/link_phone", to: "profile#link_phone"
      get "favorites", to: "favorites#index"
      post "favorites", to: "favorites#create"
      delete "favorites/:product_id", to: "favorites#destroy"
    end
    # SPA hash-routes иногда попадают на сервер как /shop/... — отдаём shell витрины
    get "*spa_path", to: "pages#home", constraints: ->(req) { req.format.html? }
  end

  # Defines the root path route ("/")
  root "auth/sessions#new"

  if Rails.env.local?
    namespace :test do
      get "slow_page", to: "slow_queries#page"
      get "slow_json", to: "slow_queries#json"
    end
  end
end
