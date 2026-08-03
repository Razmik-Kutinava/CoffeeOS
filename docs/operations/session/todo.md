# todo — Order status OS detect + Wallet/WebPush (#37)

**ТЗ:** [`customer_tasks/Адаптивный виджет статуса заказа Детекция ОС и подписка на уведомления.md`](../milestones/veha_2/requirements/customer_tasks/Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md)  
**Артефакты:** [`artifacts/order_status_os_detect_wallet_webpush/`](../milestones/veha_2/artifacts/order_status_os_detect_wallet_webpush/)  
**Фаза:** SPEC `[x]` · RED `[x]` · GREEN `[x]` шаг 1 · REVIEW `[ ]` · MCP/deploy `[ ]`

---

## Канон SPEC (маппинг ТЗ → CoffeeOS)

| ТЗ (React / `/api/v1`) | Канон CoffeeOS |
|------------------------|----------------|
| `src/utils/deviceDetect.ts` | `app/frontend/lib/deviceDetect.js` |
| `deviceDetect.test.ts` | `test/javascript/device_detect_test.mjs` (`node --test`) |
| `OrderStatusBottomBar.tsx` | Правая колонка stubs в `ActiveOrdersAccordion.svelte` (`aoa__actions`) + логика в `app/frontend/lib/orderStatusNotifyActions.js` |
| Fixed bar `z-50` overlay | **Не новый overlay.** Бар = уже существующий `OrderStatusSheet` **embedded** в `CartSheet` (v418). Кнопки — в строке аккордеона. |
| Tailwind / `#FF8A3D` | Scoped CSS как в `ActiveOrdersAccordion` / kit: accent **`#ff8c42`** (`--accent`). Tailwind в shop FE нет — не вводим. |
| Модалка «Состав заказа» | **Не новая модалка.** Нижняя кнопка → `toggleExpandedOrder` (чек `aoa__receipt` как в #36). Архитектуру модалок не трогаем. |
| `GET /api/v1/orders/:id/wallet_pass` | **Новый** `GET /shop/api/orders/:id/wallet_pass` (blob `.pkpass`) поверх `Shop::AppleWallet::PassBuilder` / `OrderWalletPass` |
| `POST …/push_subscription` + raw WebPush | **Reuse** `registerShopPush()` → `POST /shop/api/push/register` (FCM + VAPID). Не новый WebPush endpoint. |
| Vitest + RTL | `node --test` в `test/javascript/` + Rails integration на wallet_pass |

### Ограничения / риски

- **Не ломать** status-inside-cart (embedded), accordion receipt, Cable.
- Wallet download UI + route — раньше backlog runbook; в этой фиче **в scope** (шаг 4).
- Push register сегодня требует **сессию** `MobileCustomer` — при госте: toast / soft fail (не краш).
- `ActiveOrdersAccordion.svelte` уже ~240 строк → логику кнопок вынести в lib (file-size).
- PKCS7 prod signing / APNs device register — **вне scope** (остаётся PRACTICES / runbook).

---

## Атомарные шаги (TDD)

### Шаг 1 — `getDeviceOS` `[x]`

- **Файлы:** `app/frontend/lib/deviceDetect.js` · `test/javascript/device_detect_test.mjs`
- **RED:** 7/7 fail · **GREEN:** 7/7 pass (`00f2ff36` → GREEN commit)
- **Given/When/Then:** `'ios'` (iPhone/iPod + iPadOS MacIntel+touch), `'android'`, `'desktop'` (+ SSR `hasWindow:false`)

### Шаг 2 — Верстка кнопок в аккордеоне `[ ]`

- **Файлы:** `ActiveOrdersAccordion.svelte` (+ CSS stubs → реальные кнопки) · опционально thin view-helpers в lib · тесты `test/javascript/order_status_notify_actions_test.mjs` / structural
- **Then:** правая секция `flex flex-col gap-2` (~`w-44`): верх — CTA по ОС («Карта в Apple Wallet» / «Уведомление о готовности»), низ — «Состав заказа»; стили kit (`#ff8c42`, `h-9`, rounded, `text-xs font-semibold`)
- **Не:** отдельный fixed `OrderStatusBottomBar` overlay

### Шаг 3 — «Состав заказа» → чек `[ ]`

- **Then:** клик нижней кнопки вызывает `toggleExpandedOrder` / раскрывает `aoa__receipt`; `isLoading` не ставится
- **TDD:** unit на handler + (при необходимости) mount acceptance

### Шаг 4 — iOS → Apple Wallet `[ ]`

- **BE:** `GET /shop/api/orders/:id/wallet_pass` → `application/vnd.apple.pkpass` (simulate stub ok) · integration test
- **FE:** loading spinner → fetch blob → `blobUrl` → navigate; `localStorage order_{id}_wallet_added`; success label «✓ Карта добавлена»; error → toast, текст CTA без изменений
- **TDD:** JS mocks fetch/location/localStorage + Rails API test

### Шаг 5 — Android/Desktop → Push (FCM) `[ ]`

- **FE:** loading → `registerShopPush()` (permission + SW + FCM token + `/push/register`)
- **Then:** granted+ok → «✓ Уведомления включены»; denied → soft toast «Уведомления запрещены…»; network fail → toast ошибки
- **TDD:** mocks Notification / registerShopPush / api
- **Не** invent `POST …/push_subscription` с raw `PushSubscription`

### Шаг 6 — Init restored state `[ ]`

- **Then:** при mount: `localStorage wallet_added` → disabled «✓ Карта добавлена»; `Notification.permission === 'granted'` (и/или уже зарегистрированный push) → «✓ Уведомления включены» без повторного клика
- **TDD:** init render cases

---

## Регрессия (после GREEN / REVIEW)

| Зона | Команда |
|------|---------|
| JS | `node --test test/javascript/device_detect_test.mjs test/javascript/order_status_*.mjs` (и связанные) |
| Shop status | `bin/rails test test/integration/shop/order_status_sheet_mount_acceptance_test.rb` + active_orders* |
| Push | `bin/rails test test/integration/shop/api/push_register_test.rb` |
| Wallet API | новый integration test на `wallet_pass` |

---

## Exit (из ТЗ, адаптировано)

1. Unit/integration зелёные по шагам 1–6  
2. Регрессия зоны PASS  
3. Визуал кнопок = kit аккордеона / `#ff8c42`  
4. MCP DevTools (iOS/Android UA) после deploy-апрува — не в этом SPEC-шаге
