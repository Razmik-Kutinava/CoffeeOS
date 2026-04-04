# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* **Дымовые проверки:** `bin/rails smoke` или `bin/smoke` — полный прогон тестов; `bin/smoke ci` — как в CI (тесты + RuboCop + security). Подробнее: [docs/features/SMOKE_CHECKS.md](docs/features/SMOKE_CHECKS.md).

* **Два входа (франчайзи `/manager/` и УК `/admin/`):** после `bin/rails db:migrate` выполнить `bin/rails test:create_test_users`, затем логин `franchise@test.com` или `uk@test.com` (пароль в выводе rake, обычно `test123456`). Подробнее: [docs/features/ADMIN_PANELS_LOGIN.md](docs/features/ADMIN_PANELS_LOGIN.md).

* **WSL + репозиторий на `/mnt/c/...` (диск Windows):** drvfs ломает `./vendor/bundle` — после «успешного» `bundle install` команды вроде `bin/rails` пишут *Could not find rails…*. Используйте **`./bin/bundle install`** (и дальше **`./bin/bundle exec …`** при необходимости): гемы ставятся в **`~/.local/share/coffeeos-vendor/…`** на ext4 (см. `config/bundle_env.rb`). Либо клонируйте проект в **`~/projects/CoffeeOS`** — тогда снова используется `./vendor/bundle` и обычный `bundle install` ОК.

* **Версии Ruby/Node (mise):** в корне есть `mise.toml` (Ruby **3.4.8**, Node **20**). Команда **`mise install`** подтянет те же версии, что и `.ruby-version`, без путаницы rbenv/системный Ruby.

* **Прочие среды:** в `.bundle/config` по-прежнему `BUNDLE_PATH: vendor/bundle` для CI и клонов на нативном диске. `config/boot.rb` задаёт те же пути через `AppBundleEnv`.

* **Запуск:** **`./bin/server`** — только Rails (логин, manager, barista и т.д.), без Vite. **`./bin/dev`** — витрина **`/shop`**: Rails :3000 + Vite (HMR). **`./bin/dev --rails-only`** — то же, что `bin/server` на порту 3000. После **`npm run vite:build`** витрина может открываться и без живого Vite (статические ассеты).

* **Витрина `/shop` (Svelte из coffee-shop):** в `.env` задайте `SHOP_DEFAULT_TENANT_ID=<uuid точки>` (или откройте `/shop?tenant_id=...`). У точки должны быть `ProductTenantSetting` и активные продукты. В WSL при разработке витрины: **`npm install`** в корне проекта.

* Services (job queues, cache servers, search engines, etc.)

* **Деплой (Render, Docker и т.п.):** **`SECRET_KEY_BASE`** (`bin/rails secret`) или **`RAILS_MASTER_KEY`**. **`DATABASE_URL`** — один Postgres на все конфиги (**primary**, **cache**, **queue**, **cable** для Solid Cache/Queue/Cable). Docker entrypoint делает **`db:prepare`**. При необходимости в Shell: **`bin/rails db:migrate`**. Образ слушает **`PORT`** (Puma), **без Thruster** — так ожидает Render и нет 502 из‑за прокси на localhost.

* Deployment instructions

* ...
