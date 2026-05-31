# QA-сценарии CoffeeOS (приёмка Вех 1–2)

⚠️ **Структура по вехам**

| Пометка | Когда прогонять |
|---------|-----------------|
| Без пометки, префикс **V1-** | **В1** — H.2 / живое demo |
| **[ВЕХА 2]** | **В2** — онбординг, Т-Банк, kiosk, RBAC |
| **[ВЕХА 3]** | Offline, единая смена, Event Sourcing |

`bin/rails test` **не заменяет** MCP/ручной прогон; закрывает **этап 1** (сухой).

### Этапы приёмки H

| Этап | Кто | Инструмент | Журнал |
|------|-----|------------|--------|
| **1. Сухой** | Агент | `bin/rails test`, integration | **Авто** — `veha_2/QA_ACCEPTANCE_RUN.md` |
| **2. MCP** | Агент | Chrome DevTools MCP | **MCP** — там же + `ONBOARDING_DEVTOOLS_RUN.md` |
| **3. Ручной + demo** | Заказчик | Браузер, **реальные деньги** | **Ручной** — `DEMO_FEEDBACK.md` |

Протоколы: [`veha_1/QA_ACCEPTANCE_RUN.md`](../../operations/milestones/veha_1/QA_ACCEPTANCE_RUN.md) · [`veha_2/QA_ACCEPTANCE_RUN.md`](../../operations/milestones/veha_2/QA_ACCEPTANCE_RUN.md)

---

## 0. Подготовка среды (обязательно перед прогоном)

| Параметр | Значение |
|----------|----------|
| БД + демо-данные | `bin/rails db:migrate` → `bin/rails demo:seed` |
| Сервер | `ruby bin/ensure-server` или `bin/dev` (Rails **:3001**) |
| Shop (статика) | `npm run vite:build` (если Svelte не из `bin/dev`) |
| Base URL | `http://127.0.0.1:3001` |
| Логин панелей | `http://127.0.0.1:3001/login` |
| Пароль всех demo-пользователей | `demo123456` |
| Логины / роли | `docs/operations/milestones/veha_1/DEMO_LOGINS.md` |
| Tenant A (slug) | `demo-point-a` |
| Tenant B (slug) | `demo-point-b` |
| Цех (slug) | `demo-prep-kitchen` |

**UUID точки A для витрины** (после `demo:seed`):

```bash
bin/rails runner "puts Tenant.find_by!(slug: 'demo-point-a').id"
```

Витрина: `http://127.0.0.1:3001/shop?tenant_id=<UUID_из_команды_выше>`

Альтернатива: зайти как `gm-a@demo.coffeeos.local` → в сайдбаре **«Витрина этой точки»** (ссылка уже с `tenant_id`).

---

## Журнал прогона В1

**Прогон агента:** 2026-05-25. Детали: `docs/operations/milestones/veha_1/QA_ACCEPTANCE_RUN.md`.

