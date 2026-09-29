# Gates: TASK_96 — Subscription offer frontend, push & analytics

Scope: Гость видит `SubscriptionOfferBanner` на статусе заказа и `SubscriptionOfferCard` в ЛК по флагам профиля (dismiss/viewed/переход с UTM), `OfferPushNotifier` шлёт один push на каждый переход в `shown` (только при `push_enabled_at`, не при purchased/промо 11₽, ошибка FCM изолирована), `marketing_events` пишет события воронки и атрибуцию покупки, есть агрегирующий отчёт; OrderStatus layout / CTA machine / push статуса заказа / PurchaseService-алгоритм не меняются.

- [ ] G1: frontend unit — баннер + карточка ЛК: показ/скрытие, dismiss, viewed, purchased, error-path, UTM deep link, неблокирующий offer_opened (Subtask 1–13, 26–28, 34)
  CHECK: node --test test/javascript/subscription_offer_banner_test.mjs test/javascript/subscription_offer_card_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G2: OfferPushNotifier — push на shown, без push_enabled_at нет, idempotency на переход, повтор после нового shown, purchased/промо 11₽ нет, ошибка FCM не пробрасывается (Subtask 14–21, 29)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_push_notifier_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G3: marketing_events — модель + banner_shown / banner_dismissed / lk_viewed / offer_opened / push_opened из API (Subtask 22–26, 30)
  CHECK: ruby bin/rails test test/models/marketing_event_test.rb test/integration/shop/api/subscription_offer_marketing_events_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [ ] G4: атрибуция покупки + отчёт воронки — subscription_purchased с UTM последнего offer_opened, ошибка логирования не откатывает покупку, агрегация по event_type/channel (Subtask 31–33)
  CHECK: ruby bin/rails test test/integration/shop/subscription_offer_funnel_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: pending

- [x] G5: backend regression — TASK_95 состояние оффера, покупка подписки, FCM/push статуса заказа + Cascade ready (Subtask 36)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_presentation_service_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb test/services/subscriptions/purchase_service_test.rb test/services/subscriptions/confirm_payment_service_test.rb test/integration/shop/api/subscriptions_api_test.rb test/services/shop/fcm_client_test.rb test/services/shop/order_status_push_notifier_test.rb test/services/shop/order_status_push_payload_test.rb test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb test/integration/shop/api/push_register_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1efa06cc2f63f5f35bbc98307812d253214cc01bcf9d8df9bb12c9bd7246faf2; exit=0; EXPECT=matched; output-sha256=be99dc91a6780625a0f1e0b6e718b2c97388dd2f6db2c9f1e3e2514bcdbba2aa; output-bytes=1704; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: frontend regression — OrderStatus CTA machine / sheet / push subscribe / notify не сломаны
  CHECK: node --test test/javascript/order_status_cta_machine_test.mjs test/javascript/order_status_sheet_test.mjs test/javascript/order_status_push_subscribe_test.mjs test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs test/javascript/order_status_active_poll_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=75c43d408eb7b1fe9927316413fa41c9f95aa8d05d3012794f34b9390fbf46b9; exit=0; EXPECT=matched; output-sha256=0acf10777c102f290f944504881b48e9ec265dba2627687b3b6adf774ed2277e; output-bytes=19811; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G7: hot-path Fly MCP Point A + E2E — баннер на ready, dismiss, переход в оформление, карточка ЛК, гашение unread; витрина/корзина/статус не сломаны (Subtask 35)
  EVIDENCE: pending — после deploy по апруву (TASK_95 тоже не задеплоен)

<!--
CoffeeOS TASK_96 unlazy:
- G1–G4 — новые тест-файлы (RED на /sbr); пути уточнить на /spec, при смене — обновить CHECK и заново --approve.
- G5–G6 — существующие файлы, должны быть зелёными до и после.
- G7 manual; Fly после deploy (апрув).
- SPEC 2026-09-29: весь scope в TASK_96 (G2–G4 остаются); ЛК = `Profile.svelte`; mark_shown = `POST subscription_offer/shown` (#95); `npx tsc` не применим; E2E-раннера нет → G7 Fly MCP browser.
- BLOCKED: экрана оформления подписки во frontend нет (billing UI, Задача-3) — `/sbr` после снятия блокера.
-->
