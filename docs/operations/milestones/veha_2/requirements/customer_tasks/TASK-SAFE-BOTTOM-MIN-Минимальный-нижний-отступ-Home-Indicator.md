# TASK_SAFE-BOTTOM-MIN: Минимальный нижний отступ (Home Indicator) для всех bottom-sheet

**ID:** TASK_SAFE-BOTTOM-MIN · **Дата intake:** 2026-10-01  
**Источник:** владелец (чат 2026-10-01) — доп.задачи 3 + 4 аудита TASK_83/84 § 7, слиты в одну (решение владельца `merge_global`)  
**Расширяет:** контракт safe-area #67 (`--shop-safe-bottom`, `app.css`, `shopWebViewLayout.js`)  
**Тип:** новая задача (включает доп.задачу 3 «Home Indicator у шторки статуса»)  
**Статус:** SBR

---

## Сценарий владельца (дословно, доп.задача 3)

```gherkin
Сценарий: отступ снизу не меньше минимума
  Дано устройство с safe-area-inset-bottom = 0 (Android, старый iPhone, WebView)
  Тогда у шторки статуса снизу есть отступ не меньше N px
  Дано iPhone с Home Indicator (inset 34px)
  Тогда отступ = 34px (берётся большее)
```

**N = 8px** (владелец: «ебашь» на предложение 8px).

## Сценарий доп.задачи 4 (черновик агента, принят владельцем)

```gherkin
Сценарий: единый нижний отступ у всех bottom-sheet
  Дано любой из экранов: CartSheet, фильтры, сортировка, поддержка, чек заказа, шторка статуса
  Тогда нижний отступ берётся из одной переменной --shop-safe-bottom
  И --shop-safe-bottom = max(N px, safe-area / значение от WebView)
  И визуальные отступы экранов (24px/16px сверх inset) не меняются
```

## Почему слито

На витрине шторка статуса встроена в `CartSheet` (`embedded={true}`); её нижний отступ = `CartSheet` `bottom: var(--shop-safe-bottom)`. `OrderStatusSheet.svelte` `.oss { padding-bottom: env(…) }` действует только в legacy overlay (на витрине не используется). Минимум для шторки достижим только через `--shop-safe-bottom`.

## Subtask

- [x] 1. `app.css`: `--shop-safe-bottom: max(8px, env(safe-area-inset-bottom, 0px))`
- [x] 2. `shopWebViewLayout.js`: значение от WebView → `max(8, inset)` px (`SHOP_SAFE_BOTTOM_MIN_PX = 8`)
- [x] 3. Экраны на переменную вместо своего `env()`: `CatalogFiltersSheet`, `CatalogSortSheet`, `ContactSupportSheet`, `OrderReceipt`, `OrderStatusSheet` (overlay); добавки 24px/16px сохраняются
- [x] 4. `CartSheet` — без правок (уже `var(--shop-safe-bottom)`), шторка статуса получает минимум через него
- [x] 5. Тесты: 0 → 8px, 34 → 34px; в 5 экранах нет `env(safe-area-inset-bottom`

- [x] 6. (bugbot) резерв `Catalog` / `CategoryProducts` / `Product` под CartSheet + `var(--shop-safe-bottom)` — RED `835566b2` → GREEN `6309066c`

**RED** `e6a57efb` (9 fail) → **GREEN** `1c21dbda` · REVIEW · CI green [36837366924](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36837366924) · визуально на устройстве не проверено (Android: CartSheet в peek поднимается на 8px от края)

## Scope

Разрешено: `app/frontend/styles/app.css`, `app/frontend/lib/shopWebViewLayout.js`, 5 экранов (только нижний отступ), тесты.  
Запрещено: `--shop-safe-top`, высоты `CartSheet` / `stackBottomPx` / `cartSheetThresholds`, клавиатура (`--shop-keyboard-inset`), чек / peek-only / стрелка / `×`, backend.
