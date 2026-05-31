# Системная архитектура CoffeeOS

⚠️ **Веха 1 реализована (2026-05-24). Веха 2 — блок «как в коде» ниже.** Общая архитектура — далее; при расхождении с `development_roadmap.md` — приоритет у roadmap.

## Веха 1 — как в коде (демо)

| Слой | Реализация |
|------|------------|
| Backend | Rails 8.1.2 монолит; бизнес-логика в `app/services/{barista,shop,prep_kitchen,platform,callbacks}/` |
| Панели | Rails + Hotwire: `platform`, `manager`, `barista`, `prep_kitchen` |
| Shop | Svelte + Vite; Rails отдаёт layout + API; статика после `vite:build` |
| Auth панелей | Session (`POST /login`); Pundit policies |
| Shop API | `X-Shop-Api-Key`; для same-origin `/shop` — CSRF session (`shop_api_auth`) |
| Tenant | `Current.tenant_id` + `SET LOCAL app.current_tenant_id` (+ `app.current_user_id`) |
| RLS | Политики из миграций (не генерируются при онбординге) |
| Заказы shop | `Shop::OrderCreator` — без `cash_shift_id` |
| Заказы barista | `Barista::OrderCreationService` — требует `CashShift.open` |
| Склад | `Inventory::OrderRecipeDeduction` + PG-триггер на `accepted`; prep_kitchen `MovementCreator/Confirmer` |
| Онбординг | `Platform::TenantOnboarding::Provision` в транзакции |
| Demo | `Demo::EnvironmentSetup`, `demo:seed` |
| Очереди | Solid Queue (PostgreSQL) |
| Локальный dev | `bin/ensure-server`, `lib/port_killer.rb` (кросс-платформенный порт) |

**Не в архитектуре В1:** offline-буфер POS, Flutter, Redis, полный event log склада, payment gateway.

## Веха 2 — как в коде (2026-05)

| Слой | Реализация |
|------|------------|
| Онбординг | `Platform::TenantOnboarding::{Provision, CatalogBootstrap, UrlBuilder}`; карточка входов; org → точки → staff |
| URL витрины | `UrlBuilder.shop_url_for` — режим A (поддомен) / B (`?tenant_id=` на Fly) |
| Оплата | `Payments::TbankAdapter` → Init API; `Shop::OrderCreator` → `payment_url`; `Callbacks::TbankController` → enqueue |
| Async callback | `Payments::TbankCallbackJob` (Solid Queue, retry x5); worker `bin/jobs` на Fly |
| Надёжность | Circuit Breaker в адаптере; idempotency callback (`Rails.cache` / Redis на prod) |
| Shop / kiosk API | `Shop::Api::*` — `skip_forgery_protection` + `X-Shop-Api-Key` / tenant header; kiosk — `ActionController::API` |
| Kiosk auth | `POST /kiosk/api/auth` — `device_token` → `tenant_id` для shop API |
| Live UI | Solid Cable + Turbo Streams на barista POS (табло без F5) |
| Feature flags | Проверка модулей tenant в base controllers панелей |
| Смена | Гибрид В1 сохранён; CloseWizard — информационный блок pending online |

**Не в архитектуре В2:** IndexedDB offline-буфер, Flutter-клиент, единая смена на всех каналах, Read Replicas.

---

Архитектурная парадигма
Система строится на принципе «Smart Application, Reliable Storage». Мы сознательно отказываемся от концепции Thick Database (логика в SQL/триггерах) в пользу гибкости бэкенда на Ruby on Rails.

Backend (RoR): Единственный источник правды для бизнес-логики.

Database (PostgreSQL): Транзакционное хранилище с обеспечением физической целостности и изоляции данных (RLS). Политики RLS уже есть в базе один раз. При онбординге в транзакции создаются только данные (организация, точка, пользователи), а не создание новых Postgres-политик на каждый клиент.

