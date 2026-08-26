# todo — #69 PWA ЛК (личный кабинет)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| /regress #69 PASS local | Ruby 24/0 · Node 6/0 | /review |

**CBR:** #69  
**ТЗ:** [`customer_tasks/Доработка личного кабинета (ЛК) в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Доработка%20личного%20кабинета%20(ЛК)%20в%20PWA.md)  
**Артефакты:** [`artifacts/pwa_personal_account_lk/`](../milestones/veha_2/artifacts/pwa_personal_account_lk/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** задача 1 из трёх (TG-support, ЛК, email-after-pay). Не ломать #64–#68 WebView, CartSheet, checkout, payments.

## Цель (1 предложение)

Завершить сценарий ЛК в PWA по макету: hub с историей заказов, экран деталей (без ОФД), настройки/контакты, «О нас», bottom sheet «Написать нам», logout — на существующих shop API без новых внешних интеграций.

## Acceptance (DoD) — ключевое

1. `#/profile` — hub ЛК: шапка (аватар, имя, chat), 2 PLG-placeholder, история заказов с «Повторить», empty/error states.
2. `#/profile/settings` — имя, уведомления (local prefs до backend API), контакты OTP, «О нас», «Написать нам», ВЫХОД.
3. `#/order/:id/receipt` — детали заказа по UX-ref (items/total), stub ОФD-текст, кнопка ПОВТОРИТЬ без бизнес-логики.
4. `#/about` — версия/build, copy, legal links из config, footer.
5. Bottom sheet email/TG — config URLs, не хардкод в компоненте.
6. `DELETE /shop/api/session` — logout customer session (shop/api, не auth/**).
7. Без ОФD API, PLG-бизнес-логики, subscription/referral, правок checkout/payments.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] RED (slice 2: runtime API logout/history)
- [x] GREEN (slice 1 + slice 2 logged_out contract)
- [x] /regress local PASS
- [ ] REVIEW / Fly MCP Point A

## Файлы (hot-path)

- `app/frontend/routes/Profile.svelte` — hub ЛК (переписать)
- `app/frontend/routes/AccountSettings.svelte` — **новый** settings
- `app/frontend/routes/AboutUs.svelte` — **новый** «О нас»
- `app/frontend/routes/OrderReceipt.svelte` — **новый** детали заказа
- `app/frontend/lib/shopAboutConfig.js` — **новый** legal/support/version config
- `app/frontend/lib/shopPlgBlocks.js` — **новый** PLG config interface
- `app/frontend/lib/shopAccountOrders.js` — **новый** fetch history helper
- `app/frontend/components/PlgBlockSection.svelte` — **новый**
- `app/frontend/components/ContactSupportSheet.svelte` — **новый**
- `app/frontend/App.svelte` — маршруты `/profile/settings`, `/about`, `/order/:id/receipt`
- `app/controllers/shop/api/orders_controller.rb` — `title`/`order_number` в history JSON
- `app/controllers/shop/api/session_controller.rb` — `destroy` logout
- `app/services/shop/customer_session.rb` — `clear!`
- `test/integration/shop/pwa_personal_account_lk_test.rb` — **новый** grep/API contract
- `test/integration/shop/api/pwa_lk_api_test.rb` — **новый** runtime logout/history
- `test/javascript/shop_personal_account_lk_test.mjs` — **новый** config/helpers

### Blast-radius (+3)

- `test/integration/shop/profile_ui_contract_test.rb` — *почему: контакты переехали в AccountSettings*
- `app/frontend/routes/Orders.svelte` — *почему: старый `/orders` не должен регресснуть*
- `docs/integrations/shop-api.md` — *почему: history fields + DELETE session*

## Не ломать

- Header «Профиль › ID» (B1.13-S1), CartSheet канон, checkout autofill profile, OTP link email/phone merge
- `#/order/:id` OrderStatus (активный заказ) — отдельный от receipt
- WebView #66–#68, tenant RLS, payment/webhook контракты

## Проверка

- `bundle exec ruby -Itest test/integration/shop/pwa_personal_account_lk_test.rb test/integration/shop/api/pwa_lk_api_test.rb test/integration/shop/profile_ui_contract_test.rb test/integration/shop/api/orders_controller_test.rb test/services/shop/customer_session_test.rb`
- `node --test test/javascript/shop_personal_account_lk_test.mjs`

Fly MCP Point A — после GREEN + deploy.

## Открытые вопросы (не блокер slice 1)

- Финальные Google Docs URL, Telegram bot URL, legal entity — placeholder в `shopAboutConfig.js` + `VITE_*` env.
- Backend API notification toggle — interim `localStorage` до отдельного контракта.
