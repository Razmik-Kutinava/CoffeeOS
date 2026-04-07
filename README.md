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

* **Ревью кода:** когда делать самопроверку, как вызвать `@coffeeos-code-review` в Cursor и что прогнать перед PR — [docs/REVIEW.md](docs/REVIEW.md). При открытии PR GitHub подставляет чеклист из `.github/pull_request_template.md`.

* **Два входа (франчайзи `/manager/` и УК `/admin/`):** после `bin/rails db:migrate` выполнить `bin/rails test:create_test_users`, затем логин `franchise@test.com` или `uk@test.com` (пароль в выводе rake, обычно `test123456`). **Параллельные разные пользователи в разных вкладках:** разные поддомены `*.localhost` или `127.0.0.1` vs `localhost` — иначе сессия одна на хост. Подробнее: [docs/features/ADMIN_PANELS_LOGIN.md](docs/features/ADMIN_PANELS_LOGIN.md).

* **WSL + репозиторий на `/mnt/c/...` (диск Windows):** drvfs ломает `./vendor/bundle` — после «успешного» `bundle install` команды вроде `bin/rails` пишут *Could not find rails…*. Используйте **`./bin/bundle install`** (и дальше **`./bin/bundle exec …`** при необходимости): гемы ставятся в **`~/.local/share/coffeeos-vendor/…`** на ext4 (см. `config/bundle_env.rb`). Либо клонируйте проект в **`~/projects/CoffeeOS`** — тогда снова используется `./vendor/bundle` и обычный `bundle install` ОК.

* **Версии Ruby/Node (mise):** в корне есть `mise.toml` (Ruby **3.4.8**, Node **20**). Команда **`mise install`** подтянет те же версии, что и `.ruby-version`, без путаницы rbenv/системный Ruby.

* **Прочие среды:** в `.bundle/config` по-прежнему `BUNDLE_PATH: vendor/bundle` для CI и клонов на нативном диске. `config/boot.rb` задаёт те же пути через `AppBundleEnv`.

* **Запуск:** **`./bin/server`** — только Rails (логин, manager, barista и т.д.), без Vite, по умолчанию **порт 3001** (`config/puma.rb` — на 3000 часто `EADDRINUSE`). Нужен именно 3000: `PORT=3000 ./bin/server`. **`./bin/dev`** — витрина **`/shop`**: Rails **:3001** + Vite (HMR). **`./bin/dev --rails-only`** — как `bin/server`. После **`npm run vite:build`** витрина может открываться и без живого Vite (статические ассеты). Открывай **`http://127.0.0.1:3001`** (не 3000).

* **УК — меню, витрина, каталог (что менялось):** см. [doc/features/PLATFORM_MENU_AND_VITRINA.md](doc/features/PLATFORM_MENU_AND_VITRINA.md).

* **Витрина `/shop` (Svelte из coffee-shop):** API отдаёт только товары с **`ProductTenantSetting`** для выбранной точки, где **`is_enabled`** и не **`is_sold_out`** (см. `Shop::Catalog.products_scope`). Иначе категории/товары пустые. После `db:migrate` в development/test выполните **`bin/rails db:seed`** — поднимется **рабочий каталог CoffeeOS** для точки **`test-cafe`** (`db/seeds_shop_catalog.rb`, slug `menu-cat-*` / `menu-prod-*`). Чтобы **снести старые демо-заказы и старый каталог** (латте/капучино, seeds barista, import-cs, устаревшие `cb-*`) и заново залить каталог: **`bin/rails catalog:replace`** (опционально `CATALOG_TENANT_SLUG=...`; устаревшее имя: `CODEBLACK_TENANT_SLUG`, задача `codeblack:replace_catalog`). В `.env` можно задать `SHOP_DEFAULT_TENANT_ID=<uuid>` или открыть `/shop?tenant_id=...`. В development без `.env` подставляется **`test-cafe`**, если такая точка есть. Для кнопки «Написать в Telegram» на карточке товара задайте **`VITE_SHOP_TELEGRAM_URL`** (полный URL, например `https://t.me/your_channel`). В WSL: **`npm install`** в корне проекта.

* **Импорт каталога из БД coffee-shop:** `COFFEE_SHOP_DATABASE_URL=...` и `COFFEE_SHOP_IMPORT_TENANT_ID=<uuid>` (или тот же `SHOP_DEFAULT_TENANT_ID`), затем **`bin/rails coffee_shop:import_catalog`**. Подробности и маппинг полей — комментарий в начале `lib/tasks/coffee_shop_import.rake`; для проверки без записи: `COFFEE_SHOP_IMPORT_DRY_RUN=1`. Откат только импортных slug: **`bin/rails coffee_shop:rollback_import`** (при блокировке заказами — сначала убрать позиции).

* Services (job queues, cache servers, search engines, etc.)

* **Деплой (Render, Docker и т.п.):** **`SECRET_KEY_BASE`** (`bin/rails secret`) или **`RAILS_MASTER_KEY`**. **`DATABASE_URL`** — один Postgres на все конфиги (**primary**, **cache**, **queue**, **cable** для Solid Cache/Queue/Cable). Docker entrypoint делает **`db:prepare`**. При необходимости в Shell: **`bin/rails db:migrate`**. Образ слушает **`PORT`** (Puma), **без Thruster** — так ожидает Render и нет 502 из‑за прокси на localhost.

* Deployment instructions

* ...
