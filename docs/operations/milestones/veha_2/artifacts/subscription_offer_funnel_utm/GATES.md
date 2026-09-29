# Gates: TASK_98 — События воронки и UTM-атрибуция

Scope: `marketing_events` пишет 7 событий воронки оффера (banner_shown / banner_dismissed / lk_viewed / offer_opened / push_sent / push_opened / subscription_purchased) с каналом и UTM; покупка получает атрибуцию последнего offer_opened/push_opened; UTM и offer_channel идут через deep link, клик не блокирует навигацию; `/manager/subscription_offer_funnel` агрегирует по event_type × channel и на пустом диапазоне отдаёт нули без 500; `subscription_offer_states`, `OfferPresentationService`, `OfferPushNotifier`, `SubscriptionOfferEligibility`, `GrowthPromo`, `PurchaseService`, `admin_audit_logs` по бизнес-логике не меняются.

- [x] G1: модель + события из API — banner_shown (mark_shown), banner_dismissed, lk_viewed, offer_opened (banner/lk + UTM), push_opened; ошибка логгера не ломает flow (Subtask 1–5, 7)
  CHECK: ruby bin/rails test test/models/marketing_event_test.rb test/integration/shop/api/subscription_offer_marketing_events_test.rb
  EXPECT: /[1-9][0-9]* runs, [0-9]+ assertions, 0 failures, 0 errors/
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=a902905d04687e5addb853e4d87ea28fd9354e8e103b9c088c4d54f6039face3; exit=0; EXPECT=matched; output-sha256=a1205553af9f37db2e38b75c9e6c30b4be3ca9c333dd32d46b248363b1d9b67b; output-bytes=1627; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: push_sent только на успешную доставку offer push; ошибка FCM → нет push_sent, без raise (Subtask 6)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_push_notifier_test.rb
  EXPECT: /[1-9][0-9]* runs, [0-9]+ assertions, 0 failures, 0 errors/
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=c8fefb4106adecbc3255a7cc2c3e9132d35ed23d72ec14197577af55594ac6db; exit=0; EXPECT=matched; output-sha256=f6c2f81acbac96211a71bcbcef6f7ed9e90558ffb4569478ccd3ab37d534475b; output-bytes=1626; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: subscription_purchased + атрибуция в subscriptions.utm_* / offer_channel из последнего open; ошибка аналитики не откатывает покупку; отчёт по event_type × channel с фильтром точки (Subtask 10–11)
  CHECK: ruby bin/rails test test/integration/shop/subscription_offer_funnel_test.rb
  EXPECT: /[1-9][0-9]* runs, [0-9]+ assertions, 0 failures, 0 errors/
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=693c13a19c005853968ead9a0b1b3dae28f499dfa4fa0cc5287cbf0ab22b73ef; exit=0; EXPECT=matched; output-sha256=cb7b52843b697594ea1c35468127b5659987c755937296809382ee3a0a7613c1; output-bytes=1625; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: frontend — deep link с utm_campaign / utm_content / offer_channel из баннера и карточки ЛК, offer_opened не блокирует навигацию (Subtask 8–9)
  CHECK: node --test test/javascript/subscription_offer_banner_test.mjs test/javascript/subscription_offer_card_test.mjs
  EXPECT: fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=774a61bc181ed3033ab20700fce7b70a4f7cabdca40f9c581ce4c15e4a11edca; exit=0; EXPECT=matched; output-sha256=e38d49ebfd6849051efd0a6a47d19b63a105927a39908fb07346a56b938cf263; output-bytes=8617; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: пустой диапазон отчёта → нулевые/пустые totals и rows, JSON-эндпоинт 200 без 500 (Subtask 11, «отсутствие событий») — тест ещё не написан, RED на /sbr
  CHECK: ruby bin/rails test test/integration/shop/subscription_offer_funnel_test.rb -i /empty/
  EXPECT: /[1-9][0-9]* runs, [0-9]+ assertions, 0 failures, 0 errors/
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=41e70761e6b52f7136edf19eab9be08edbf22b2cc3616575dbb135889876faeb; exit=0; EXPECT=matched; output-sha256=070b9a8c262ababa1cac4a8434cfc408a326e61da98f19326d9db6d2568fb80b; output-bytes=1624; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: регрессия зоны — состояние оффера, eligibility, покупка, FCM/push статуса заказа, concurrent offer push (Subtask 12)
  CHECK: ruby bin/rails test test/services/subscriptions/offer_presentation_service_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/services/shop/subscription_offer_eligibility_test.rb test/services/subscriptions/purchase_service_test.rb test/services/subscriptions/confirm_payment_service_test.rb test/integration/shop/api/subscriptions_api_test.rb test/services/subscriptions/offer_push_concurrency_test.rb test/services/shop/fcm_client_test.rb test/services/shop/order_status_push_notifier_test.rb test/jobs/shop/ready_push_job_test.rb
  EXPECT: /[1-9][0-9]* runs, [0-9]+ assertions, 0 failures, 0 errors/
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=d098a984052cf716e2cb790de5dbcf26b3372130503ad0703087f4f44fe88f69; exit=0; EXPECT=matched; output-sha256=3d75b488e3505537543e2144064c1f88afb2e2214775782e65402ae62ff82d29; output-bytes=1700; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [ ] G7: Fly MCP Point A — после deploy: у тестового гостя события воронки в `marketing_events`, отчёт `/manager/subscription_offer_funnel` 200; витрина / статус заказа не сломаны
  EVIDENCE: pending — deploy только по апруву (TASK_95/96/97 тоже не задеплоены)

<!--
CoffeeOS TASK_98 unlazy:
- TASK_98 ⊂ TASK_96 Subtask 22–33: реализация уже в `63a317a1` (GREEN #96). G1–G4 = те же тест-файлы, что TASK_96 G1/G3/G4 + push_sent из G2.
- Единственный найденный пробел — G5 (пустой отчёт не покрыт тестом). Если на RED тест сразу зелёный — код не трогать, закрыть G5 тестом.
- Хранилище: отдельная таблица `marketing_events` (не admin_audit_logs) — решение TASK_96, совместимо с ТЗ.
- G7 manual; skip допустим до deploy.
-->
