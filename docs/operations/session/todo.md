# todo — TASK_118: SMS «Заказ готов» → история заказов CODE:BLACK (очередь, шаг 15)

| Поле | Значение |
|------|----------|
| **Очередь** | [PUSH_SMS_QUEUE](../milestones/veha_2/requirements/PUSH_SMS_QUEUE.md) · шаг **15** `in_progress` · зависимости 2 / 4 / 5 / 13 / 14 / 0.4 = done |
| **Основание** | [TASK-118-…](../milestones/veha_2/requirements/customer_tasks/TASK-118-SMS-Заказ-готов-история-заказов-CODE-BLACK.md) · CBR #118 · Google Doc v4 |
| **Статус** | **REVIEW** 2026-11-02 · RED `7be416af` → GREEN `5422913e` · Entire `01M6E6SK26KVPBMSJWMAJXCFQ4` · crit-audit CLEAN · COMPONENT_MAP: нет · миграции нет · не задеплоено (🚀 7) |

## SBR

- [x] intake (0.3 + шаг 15) — текст 1:1, CBR #118, очередь `in_progress`
- [x] SPEC — факты = код (ниже) · решения · файлы · Не ломать · Проверка · миграции нет
- [x] RED `7be416af` — resolve/screens/pin/profile Location `[RED]`
- [x] GREEN — `resolve` + short link HTML/Location + `sms_entry` pin; задача short_links 8/0, sms_link 13/0; sms_transition 7+3; rack 5/0; ownership 11/0; JS pin+preferred 9/0 + sms_session 12/0; rubocop 0
- [x] `/review` — local «Проверка» PASS · ревью диффа вручную (bugbot/security skip) · crit-audit CLEAN · COMPONENT_MAP: нет · Entire `01M6E6SK26KVPBMSJWMAJXCFQ4` · push → CI

## Сверка фактов (SPEC 2026-11-02)

| Документ | Код | Итог |
|---|---|---|
| `config/routes.rb:21` `GET /o/:order_hash` | `:21` → `shop/order_short_links#show` | ✅ |
| `order_short_links_controller.rb:12-27` — find → bind → Location с `reconnect_token` + `#/order/:id` | `:12-38` — conflict → `sms_transition` (TASK_117); иначе bind → `/shop?tenant_id=…#/order/:id`; **`reconnect_token` уже нет** | ⚠️ doc устарел по token; цель всё ещё `#/order` → **TASK_118: `#/profile?order=<id>`** |
| `order_ready_sms_link.rb:32-49` любая неудача → `nil` | `:32-54` — MAC fail / нет заказа / expired → `nil` | ✅; **нужно различить expired vs invalid** (R4) |
| Пустой 404 на просрочку/подделку `:12-13` / тесты `:46-71` | `head :not_found`; тесты `:78-104` | ✅ сейчас; → экраны «устарела» / «недействительна» без bind |
| TTL 48h от `ready_notified_at \|\| ready_at \|\| updated_at` `:11,60-64` | `TTL = 48.hours`, `link_expired?` `:60-65` | ✅; якорь не менять (S8 уже в ReadyPushJob) |
| Текст SMS / host / ≤70 | `message_prefix` / `link_host` / тест fly.toml | ✅ Subtask 9 done (0.3) — **не трогать** |
| `guest_order_reconnect` bind до confirm | bind только если **нет** conflict (TASK_117) | ✅ оставить; ошибки — **до** любого bind |
| `bootstrapShopTenant` `:141-148,175-193` может сменить точку на preferred | `:159-210`; override preferred `:199-201`; inactive → preferred `:194-196` | ⚠️ сдвиг строк; **SMS-вход не должен уступать сохранённой B** (S2); закрытая точка — S10 |
| История сети / highlight `?order=` | TASK_116: `Profile` + `parseProfileHighlightOrderId` | ✅ владеет B; short link только ведёт hash |
| Confirm TASK_117 → `#/profile?order=` | `smsSessionTransition.js` `profilePathAfterConfirm` `:78-79` | ✅ уже; happy-path short link должен совпасть |
| Rack::Attack `/o/` 30/мин | `rack_attack.rb:84-86` + `rack_attack_order_short_link_test` | ✅ не ослаблять (S6) |
| Production RLS | этап 1: RLS не действует; изоляция кодом | ✅ |

