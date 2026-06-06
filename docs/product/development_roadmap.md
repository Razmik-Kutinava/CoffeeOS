IMPORTANT: Этот файл — высший приоритет для контекста. Игнорируй любые продвинутые функции из 03_business_logic.md и ARCHITECTURE.md, если они не входят в текущую активную Веху. Не добавлять новые фронты вне основного стека без явного решения продукта/архитектуры.

🚩 ВЕХА 1 (MVP — «Цифровой прилавок») — **РЕАЛИЗОВАНА** (2026-05-24)

Цель: рабочий **online-only** демо-прототип кофейни (1 org, 2 точки, prep_kitchen, демо-пользователи).

**Итог:** блоки A–G чеклиста закрыты; `bin/rails test` — **479 runs, 0 failures**. Приёмка (блок H): синхронизация доков, `qa_scenarios`, ручной прогон — в работе.

### Backend (Rails 8.1.2) — сделано

| Область | Реализация |
|---------|------------|
| Models | Tenant, Category, Product, Modifier, Order, OrderItem, CashShift, склад, prep_kitchen |
| Service Objects | Оркестрация в `app/services/` — см. `docs/operations/milestones/veha_1/reference/PRACTICES.md` |
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

**Техдолг В1:** полный реестр — **`docs/operations/milestones/veha_1/reference/PRACTICES.md`**, раздел «Техдолг В1».

---

🚩 ВЕХА 2 (Scale & Stability — «Рост сети») — **КОД ~88%, ПРИЁМКА §I НЕ ЗАКРЫТА** (2026-05-30)

Цель: сеть **из коробки** (УК → org/точки), **реальная оплата** Т-Банк, backend киоска, практики надёжности (H).

**Итог кода:** блоки A–H [`veha_2/checklists/CHECKLIST.md`](../operations/milestones/veha_2/checklists/CHECKLIST.md) в основном `[x]`; **`bin/rails test` — 554 runs, 0 failures** (2026-05-30). **§I открыта:** живое demo, QA прогон 10, DEMO_FEEDBACK.

### Сделано в В2

| Область | Реализация |
|---------|------------|
| Онбординг | `Platform::TenantOnboarding::{Provision, CatalogBootstrap, UrlBuilder}`; org → SAL/KIT/ENT + prep_kitchen; **карточка входов** (URL, модули, staff) |
| URL витрины | Поддомен (режим A) или `/shop?tenant_id=` на Fly (режим B) — `SHOP_URL_MODES.md` |
| Оплата | **Т-Банк** (`Payments::TbankAdapter`, `Callbacks::TbankController`, `TbankCallbackJob`); cash/card/sbp; `SHOP_SIMULATE_PAYMENT=0` на prod |
| Надёжность | Outbox (Solid Queue worker), Circuit Breaker, idempotency callback; `StuckPaymentsCheckJob` |
| Shop / витрина | `pending_payment` + редирект на `pay.tbank.ru`; callback → `accepted` + списание |
| Kiosk backend | `POST /kiosk/api/auth` (device_token); заказы через shop API; **без Flutter UI** |
| Live-табло | Barista POS — broadcast без F5 (Solid Cable + worker) |
| Feature flags | Модули точки — скрытие разделов панелей |
| UX | Overlay skeleton при медленном fetch **>5 с** (`slow_request_ux_test`) |
| Смена | **Гибрид сохранён** (shop/киоск без смены; barista с `CashShift.open`); CloseWizard — pending online за 24ч |
| RBAC / staff | AUTH-01…10 (сценарии в `ONBOARDING_DEVTOOLS_SCENARIOS.md`) |

### Перенесено в В3 (не обещали в закрытии В2)

- Offline POS (IndexedDB, sync queue, drift)
- Flutter UI (киоск / мобилка)
- **Единая смена** на всех каналах (shop/киоск тоже только при open shift)
- Refund, Z-отчёт, полный Event Sourcing склада

**Ops:** `docs/operations/milestones/veha_2/` — CHECKLIST, PRACTICES, PAYMENT, QA_ACCEPTANCE_RUN.

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
