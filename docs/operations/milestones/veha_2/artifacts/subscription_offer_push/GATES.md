# Gates: TASK_97 — Push-оффер подписки

Scope: `Subscriptions::OfferPushNotifier` шлёт через существующий FCM (`PushNotification` + `Shop::SendPushNotificationJob`) не более одного push на каждый переход `not_shown → shown` в `OfferPresentationService`; нет push при `push_enabled_at = null` / `purchased` / доступном промо 11₽; новый переход (повтор после 3 заказов) → новый push; ошибка FCM логируется и не ломает presentation-flow; push статуса заказа, FCM registration, `subscription_offer_states`, `SubscriptionOfferEligibility`, `GrowthPromo` не меняются.

- [x] G1: OfferPushNotifier — push на shown, `push_enabled_at = null` → нет, idempotency на переход, повтор после нового shown, purchased / промо 11₽ → нет, ошибка FCM не пробрасывается (Subtask 1–8)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_push_notifier_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=22e88e48a12a04c567422791a5c836f4ffa12a27f3eb4b134b3ad2572097e685; exit=0; EXPECT=matched; output-sha256=401db1d296b1a8aa887c65e7f26fa01c2f4d010c2320686af1deaafb723b1c0f; output-bytes=1627; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: OfferPresentationService / state API (TASK_95) — правила состояния не изменились, side-effect подключён только к переходу в shown
  CHECK: ruby bin/rails test test/services/subscriptions/offer_presentation_service_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/services/shop/subscription_offer_eligibility_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=0600911dd19bb7ad3d113bba65c737cfc7bce4f11d2ba560c641b58f034affcb; exit=0; EXPECT=matched; output-sha256=b0a016d4d9b5da9f834f3c635f416137674f794f624ae7b05da9ab43274b9d73; output-bytes=1662; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: push/FCM regression — FCM client, push статуса заказа + Cascade ready, registration flow (Subtask 9)
  CHECK: ruby bin/rails test test/services/shop/fcm_client_test.rb test/services/shop/order_status_push_notifier_test.rb test/services/shop/order_status_push_payload_test.rb test/services/shop/ready_push_claim_test.rb test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb test/integration/shop/api/push_register_test.rb test/integration/shop/push_pipeline_simulation_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=a6b6210abfe2a393c0b1f57312f94c883b77e0d10261051bb74ac7d0e993f9a7; exit=0; EXPECT=matched; output-sha256=7b34c75fecb8463d57058559c4361fff9a8caad4183627955d8da0ba2a88ec12; output-bytes=1665; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: concurrent idempotency — параллельные `mark_shown` / `OfferPushNotifier.call` с одним ключом → ровно 1 push (Проверка TASK_97 «idempotency при параллельных вызовах»)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_push_concurrency_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=8446671f63e527bfce26fbb488c5520c6c6885b1d873afbd18f726d633aecee1; exit=0; EXPECT=matched; output-sha256=3c023037be30cdc586b797dde4e56b7eef33193106efa0403f5c13e54ec922fc; output-bytes=1613; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: /regress зона subscriptions + push + shop jobs (28 файлов, baseline 176/0)
  CHECK: ruby bin/rails test test/services/subscriptions/ test/integration/shop/subscription_offer_funnel_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb test/integration/shop/api/subscription_offer_marketing_events_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/api/subscriptions_api_test.rb test/models/subscription_offer_setting_test.rb test/models/subscription_offer_state_test.rb test/jobs/shop/ test/integration/shop/api/profile_subscription_offer_test.rb test/models/marketing_event_test.rb test/services/shop/subscription_offer_eligibility_test.rb test/services/shop/fcm_client_test.rb test/services/shop/order_status_push_notifier_test.rb test/services/shop/order_status_push_payload_test.rb test/services/shop/ready_push_claim_test.rb test/integration/shop/api/push_register_test.rb test/integration/shop/push_pipeline_simulation_test.rb test/controllers/platform/subscription_offer_settings_controller_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=58846afcec58db7435f6efdf353944dea48e48101676c76148da1ad524fabac7; exit=0; EXPECT=matched; output-sha256=1eba278b470ec55a47bf3aeb488d7edf5f86501ec53e1ddaac629a8ce1d2ec0a; output-bytes=1794; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G4: Fly MCP Point A — после deploy: переход в shown у тестового гостя с push → одна `push_notifications` `subscription_offer`; витрина / статус заказа не сломаны
  EVIDENCE: pending — deploy только по апруву (TASK_95/96 тоже не задеплоены)

<!--
CoffeeOS TASK_97 unlazy:
- TASK_97 ⊂ TASK_96 Subtask 14–21: G1 = TASK_96 G2 (тот же тест-файл, написан на RED TASK_96). Закрытие #97 = G1–G3 met на GREEN TASK_96.
- Пробел: «тест idempotency при параллельных вызовах» (Проверка TASK_97) — сейчас покрыт последовательными повторами + row-lock `with_state`; настоящий concurrent-тест — добавить на GREEN или ABANDON с обоснованием.
- G4 manual, не hot-path оплаты; skip допустим до deploy.
-->