| ID | Авто (этап 1) | MCP (этап 2) | Ручной (этап 3) | Комментарий |
|----|---------------|--------------|-----------------|-------------|
| V1-0 | OK | OK | — | `demo:seed`; shop 200; tenant A `8c7f5bc7-f2b4-43f0-991c-5ede0f480b20` |
| V1-1.1 | OK | — | опц. | tenant isolation / shop API tests |
| V1-1.2 | OK | — | опц. | `gm-a` vs `gm-b` — integration |
| V1-2.1 | OK | OK | опц. | barista POS; `/manager` → доступ запрещён (MCP) |
| V1-2.2 | OK | — | опц. | `general_manager_rbac_test` |
| V1-2.3 | OK | — | опц. | `franchise_manager_rbac_test` (switch, read-only menu) |
| V1-2.4 | OK | — | опц. | `shift_manager_rbac_test` |
| V1-2.5 | OK | OK | опц. | `/admin` OK; `/barista` запрещён (MCP) |
| V1-2.6 | OK | — | опц. | `prep_kitchen_manager_rbac_test` |
| V1-2.7 | OK | — | опц. | `prep_kitchen_worker_rbac_test` |
| V1-3.1 | OK | — | опц. | barista без смены — `block_g` (перепрогон после 429) |
| V1-3.2 | OK | OK | опц. | barista login, смена открыта (MCP) |
| V1-3.3 | OK | OK | опц. | shop заказ без смены, mock accepted (MCP) |
| V1-3.4 | OK | OK | опц. | модификаторы + история за сегодня (MCP) |
| V1-3.5 | OK | — | опц. | отмена + `admin_audit_logs` — `block_g` |
| V1-3.6 | OK | — | опц. | `cash_difference` — `block_g` |
| V1-3.7 | OK | OK | опц. | имитация оплаты (MCP) |
| V1-3.8 | OK | — | опц. | статус без смены — `block_g` |
| V1-4.1 | OK | — | опц. | `order_recipe_deduction_test`, block F |
| V1-4.2 | OK | — | опц. | отрицательный остаток — block F |
| V1-4.3 | OK | — | опц. | prep movement — `prep_kitchen_movements_test` |
| V1-4.4 | OK | — | опц. | stop-list — integration prep |
| V1-4.5 | OK | — | опц. | return при отмене — `block_g` |
| V1-5.1 | OK | — | опц. | onboarding rollback — `platform/tenants_controller_test` |
| V1-6.1 | OK | OK | опц. | double-click / один заказ (MCP shop) |

**Автотесты:** `479 runs, 0 failures` (2026-05-25).  
**Замечание:** batch shop+block_g дал 1×429 на shop order; изолированный тест OK.

**Критерий H.2 (агент):** этапы 1–2 — все V1-* **Авто** и/или **MCP** = OK.  
**Критерий H.3 (владелец):** живое демо — отдельно, колонка **Ручной**.

---

## 1. Безопасность и изоляция (RLS / multi-tenancy)

**Цель:** данные точки A не видны точке B.

### V1-1.1: Подмена tenant (API / сессия)

**Действие:**

1. Залогиниться как `gm-a@demo.coffeeos.local` / `demo123456`.
2. Открыть витрину с UUID **точки B** (slug `demo-point-b`):  
   `bin/rails runner "puts Tenant.find_by!(slug: 'demo-point-b').id"` → подставить в `/shop?tenant_id=...`.
3. Либо в DevTools: запрос к `/shop/api/products` с заголовком `X-Shop-Tenant: <uuid_чужой_точки>` без прав сессии.

**Ожидание:** чужой каталог/заказы не отдаются; для панелей при нарушении доступа — редирект/ошибка, без утечки данных другого tenant.

### V1-1.2: Изоляция справочников двух точек

**Действие:**

1. `gm-a@demo.coffeeos.local` → `/manager/menu` — зафиксировать цену/товар точки A.
2. `gm-b@demo.coffeeos.local` → `/manager/menu` — другой набор/цены точки B.
3. `gm-a` не может переключиться на точку B (если нет роли franchise/УК).

**Ожидание:** меню и staff строго в рамках своего tenant; перекрестных записей нет.

---

## 2. Ролевая модель (6 ролей + витрина без роли)

**Цель:** каждая роль видит только свою панель. Логины — `DEMO_LOGINS.md`, пароль `demo123456`.

### V1-2.1: `barista` — только POS

**Действие:** `barista-a@demo.coffeeos.local` → после login `/barista`.  
Попробовать вручную: `/manager`, `/prep_kitchen`, `/admin` (platform root).

**Ожидание:** доступен `/barista` (дашборд, смена, заказы). Остальные URL — **redirect**, не 200.

### V1-2.2: `general_manager` — полная точка A

**Действие:** `gm-a@demo.coffeeos.local` → `/manager/menu`, `/manager/inventory`, `/manager/staff_members`, `/manager/reports`.  
Попробовать изменить цену PTS, открыть `/barista`.