**Находки:**
- Happy-path Location всё ещё `#/order/:id` — главная правка TASK_118 (в т.ч. без conflict).
- `find_order` смешивает expired и invalid → один 404; нужен явный статус после успешной MAC (expired) vs MAC/мусор (invalid), без раскрытия заказа/клиента.
- `bootstrapShopTenant` при `preferred ≠ current` уводит с точки заказа A на сохранённую B — ломает S2; при `!currentAllowed` уводит на preferred — для S10 оставить историю без highlight.
- Doc пишет `reconnect_token` в Location — уже снято в TASK_117; в Build не возвращать.
- Subtask 8: тест якоря уже есть (`ready_push_job_test` «SMS link anchor unchanged») — на RED добавить/усилить assert в зоне SMS-link при необходимости, не дублировать job.
- Subtask 12 (iPhone T1) — только фиксация факта, код не менять.
- Subtask 9 — не в Build.

## Решения (агент)

1. **`OrderReadySmsLink.resolve(hash)`** (или эквивалент): `:ok` + order · `:expired` (MAC ок, TTL вышел) · `:invalid` (остальное). `find_order` = только ok (для совместимости) или тонкая обёртка.
2. **Контроллер:** ok → как сейчас (conflict / bind), Location **`/shop?tenant_id=<order>&sms_entry=1#/profile?order=<id>`** (без `reconnect_token`); expired → HTML «Ссылка устарела» + CTA «Открыть мои заказы» → `/shop#/profile`, **без** bind/session; invalid → HTML «Ссылка недействительна», без CTA к чужим данным / без bind. Рендер в контроллере или один view — без новой shop-route FE.
3. **`bootstrapShopTenant`:** при `sms_entry=1` в query — **не** `navigateToTenant(preferred)`, если currentAllowed; `saveSelectedTenantId` не перебивать ради SMS. Если `!currentAllowed` (закрыта/отключена) — уйти на preferred **с сохранением** `#/profile` **без** `?order=` (S10: история без highlight, без ошибки).
4. **Conflict/confirm** — не переписывать TASK_117; после confirm hash уже `#/profile?order=` — оставить.
5. **Корзина (S11)** — не новый код: TASK_120 сработает при смене точки на точку заказа.
6. **Миграции нет.** Текст/HMAC/TTL/каскад/FCM/платежи — не трогать.

## Файлы (ожидаемо)

- `app/services/shop/order_ready_sms_link.rb` — статус resolve expired/invalid/ok
- `app/controllers/shop/order_short_links_controller.rb` — Location → `#/profile?order=` + `sms_entry`; экраны ошибок без bind
- `app/frontend/lib/shopTenantHeader.js` — pin точки SMS / S10 без highlight при закрытой точке
- `test/integration/shop/order_short_links_test.rb` — редирект, expired/invalid, без session, повторное открытие
- `test/services/shop/order_ready_sms_link_test.rb` — resolve statuses + якорь TTL
- `test/javascript/…` (новый или соседний) — `bootstrapShopTenant` / pin при `sms_entry` (если удобнее unit без браузера — вынести чистую ветку решения)

**Соседи (blast-radius, не обязательно править):**
- `app/frontend/lib/smsSessionTransition.js` — формат `#/profile?order=` после confirm уже есть; сверить, не сломать
- `test/integration/rack_attack_order_short_link_test.rb` / `test/jobs/shop/ready_push_job_test.rb` — регрессия throttle и S8
- `app/frontend/routes/Profile.svelte` / `shopAccountOrders.js` — highlight уже есть; код не менять без нужды

## Не ломать

- Каскад SMS / текст / HMAC / TTL 48h / длина ≤70 (Subtask 9) / провайдер
- TASK_117: conflict → confirm/decline; Location без `reconnect_token`; без тихого overwrite
- TASK_116: история CODE:BLACK + highlight `?order=` ≤3 с
- Оплата / checkout / Quick Repeat / FCM / Wallet / Rack::Attack `/o/`

## Проверка

- `bin/rails test test/integration/shop/order_short_links_test.rb test/services/shop/order_ready_sms_link_test.rb test/services/shop/sms_session_transition_test.rb test/integration/shop/api/sms_session_transition_test.rb`
- `bin/rails test test/integration/rack_attack_order_short_link_test.rb test/integration/shop/api/ownership_idor_test.rb`
- JS зоны: `node --test test/javascript/sms_session_transition_test.mjs` (+ тест pin tenant, если добавим)

## COMPONENT_MAP

**Обновление требуется: нет** — short link + `shopTenantHeader` вне CartSheet/OrderStatus*/GuestOrder*; Profile/highlight не менялись (только Location hash с сервера).
