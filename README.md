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

* **Деплой (Render, Docker и т.п.):** в переменных окружения обязательно задать **`SECRET_KEY_BASE`** (локально: `bin/rails secret`, вставить длинную строку в панели сервиса). Альтернатива — **`RAILS_MASTER_KEY`** из `config/master.key`, тогда ключ возьмётся из `credentials`. Плюс **`DATABASE_URL`** на managed Postgres. После деплоя: миграции (`bin/rails db:migrate` в Release Command или Shell).

* Deployment instructions

* ...