**Ожидание:** меню/цены/staff/склад/отчёты **своей** точки доступны; PATCH цены успешен; `/barista`, `/prep_kitchen`, `/admin` — redirect.

### V1-2.3: `franchise_manager` — сеть, read-only меню, отчёты

**Действие:** `franchise@demo.coffeeos.local` → `/manager`.  
Переключить точку A → B (`POST /manager/switch_tenant` через UI).  
`/manager/menu` на обеих точках; `/manager/reports`; попробовать сохранить цену; открыть `/barista`.

**Ожидание:** дашборд и **переключение** между `demo-point-a` / `demo-point-b`; меню **видно**, формы «Сохранить цену» **нет**; PATCH цены не меняет price; **отчёты открываются**; POS (`/barista`) и `/admin` — redirect.

### V1-2.4: `shift_manager` — только текущая смена

**Действие:** `shift-a@demo.coffeeos.local` → `/manager/orders`, `/manager/shifts`.  
Попробовать `/manager/inventory`, `/manager/staff_members`, изменить цену в меню; отчёт с «широким» периодом по закрытой смене (если есть в UI).

**Ожидание:** оперативные разделы открытой смены доступны; inventory/staff/devices/TV и правка цен — **нет**; глубокая история закрытых смен недоступна.

### V1-2.5: `uk_global_admin` — platform / УК

**Действие:** `uk@demo.coffeeos.local` → `/admin` (organizations, tenants, menu/platform catalog).  
Попробовать `/barista`, `/manager`, `/prep_kitchen`.

**Ожидание:** platform-разделы **200**; операционные панели точки — redirect.

### V1-2.6: `prep_kitchen_manager` — полный цех

**Действие:** `pk-manager@demo.coffeeos.local` → `/prep_kitchen` (dashboard, inventory, movements, stop_list, new movement).  
Попробовать `/barista`, `/manager`, `/admin`.

**Ожидание:** все разделы цеха доступны; чужие панели — redirect.

### V1-2.7: `prep_kitchen_worker` — только просмотр

**Действие:** `pk-worker@demo.coffeeos.local` → `/prep_kitchen` (dashboard, inventory, movements list).  
Попробовать создать движение (`/prep_kitchen/.../new`), PATCH stop-list.

**Ожидание:** списки/остатки **видны**; мутации (новое движение, подтверждение, stop-list) — **запрещены** (redirect/403).

---

## 3. Кассовая дисциплина и заказы (гибрид смены + shop)

**Цель:** barista привязан к `CashShift`; shop — без смены.  
**Реестр входов (не дублировать правила):** `docs/operations/milestones/veha_1/ORDER_ENTRY_AUDIT.md`.

> После `demo:seed` у `barista-a` обычно уже **открытая** смена. Для V1-3.1 сначала **закройте** смену: `/barista/shift` → закрытие (wizard), затем пробуйте новый заказ.

### V1-3.1: Barista **без** открытой смены → заказ блок

**Действие:** `barista-a@demo.coffeeos.local`, смена **закрыта** → `/barista/create-order` → добавить товар → оплатить.

**Ожидание:** redirect, flash «Смена не открыта» (или аналог); **новый** `orders` не создаётся.

### V1-3.2: Barista **с** открытой сменой → заказ OK

**Действие:** открыть смену на `/barista/shift` → `/barista/create-order` → cash/card → создать заказ.

**Ожидание:** заказ `accepted`, в БД `cash_shift_id` = id открытой смены (проверка в `/barista/orders/:id` или rails runner).

### V1-3.3: Shop **без** смены → заказ OK

**Действие:** без логина открыть  
`http://127.0.0.1:3001/shop?tenant_id=<UUID demo-point-a>` → товар в корзину → **Оплатить** (mock).

**Ожидание:** заказ создан, статус `accepted`, оплата `succeeded`; `cash_shift_id` **NULL**.

