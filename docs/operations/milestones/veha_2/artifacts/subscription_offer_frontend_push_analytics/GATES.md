# Gates: TASK_96 — Subscription offer frontend, push & analytics

Scope: Гость видит `SubscriptionOfferBanner` на статусе заказа и `SubscriptionOfferCard` в ЛК по флагам профиля (dismiss/viewed/переход с UTM), `OfferPushNotifier` шлёт один push на каждый переход в `shown` (только при `push_enabled_at`, не при purchased/промо 11₽, ошибка FCM изолирована), `marketing_events` пишет события воронки и атрибуцию покупки, есть агрегирующий отчёт; OrderStatus layout / CTA machine / push статуса заказа / PurchaseService-алгоритм не меняются.

- [x] G1: frontend unit — баннер + карточка ЛК: показ/скрытие, dismiss, viewed, purchased, error-path, UTM deep link, неблокирующий offer_opened (Subtask 1–13, 26–28, 34)
  CHECK: node --test test/javascript/subscription_offer_banner_test.mjs test/javascript/subscription_offer_card_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=774a61bc181ed3033ab20700fce7b70a4f7cabdca40f9c581ce4c15e4a11edca; exit=0; EXPECT=matched; output-sha256=333025612fed604071e0a2a40125ad72afd78cedcfc28986ac3b3749ea129c76; output-bytes=8626; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: OfferPushNotifier — push на shown, без push_enabled_at нет, idempotency на переход, повтор после нового shown, purchased/промо 11₽ нет, ошибка FCM не пробрасывается (Subtask 14–21, 29)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_push_notifier_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=22e88e48a12a04c567422791a5c836f4ffa12a27f3eb4b134b3ad2572097e685; exit=0; EXPECT=matched; output-sha256=3af8208f98a7a0ca97b26da363b13599f16c34fe5505f34e222fa8425b347aa6; output-bytes=1626; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: marketing_events — модель + banner_shown / banner_dismissed / lk_viewed / offer_opened / push_opened из API (Subtask 22–26, 30)
  CHECK: ruby bin/rails test test/models/marketing_event_test.rb test/integration/shop/api/subscription_offer_marketing_events_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=4cae4a383745bbdd5159390dd4082842d4f1d9c822b1fcb4b07c1a886a25bf92; exit=0; EXPECT=matched; output-sha256=d84f961b66e7b4bc8515aa0c0bf328c42542c817c3d472ddb1d56293a6d733e6; output-bytes=1631; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: атрибуция покупки + отчёт воронки — subscription_purchased с UTM последнего offer_opened, ошибка логирования не откатывает покупку, агрегация по event_type/channel (Subtask 31–33)
  CHECK: ruby bin/rails test test/integration/shop/subscription_offer_funnel_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=55caeeb09347acc1abeef09e5cc62e19e767b5abe4dfc03f04dc7f0f104cc8b1; exit=0; EXPECT=matched; output-sha256=1178a4229c91d24fd9c791df3641dc07be6ccb84f0e5ce0018879f59d4b42a85; output-bytes=1619; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: backend regression — TASK_95 состояние оффера, покупка подписки, FCM/push статуса заказа + Cascade ready (Subtask 36)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_presentation_service_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb test/services/subscriptions/purchase_service_test.rb test/services/subscriptions/confirm_payment_service_test.rb test/integration/shop/api/subscriptions_api_test.rb test/services/shop/fcm_client_test.rb test/services/shop/order_status_push_notifier_test.rb test/services/shop/order_status_push_payload_test.rb test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb test/integration/shop/api/push_register_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=1efa06cc2f63f5f35bbc98307812d253214cc01bcf9d8df9bb12c9bd7246faf2; exit=0; EXPECT=matched; output-sha256=24699bd3c5b356de75297791a9ec1a50f790565724fe5a7753c168a0b69765c9; output-bytes=1706; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: frontend regression — OrderStatus CTA machine / sheet / push subscribe / notify не сломаны
  CHECK: node --test test/javascript/order_status_cta_machine_test.mjs test/javascript/order_status_sheet_test.mjs test/javascript/order_status_push_subscribe_test.mjs test/javascript/order_status_notify_actions_test.mjs test/javascript/order_status_notify_init_test.mjs test/javascript/order_status_active_poll_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=75c43d408eb7b1fe9927316413fa41c9f95aa8d05d3012794f34b9390fbf46b9; exit=0; EXPECT=matched; output-sha256=9bb35654c0f0b89a21dd7e3a0316478f051d85d376df801c9649899d5602d8bc; output-bytes=19807; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

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
