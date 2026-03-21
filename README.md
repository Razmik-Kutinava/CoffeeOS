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

* Services (job queues, cache servers, search engines, etc.)

* **Деплой (Render, Docker и т.п.):** **`SECRET_KEY_BASE`** (`bin/rails secret`) или **`RAILS_MASTER_KEY`**. **`DATABASE_URL`** — один Postgres на все конфиги (**primary**, **cache**, **queue**, **cable** для Solid Cache/Queue/Cable). Docker entrypoint делает **`db:prepare`**. При необходимости в Shell: **`bin/rails db:migrate`**. Образ слушает **`PORT`** (Puma), **без Thruster** — так ожидает Render и нет 502 из‑за прокси на localhost.

* Deployment instructions

* ...