### V1-3.4: Shop — меню, модификаторы, история за сегодня

**Действие:** на витрине — категории и товары; товар с обязательным модификатором (radio); после оплаты — блок **истории заказов за сегодня** (`?today=1` или UI «сегодня»).

**Ожидание:** без модификатора заказ не уходит; с модификатором — OK; в истории виден только что созданный заказ.

### V1-3.5: Отмена barista — обязательная причина + audit

**Действие:** под `barista-a`, открытая смена → создать заказ → перевести в `preparing` (если нужно по UI) → **Отменить** без причины, затем с причиной из списка.

**Ожидание:** без причины — ошибка/форма не принимает; с причиной — заказ `cancelled`; запись в `admin_audit_logs` (`order_cancelled`) — проверка:

```bash
bin/rails runner "puts AdminAuditLog.where(action: 'order_cancelled').order(created_at: :desc).limit(3).pluck(:id, :metadata)"
```

### V1-3.6: Закрытие смены — недостача (`cash_difference`)

**Действие:** при открытой смене несколько cash-заказов → `/barista/shift` → закрыть смену, ввести **меньшую** сумму наличных, чем `expected_cash`.

**Ожидание:** смена `closed`, поле `cash_difference` **отрицательное** (недостача).

### V1-3.7: Shop mock-оплата (имитация)

**Действие:** витрина → оплата (кнопка «Оплатить»).

**Ожидание:** без реального шлюза заказ сразу `accepted`, payment provider `shop` / simulate (см. `SHOP_SIMULATE_PAYMENT=1`).

### V1-3.8: Barista не меняет статус заказа без смены

**Действие:** закрыть смену при существующем активном заказе → попробовать сменить статус.

**Ожидание:** операция блокируется (как V1-3.1).

---

## 4. Склад (Inventory v0.1)

**Цель:** списание при продаже, минус разрешён, prep_kitchen движения, stop-list.

### V1-4.1: Списание при продаже (shop или barista)

**Действие:** в `/prep_kitchen/inventory` или rails runner зафиксировать `qty` ингредиента с техкартой на проданный товар.  
Продать этот товар через **shop** (V1-3.3) или **barista** (V1-3.2).

**Ожидание:** `ingredient_tenant_stocks.qty` уменьшился на объём по `product_recipes`.

### V1-4.2: Остаток в минус — продажа не блокируется

**Действие:** довести остаток ключевого ингредиента до 0 (или уже 0 после 4.1) → ещё один заказ с этим товаром.

**Ожидание:** заказ **принят**; `qty` **отрицательный**; UI не показывает жёсткий stop на витрине/POS из-за склада.

### V1-4.3: Prep — движение черновик → подтверждение

**Действие:** `pk-manager@demo.coffeeos.local` → `/prep_kitchen` → новое движение (приход) → сохранить черновик → **подтвердить**.

**Ожидание:** до подтверждения остаток не меняется (или статус draft); после confirm — `qty` увеличился, движение `confirmed`.

### V1-4.4: Prep — stop-list / min_qty

**Действие:** `pk-manager` → stop-list: пометить ингредиент / товар sold out или изменить `min_qty` (если есть в UI).

**Ожидание:** изменение сохраняется для tenant цеха; на витрине точки A товар с `is_sold_out` не продаётся (если связан через PTS).

### V1-4.5: Отмена barista (preparing) — возврат на склад

**Действие:** заказ barista в `preparing`, `ingredients_used=false` → отмена с reason (V1-3.5).

**Ожидание:** при выполнении условий создаётся `StockMovement` типа **return**, остаток растёт (см. `Barista::OrderCancellationService`).

⚠️ **[ВЕХА 3]** Полный Event Sourcing (каждое списание только через `stock_movements`), Nightly Reconciliation — не в прогоне В1. Таблицы проекта: `stock_movements`, `ingredient_tenant_stocks` (не `inventory_transactions`).

---

## 5. Онбординг точки (атомарность)

