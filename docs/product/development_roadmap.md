IMPORTANT: Этот файл — высший приоритет для контекста. Игнорируй любые продвинутые функции из 03_business_logic.md и ARCHITECTURE.md, если они не входят в текущую активную Веху. Не добавлять новые фронты вне основного стека без явного решения продукта/архитектуры.

🚩 ВЕХА 1 (MVP — «Цифровой прилавок») — **РЕАЛИЗОВАНА** (2026-05-24)

Цель: рабочий **online-only** демо-прототип кофейни (1 org, 2 точки, prep_kitchen, демо-пользователи).

**Итог:** блоки A–G чеклиста закрыты; `bin/rails test` — **479 runs, 0 failures**. Приёмка (блок H): синхронизация доков, `qa_scenarios`, ручной прогон — в работе.

### Backend (Rails 8.1.2) — сделано

| Область | Реализация |
|---------|------------|
| Models | Tenant, Category, Product, Modifier, Order, OrderItem, CashShift, склад, prep_kitchen |
| Service Objects | Оркестрация в `app/services/` — см. `docs/operations/milestones/veha_1/PRACTICES.md` |
| Панели | УК, manager, barista, prep_kitchen — Rails + Hotwire; RBAC по ролям (integration-тесты) |
| Auth | Session-login панелей; Shop API — `X-Shop-Api-Key` + same-origin CSRF для `/shop` |
| Shop API | `/shop/api/{categories,products,cart,orders}`; меню из УК (Product + PTS + modifiers) |
| Оплата shop | **Имитация** (`SHOP_SIMULATE_PAYMENT=1`, default) → `accepted` / `succeeded` |
| Онбординг | `Platform::TenantOnboarding::{Provision, CatalogBootstrap, UrlBuilder}`; поддомен витрины |
| RLS | Существующие политики Postgres; изоляция точек (тесты); **новые** политики не добавлялись |
| Demo | `Demo::EnvironmentSetup`, `bin/rails demo:seed` — org, 2 точки, цех, каталог, 9 пользователей |
| Склад v0.1 | `Inventory::OrderRecipeDeduction` + DB-триггер; минус в остатке; prep_kitchen movements |
| Смена | **Гибрид:** shop без смены; barista только с `CashShift.open`; `close!` + `cash_difference` |
| Отмена | `Barista::OrderCancellationService` — reason + `admin_audit_logs` + возврат склада |

### Frontend (Витрина `/shop`) — сделано

Стек: Svelte + Vite (`app/frontend`).

- Меню: категории + плитки товаров (API `{ data }`).
- Корзина: ±, модификаторы (один уровень, required → radio).
- Оплата: кнопка «Оплатить» — имитация транзакции.
- История заказов за сегодня (`?today=1`).
- Skeleton / защита от double-click на оплате.

Сборка: `npm run vite:build` или `bin/dev` (Rails :3001 + Vite HMR). Локально: `ruby bin/ensure-server`.

### ⚠️ STOP-LIST В1 (соблюдено)

- **No new RLS policies** при онбординге.
- **No Offline** — Drift/Hive, sync engine.
- **No полный Event Sourcing склада** — упрощения v0.1.

**Техдолг В1:** полный реестр — **`docs/operations/milestones/veha_1/PRACTICES.md`**, раздел «Техдолг В1».

---

🚩 СЛЕДУЮЩИЙ ЭТАП: ВЕХА 2 (Scale & Stability — «Рост сети»)

Цель: подготовка к нескольким точкам, реальная оплата, offline POS.

Безопасность и изоляция (Multi-tenancy):
- Postgres RLS — готовые политики; middleware tenant через поддомен/сессию + `Current`.
- Tenant scoping через автоматический скоуп.

Offline-first (Sync Engine):
- Local DB / PWA для Rails POS.
- Background sync, UI Online/Offline/Syncing.

Flutter (мобильное приложение и киоск):
- Старт разработки; Drift/Hive; киоск — заказы **без** смены (как shop).

Кассовая дисциплина (расширение):
- В В1 бариста уже привязан к смене; в В2 — offline + единые правила на сеть точек.

Реальная оплата:
- `SHOP_SIMULATE_PAYMENT=0`, payment gateway, callbacks.

---

🚩 ФИНАЛЬНЫЙ ЭТАП: ВЕХА 3 (Total Control — «Профессиональный учет»)

Цель: тотальный аудит, склад как в Dodo IS, борьба с фродом.

Архитектура склада (Event Sourcing):
- Refactoring: убрать упрощения В1 → «сначала `StockMovement`, потом `IngredientTenantStock`».
- `StockMovement` — SoT; `IngredientTenantStock` — derived state.
- Nightly reconciliation.

Цепочка поставок (Supply Chain):
- Vendors, invoices, self-cost.

Анти-фрод и аудит:
- Расширение `admin_audit_logs`; алерты владельцу; Z-отчёт; запрет правок без следа.

---

🛠 Технический долг и допущения (Acceptable Debt)

**В1 (зафиксировано):**
- Склад: часть списаний без `StockMovement` — см. `MILESTONE_PRACTICES.md` § Block F.
- Тесты: полный suite 479 runs; ключевые флоу покрыты integration + services.
- UI: функциональный минимализм панелей и shop.

**Устаревшие допущения MVP (сняты по факту В1):**
- ~~Тесты только на один флоу~~ — покрытие RBAC, shop, склад, смена, панели.
- ~~Дублирование в контроллерах~~ — Service Objects для критичных путей.