Frontend (Гибридный): Витрина/Shop (app/frontend) на Svelte; мобильное приложение клиента и киоск самообслуживания — Flutter (Веха 2+). Все остальные экраны (внутренние операционные панели): Управляющая компания (platform/УК), владелец франшизы/организации, управляющий точки, менеджер смены, терминал/панель бариста (POS), заготовочный цех / prep‑kitchen и кухня, входы работника цеха и работника смены — только Rails + Hotwire с поддержкой оффлайн-режима в будущих вехах.

Технологический стек
Язык и фреймворк: Ruby 3.3+, Rails 8.1.2 (строго согласно Gemfile).

База данных: PostgreSQL 16+.

Кэширование и очереди: Solid Queue (использование основной БД PostgreSQL для хранения очередей, без внедрения Redis/Sidekiq на текущем этапе).

Клиентская часть: Svelte для витрины; Rails + Hotwire для всего списка операционных панелей; Flutter для мобильных приложений и киоска (Веха 2+).

Инфраструктура: Docker, PgBouncer (для управления пулом соединений при масштабировании).

Слой данных и Безопасность (Multi-tenancy)
Изоляция данных кофейных сетей реализуется через Row Level Security (RLS) в PostgreSQL. Политики RLS внедряются в миграциях один раз для всех таблиц, динамическое создание политик под новых клиентов при онбординге запрещено.

Tenant Identity: Каждый запрос от клиента привязывается к тенанту (определяется через поддомен или текущую сессию в Current.tenant).

Session Binding: При каждом обращении к БД Rails-сервис устанавливает SET local app.current_tenant_id = '...'.

RLS Policies: Все таблицы, содержащие данные клиентов (заказы, склад, персонал), имеют политику, проверяющую соответствие поля tenant_id значению из app.current_tenant_id.

Audit: Все деструктивные действия логируются в системную таблицу admin_audit_logs вне зависимости от политик RLS.

Offline-first и Синхронизация
Для обеспечения непрерывности бизнеса в QSR, архитектура поддерживает асинхронное взаимодействие.

Client-Side Storage: Начиная с Вехи 2, Rails+Hotwire POS использует IndexedDB для офлайн-буфера заказов. Flutter-приложение — Drift/Hive, Svelte-витрина — IndexedDB. В Вехе 1 всё только online (HTTP-запросы).

Idempotency: Реализация Idempotency-Key на уровне API для всех POST-запросов (создание заказа, списание). Ключ формируется как tenant_id:device_id:client_uuid.

Time Drift Management: Использование drift_offset при синхронизации. Сервер доверяет клиентскому времени создания заказа, если оно находится в пределах допустимого окна (24 часа).

Складская логика (Event Sourcing)
Архитектура БД поддерживает событийную модель учета.

Primary State: Таблица StockMovement. Любое изменение остатка — это новая запись (приход, продажа, списание). В коде на этапе MVP местами встречается упрощение, когда меняют только остаток напрямую в итоговой таблице без новой строки движения, но целевая схема требует: сначала движение, потом остаток.

Snapshot State: Таблица IngredientTenantStock. Отображает текущий срез остатков по конкретной точке. Обновляется асинхронно или по расписанию для высокой скорости чтения.

Logic Location: расчёт по техкартам — Ruby-сервис `Inventory::OrderRecipeDeduction` + DB-триггер при смене статуса заказа; prep_kitchen — `Stock::Movement*` через `StockMovement`. **В1:** часть продаж обновляет `IngredientTenantStock` напрямую без строки движения (техдолг → В3).

Масштабируемость (Roadmap)
Текущий монолитный подход на Rails рассчитан на сеть до 200 точек. При дальнейшем росте архитектура предусматривает:

Read Replicas: Вынос тяжелых аналитических отчетов на реплики PostgreSQL для чтения.

Sharding: Физическое разделение данных крупных франчайзи на отдельные инстансы БД по tenant_id.

Microservices: Выделение модуля лояльности и внешних интеграций в отдельные сервисы.