### V1-5.1: Rollback при ошибке на последнем шаге

**Действие:** `uk@demo.coffeeos.local` → `/admin` → создать **новую** org/tenant (уникальный slug) → на последнем шаге указать **невалидный email** менеджера (например `not-an-email`).

**Ожидание:** ошибка валидации; в БД **нет** новой org/tenant/user от этой попытки (проверка в `/admin/tenants` или runner по slug).

---

## 6. UI (Веха 1)

### V1-6.1: Двойной клик «Оплатить» (shop)

**Действие:** витрина `demo-point-a` → корзина с товаром → быстро **2–3 раза** нажать «Оплатить».

**Ожидание:** кнопка блокируется (loader/disabled); в истории за сегодня **один** новый заказ, не дубликаты.

---

## Сценарии [ВЕХА 2]

MCP-шаги: [`ONBOARDING_DEVTOOLS_SCENARIOS.md`](../../operations/milestones/veha_2/ONBOARDING_DEVTOOLS_SCENARIOS.md). Журнал: [`ONBOARDING_DEVTOOLS_RUN.md`](../../operations/milestones/veha_2/ONBOARDING_DEVTOOLS_RUN.md).

### V2-ONB: Онбординг 3 org × 3 точки

**Действие:** УК → 3 org, точки SAL/KIT/ENT + prep_kitchen; карточка «все входы».

**Ожидание:** URL витрины (`?tenant_id=` на Fly); staff; RLS.

### V2-AUTH: RBAC AUTH-01…10

**Действие:** прогон § AUTH в ONBOARDING_DEVTOOLS_SCENARIOS.

**Ожидание:** роли изолированы; cross-panel — redirect/403.

### V2-PAY: Т-Банк (не ЮKassa)

**Действие:** `SHOP_SIMULATE_PAYMENT=0`; card/sbp → `pending_payment` → callback → `accepted`.

**Ожидание:** списание; barista табло без F5; idempotent callback.

**MCP:** signed callback OK. **Живое demo:** реальные деньги.

### V2-PAY-STRESS: 5–8 оплат / ~3 с

**Действие:** серия заказов с витрины.

**Ожидание:** без 500/дубликатов.

### V2-URL / V2-KIOSK / V2-FLOW

- **URL:** витрина/QR из карточки точки — меню и цены своего tenant.
- **Kiosk:** `POST /kiosk/api/auth` + shop API (curl); без Flutter UI.
- **Barista ↔ prep_kitchen:** продажа → остаток цеха ↓ (как V1-1.4).

### [ВЕХА 2] 6.2: Таймаут >5 с — **[В2] done**

Overlay skeleton (`slow_request_ux_test`; прогон 8, 2026-05-30).

---

## Сценарии [ВЕХА 3] — не закрытие В2

### [ВЕХА 3] 3.V2-1: Единая смена на **всех** каналах

Shop/kiosk **без** смены в В1–В2 (гибрид). Единая дисциплина — **В3**.

### [ВЕХА 3] Offline POS (O-1…O-3)

IndexedDB, sync, `client_uuid`. *(Callback idempotency Т-Банка — **[В2] done**.)*

---

- Уведомления владельцу о подозрительных отменах; автоматический финансовый отчёт при расхождении смены.
- Полный журнал склада (Event Sourcing как SoT), nightly reconciliation.
- Z-отчёт, запрет правок в закрытых чеках без следа.

---

## Ссылки

- Логины В1: `docs/operations/milestones/veha_1/DEMO_LOGINS.md`
- Чеклист В1: `docs/operations/milestones/veha_1/CHECKLIST.md` (блок H)
- Чеклист В2: `docs/operations/milestones/veha_2/CHECKLIST.md` (§I)
- Продукт (scope): `docs/product/development_roadmap.md`
- Техдолг (не дублировать в QA): `docs/operations/milestones/veha_1/PRACTICES.md` § «Техдолг В1»
