# ISSUES

> Канон (`coffeeos-commit-ops.mdc`, `RULES_INDEX.md`): баг фиксируется здесь **сразу**; статус до **«решено»** + **чем закрыли** (код, тесты, миграции).
>
> **Агент на старте чата:** читай **только секцию `## 🔴 Открыто`** (до следующего `##`). Детали — по ссылке «→ полная запись» ниже. Архив — когда файл раздуется до тысяч строк (сейчас не делаем).

## 🔴 Открыто

| Дата | ID / тема | Статус | Следующий шаг |
|------|-----------|--------|---------------|
| 2026-07-16 | **UserCards** save_card / delayed RebillId | 🟡 Fly v444 MCP 8925 ✅ · апрув 3.5 ❌ · E2E real PAN ⛔ | Апрув скрина 8925; E2E только real MIR; → полная запись |
| 2026-07-16 | **Checkout UX** stacked sheet (Фаза 2) | 🟡 на Fly v445 · MCP pay-stack status hidden ✅ · апрув ❌ | Апрув заказчика; → полная запись |
| 2026-07-31 | **Legacy shop suite** (~3–4 fail после triage) | 🔴 open | silent_refresh structural **fixed** Group1; остальное отдельно; → полная запись |
| 2026-08-13 | **CI job `test`** / 4 legacy shop exclude | 🟢 CI #31 green · exclude 4 legacy | triage 4 legacy отдельно (не гейт); → полная запись |
| 2026-07-27 | **SBP 3001** на Fly | 🟡 банк / кабинет | После UI-enable: push+deploy+MCP; если снова 3001 — кабинет NSPK; → полная запись |
| 2026-07-28 | **Fly Test** в шапке Арама | 🟡 код local ✅ | push + deploy + MCP Point A; → полная запись |
| 2026-08-08 | **#47** PWA статусы + повторы | 🟡 на Fly v445 · MCP surface ✅ · апрув ❌ | Апрув заказчика; → полная запись |
| 2026-07-21 | **Windows** полный `test/integration/shop/` зависает | 🟡 env | Таргетные файлы / CI; не полный suite локально; → полная запись |

---

## Решено недавно (детали)

[2026-08-13] — Pay NET_ERROR: сырой `Failed to fetch` в PaymentMethodsSheet
**Статус:** **resolved** Fly **v451** MCP PASS
**Источник:** MCP Point A v450
**Root cause:** Checkout `sheetInlineError = e.message` при pay inline.
**Чем закрыли:** `resolveCheckoutSheetInlineError` → null для NET/CLIENT/BANK.
**Проверка:** local JS 9/0 · MCP v451 offline: CTA «Нет связи. Повторить», alerts без Failed to fetch.
**Evidence:** `mcp/fly_2026-08-13_recheck/MCP_RESULT.md`

[2026-08-13] — A6 Repeat: `has_active_order=true` после guest cancel
**Статус:** **resolved** Fly **v452** MCP PASS
**Источник:** MCP Point A v450/v451
**Root cause:** нет bust на cancel + race: poll frequent перезаписывал SolidCache после delete-only.
**Чем закрыли:** `refresh_cache!` (bust+write) в GuestOrderCancellation; FE clear LS.
**Проверка:** cancel #202608-0041 → без reload `has_active_order=false` · frequent×3 · «повторить».
**Evidence:** `mcp/fly_2026-08-13_recheck/MCP_RESULT.md`

[2026-08-12] — Кнопка СБП «не активна» в PaymentMethodsSheet
**Статус:** **resolved** (local; push/deploy/MCP — ждёт)
**Источник:** заказчик · «кнопка СБП не активна»
**Root cause:** #26 G4 — hardcoded `disabled` + toast `sbpUnavailable` вместо `onSelectSbp` (не кабинет Т-Кассы).
**Чем закрыли:** unlock row СБП / счёт СБП → `onSelectSbp` / `onSelectSbpAccount`; тесты UI/CBR обновлены.
**Проверка:** `sbp_payment_ui` + `checkout_acceptance_cbr` + `repeat_invalid_token` + `checkout_ui_cleanup` + `user_cards_sbp_accounts` → 29/0.
**Осталось:** push + deploy + Fly MCP Point A; банк 3001 — отдельно.

[2026-08-09] — Legacy shop suite triage: regression fixed + messenger OTP — тесты актуализированы под реальный флоу заказчика
**Статус:** **resolved**
**Источник:** плановый triage `test/integration/shop/` (C из очереди) по запросу владельца
**Regression (resolved, `1582f078`):** `test/integration/shop/shop_second_card_step5_test.rb` + `shop_save_card_false_step6_test.rb` — `Override#init_payment` с фиксированной сигнатурой без `receipt:`; ломало `ArgumentError: unknown keyword: :receipt` любой тест дальше в prepend-цепочке `TbankAdapter`. Фикс: `**` для форвард-совместимости (как у остальных стабов).
**Messenger OTP — проверено по git log, не код-баг:** канал `messenger` был **осознанно снесён** двумя коммитами рефакторинга (`b2685910` cascade flash_call×2→SMS через SmsRuClient, `8b76da10` "remove messenger from Rack::Attack and Svelte" + `8d94b95b` dead code). У заказчика сейчас в `PhoneAuthWizard`/`PhoneAuthCodeStep.svelte` **нет** кнопки мессенджера — только flash_call (основной) + SMS (fallback, требует уже существующий код). Это подтверждённый текущий продукт, не пропуск.
**Чем закрыли:** актуализировали тесты под реальный флоу (а не добавляли messenger обратно — это было бы "придумать своё"):
- `phone_otp_test.rb` — happy path / sms-throttle / "links phone" переведены с `channel: "sms"` (не работает на новом номере) на `channel: "flash_call"`; 3 теста про `messenger` (throttle 30s, send messenger, messenger_delivery_error) удалены — фичи нет.
- `profile_merge_test.rb` — `bind_via_phone!` и `link_phone` тест переведены с `sms` на `flash_call` (реальный вход в OTP).
- `auth_funnel_wizard_ui_test.rb` — тест "messenger and sms fallback" сужен до реального "sms fallback" (без messenger-ассертов).
**Проверка:** `bin/rails test test/integration/shop/api/phone_otp_test.rb test/integration/shop/api/profile_merge_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb` → 17 runs, 0 failures.
**Остальной легаси suite (не трогали, отдельная итерация):** `payment_status_error_code_test.rb` (ErrorCode 1051 nil), `active_orders_receipt_test.rb` (`NoMethodError` nil.key?), `order_status_acceptance_cbr_test.rb`, `shop_user_cards_extremes_test.rb#E7`. *(silent_refresh_frontend_structural — fixed 2026-08-10 Group 1 `ef3ad4ce`)*
**Полный прогон после фикса:** `test/integration/shop/` → 502 runs, 3289 assertions, 4 failures, 1 error, 3 skips (только известный хвост выше, без новых регрессий).

[2026-08-08] — #47 Статусы с табло не sync в PWA; повторы после заказа пустые
**Статус:** 🟡 **MCP PASS** Fly **v443** · апрув заказчика `[ ]`
**Источник:** Арам · [`Статусы с табло не подтягиваются…`](milestones/veha_2/requirements/customer_tasks/Статусы%20с%20табло%20не%20подтягиваются%20в%20PWA%20и%20повторы%20после%20заказа.md) · скрин `01_aram_empty_sheet_plus0.png`
**Симптом:** смена статуса на табло → PWA только после reload; после покупки «повторы»/история не подгружаются (пустая шторка +0₽).
**Root cause:** live-path только ActionCable; нет polling `/orders/active`; frequent refresh после terminal в основном по Cable.
**Чем закрыли (код):** `ACTIVE_ORDERS_POLL_MS` + visibility; `refreshActive` → `refreshFrequentProducts`. JS 32/0 · Fly **v443**.
**Evidence:** [`mcp/fly_v443_2026-08-08/`](milestones/veha_2/artifacts/pwa_status_sync_and_repeats_stale/mcp/fly_v443_2026-08-08/) — ready→issued без F5 → «повторить» ×3.
**Осталось:** апрув заказчика «ок».
**Deploy:** Fly **v443** · `deployment-01KZGG9538YYB9ZE5YBTEN9PQS` · `/up` 200 (2026-08-08).

[2026-08-07] — #46 Сбой банка: лимит авторизаций блокирует оплату / статусы
**Статус:** **resolved** 2026-08-07 · Fly **v441** · MCP PASS
**Источник:** заказчик · [`Сбой банка…`](milestones/veha_2/requirements/customer_tasks/Сбой%20банка%20не%20могу%20оплатить%20заказ%20для%20статусов.md) · скрин `01`
**Симптом:** «Превышено допустимое количество запросов авторизации операции» + CTA «Сбой банка: позже»; нельзя оплатить → статусы не сменяются.
**Root cause:** ErrorCode `119`/`2200` (банк) + UX blind-retry той же карты + widget `charge_existing!` на том же PaymentId после REJECTED Charge.
**Чем закрыли:** clear `provider_payment_id` после fail Charge; FE `119`/`2200` → `CLIENT_ERROR` (сменить карту); BE friendly message. MCP v441: *5953→119+NewCardForm; *8782→«Оплачен».
**Evidence:** [`mcp/fly_v441_2026-08-07/`](milestones/veha_2/artifacts/bank_auth_limit_blocks_payment/mcp/fly_v441_2026-08-07/)
**Осталось:** апрув заказчика «ок»; СБП 3001 кабинет — отдельно.

[2026-08-06] — Peek корзины пропадал при активном статусе заказа
**Статус:** **resolved** 2026-08-06 (локально; push/MCP — ждёт апрув)
**Источник:** владелец · скрин статусной шторки на каталоге / карточка товара
**Root cause:** follow-up `hideCartTail` (`19231620`) — mutex: `hasActiveOrder` ⇒ не рендерить peek/expanded/single; add в корзину не виден.
**Чем закрыли:** убрали `hideCartTail`; статус + позиции стык в стык; `STATUS_IN_SHEET_EXTRA_VH`; empty placeholder скрыт при активном заказе без позиций; build `prog38`. Тесты: `active_order_cart_peek_stack_test` + cart sheet zone 57/0.

[2026-08-06] — #43 После #42 пропали повторы / кнопки / история частот
**Статус:** **resolved** 2026-08-06 · Fly **v434** · MCP PASS
**Источник:** Арам · [`После 42 пропали повторы…`](milestones/veha_2/requirements/customer_tasks/После%2042%20пропали%20повторы%20в%20шторке%20и%20история%20покупок.md)
**Root cause:** `has_active_order?` без TTL → June accepted → hide «повторить».
**Чем закрыли:** TTL 24h (= #42) на `has_active_order?`; bust cache; MCP 3× «оплатить в 1 клик». Evidence: [`mcp/fly_v434_2026-08-06/`](milestones/veha_2/artifacts/repeat_hidden_by_stale_active_orders/mcp/fly_v434_2026-08-06/).

[2026-08-05] — #42 Зависшие June accepted в шторке #35 блокируют оплату Point A
**Статус:** **resolved** 2026-08-05 · Fly **v433** · MCP PASS
**Источник:** Арам · чат · [`customer_tasks/Зависшие заказы…`](milestones/veha_2/requirements/customer_tasks/Зависшие%20заказы%20в%20статусной%20шторке%20PWA%20блокируют%20оплату.md)
**Root cause:** `orders/active` без TTL → старые `accepted` вечно в sheet; peek `min(40vh,16rem)` съедает экран. На табло нет: фильтр открытой смены (`created_at >= shift.opened_at` / cash_shift).
**Чем закрыли:** TTL 24h на `#active` + peek `min(22vh,8.5rem)`; deploy v433; MCP Aram `orders/active=[]`, June не в DOM, CTA `+3₽` видна. Evidence: [`mcp/fly_v433_2026-08-05/`](milestones/veha_2/artifacts/stuck_orders_status_sheet_blocks_payment/mcp/fly_v433_2026-08-05/).
**Backlog:** SM filter NULL-shift; sync payment `processing` после callback.

[2026-08-05] — Fly coffeeos edge FRA: 503 «could not find a good candidate within 40 attempts at load balancing»
**Статус:** **resolved** 2026-08-05 · redeploy **v430/v431** · `/up` 200 стабильно
**Источник:** MCP #41 cancel follow-up после `fly machine restart`
**Чем закрыли:** `fly apps restart` + повторный `fly deploy` (v431); cancel MCP PASS на v431.
**Артефакт:** [`mcp/fly_v431_2026-08-05/`](milestones/veha_2/artifacts/order_action_buttons_status_panel/mcp/fly_v431_2026-08-05/)

[2026-07-31] — Fly v415: Quick Repeat не скрыт и status sheet не на всю ширину
**Статус:** **resolved** 2026-07-31 · Fly **v416** · re-verify **v417** MCP PASS (hide + full-width + one-open)
**Источник:** фидбек заказчика + `artifacts/quick_repeat_bottom_sheet/screenshots/07_…png`
**Root cause:** FE не читал `has_active_order`; legacy `right/max-width` у OrderStatusSheet.
**Чем закрыли:**
- BE: `HIDE_REPEAT_STATUSES` + `has_active_order` + cache v3 + barista `bust_cache!` (`01c61262`)
- FE: `hasActiveOrder` / `showRepeat` + Cable `onTerminal` refresh (`ba0abf7f`)
- Layout: `OrderStatusSheet` `left:0; right:0; width:100%` (z60)
- Push develop `0b71d5f9` · deploy **v416** · Fly MCP [`mcp/fly_v416_2026-07-31/`](milestones/veha_2/artifacts/quick_repeat_bottom_sheet/mcp/fly_v416_2026-07-31/) — API `has_active_order:true`+`[]`, UI без «повторить», sheet `390/390` z60.
- Re-verify: push `6fa90731` · deploy **v417** · MCP [`mcp/fly_v417/`](milestones/veha_2/artifacts/quick_repeat_bottom_sheet/mcp/fly_v417/) — peek/expanded/one-open PASS.

[2026-07-31] — Полная shop regression: 24 legacy OTP/structural failures
**Статус:** 🔴 **open**, не из diff #35 (после triage 2026-08-09: ~4–5 fail осталось)
**Источник:** после MCP fix #35: `bundle exec rails test test/integration/shop/`
**Факт:** 460 runs, 2893 assertions, **24 failures**, 0 errors, 3 skips; примеры — phone/profile OTP ожидали старый messenger flow, structural tests ищут удалённые frontend symbols.
**#35:** targeted mount 5/5 + JS 14/14 + Vite build PASS.
**Осталось:** отдельный triage/fix legacy shop suite; не пакетить в #35.

[2026-07-31] — #35 status sheet скрыта под CartSheet + WS reconnect loop
**Статус:** **resolved** 2026-07-31 · Fly **v414** · MCP PASS (labels/track/z60)
**Источник:** MCP DevTools Fly, сравнение с `artifacts/order_status_compact_sheet_push/screenshots/`
**Root cause:** `OrderStatusSheet` имела `z-index:40`, а CartSheet — `50`; initial `connected` вызывал `refreshActive→resubscribe→connected` по кругу.
**Чем закрыли:** `e2f69ec2` layering/reconnect · `3bbd62a8` labels+track · deploy v414 · evidence `artifacts/…/mcp/`

[2026-07-28] — Шапка «ул. Fly Test» у Арама (inactive last_ordered)
**Статус:** 🟡 **код local PASS** · deploy/MCP `[ ]`
**Источник:** скрин заказчика «Хотя уже лучше» · адрес Fly Test при телефоне ок
**Root cause:** `last_ordered_tenant_id` = inactive Fly Overnight (`af4f78d6`, 7 заказов 2026-07-28) свежее Point A → preferred=Fly Test → bootstrap не уводил.
**Чем закрыли (код):** `resolvePreferredTenantId` только active · bootstrap bounce `!currentAllowed` · history skip inactive last_ordered
**Осталось:** push + fly deploy + MCP шапка Ленин

[2026-07-28] — В профиле Арама тестовый телефон вместо настоящего
**Статус:** **resolved** 2026-07-28 · prod `link_phone!` + merge
**Источник:** скрин владельца · настоящий номер `+79639124847`
**Root cause:** MCP OTP тестовыми `+79001119932` / `+79001119877` перезаписал phone; настоящий лежал на отдельном donor `e01d7bd4-…`.
**Чем закрыли:** `Shop::CustomerProfileMerger.link_phone!(…, "+79639124847")` на survivor `2bc37279-…` · merge donor · [`fly_aram_real_phone_link_2026-07-28.json`](milestones/veha_2/artifacts/aram_phone_restore/fly_aram_real_phone_link_2026-07-28.json)
**Правило:** не гонять phone OTP MCP на профиле заказчика тестовым номером.
**ТЗ:** [`Вернуть номер телефона Арама в профиле.md`](milestones/veha_2/requirements/customer_tasks/Вернуть%20номер%20телефона%20Арама%20в%20профиле.md)

[2026-07-28] — Пропали рекомендации / «повторить» у Арама (Fly Test)
**Статус:** **resolved** 2026-07-28 · Fly **v399** · MCP PASS
**Источник:** заказчик Арам · скрин `artifacts/repeat_recommendations_missing/screenshots/01_…`
**Root cause:** витрина на `Fly Overnight` (`af4f78d6…`, ул. Fly Test) — 0 заказов; «повторить» на Point A (`2fdee1ac…`) жив (freq=3). Sticky selected + inactive current в `/tenants` + bootstrap до Silent Refresh.
**Чем закрыли:** restore→bootstrap · `resolvePreferredTenantId` · history без inactive current · deactivate Fly Overnight · deploy v399 · MCP [`fly_mcp_repeat_restored_2026-07-28.json`](milestones/veha_2/artifacts/repeat_recommendations_missing/fly_mcp_repeat_restored_2026-07-28.json) · скрин `02_fly_aram_point_a_repeat_restored.png`
**ТЗ:** [`Пропали рекомендации повторить на витрине.md`](milestones/veha_2/requirements/customer_tasks/Пропали%20рекомендации%20повторить%20на%20витрине.md)

[2026-07-27] — SBP live на Fly: банк отклоняет СБП
**Статус:** 🟡 **открыт** · UI/OTP/WAITING PASS · код Receipt.Email **задеплоен v396** · UX 3001 friendly **v398/v399**
**Источник:** MCP Aram E2E · скрины `screenshots/01–07`
**Улика v395:** `ErrorCode 329` Неверные параметры (Receipt без Email) — **закрыто кодом** `d1328b9`
**Улика v396:** `ErrorCode 3001` **«Оплата через СБП недоступна»** — ответ Т-Кассы после успешного Formal Init path
**Root cause 3001:** на терминале `TBANK_TERMINAL_KEY=1719235292309` в кабинете Т-Банка **не включён СБП** / нет тарифа NSPK (не баг приложения).
**UX fix 2026-07-28:** сырой `Т-Банк API error 3001…` → «СБП сейчас недоступна… картой / позже» (BE+FE).
**Осталось:** владелец включает СБП в кабинете Т-Кассы → повторный MCP → `qr.nspk.ru`

[2026-07-16] — UserCards: карта не сохранилась после оплаты с save_card ON (bug_13-23)
**Статус:** 🟡 **открыт** · код 3.3 **[x]** · Fly **v444** · MCP 8925 **[x]** 2026-08-10 · апрув 3.5 **[ ]** · E2E real PAN **⛔**
**Источник:** заказчик · [`bug_13-23_repeat_purchase_card_missing.png`](../milestones/veha_2/artifacts/usercards_save_card/screenshots/bug_13-23_repeat_purchase_card_missing.png)
**Root cause (Фаза 0):** webhook RebillId enqueued, worker stopped → SavedCardStore не вызван.
**Root cause (Фаза 3.2, платёж 8866531465 / 09:56):** FA CONFIRMED **без RebillId/Pan** → settle + однократный GetState не дожали; банк прислал RebillId *8782 только **2026-07-17** (delayed webhook). Init Recurrent=Y ожидаем при save_card=true. **Наш баг:** нет retry GetState / delayed sync — карта не в 8925 в день оплаты.
**Артефакт:** [`usercards_fly_payment_root_cause_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json)
**Фикс Фаза 1 (код + deploy v362):** `TbankController` perform_now · `SOLID_QUEUE_IN_PUMA` · `OrderCreator` recurrent save_card — **не закрывает** кейс FA без RebillId.
**Приёмка Fly 2026-07-16 (частичная):**
- Replay webhook 0₽ → [`usercards_fly_phase1_verify_2026-07-16.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_phase1_verify_2026-07-16.json) — aramfifa **MIR *5953** (replay, не E2E 2-й карты)
- MCP: [`usercards_phase1_mcp_2026-07-16.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_phase1_mcp_2026-07-16.json) — *5953 в списке
**Живая оплата 2026-07-18:** MCP «Новая карта» 4300*0777 → payment `8878842078` **failed**, Pan/RebillId nil (prod отклоняет test PAN).
**Deploy Fly v366 (2026-07-18):** release `deployment-01KXT8NR80HW40FKBRKFJCMDT7` · 3.3 retry GetState на prod
**Приёмка 3.4:** MCP 2 карты (*5953 + *8782) — [`usercards_phase34_mcp_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_phase34_mcp_2026-07-18.json)
**Приёмка 3.5 re-verify 2026-08-10 (Fly v444):** Local 61/0 · worker started · diagnose + GET `/user/cards` + MCP PaymentMethodsSheet — [`usercards_phase35_mcp_2026-08-10.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_phase35_mcp_2026-08-10.json) · скрин [`usercards_phase35_mcp_2026-08-10_payment_sheet_two_cards.png`](../milestones/veha_2/artifacts/usercards_save_card/screenshots/usercards_phase35_mcp_2026-08-10_payment_sheet_two_cards.png) · канон [`1000008925_payment_methods_list.png`](../milestones/veha_2/artifacts/usercards_save_card/screenshots/1000008925_payment_methods_list.png)
**Осталось:** апрув заказчика/владельца скрина 8925 (3.5) · E2E «Новая карта» только **реальной MIR** (test PAN на prod не гонять)

[2026-07-16] — Checkout Фаза 2 UX: нет одной шторки (peek сверху + PaymentMethodsSheet expanded снизу)
**Статус:** **код done** · **MCP Fly [ ]** · **апрув заказчика [ ]**
**Источник:** заказчик · [`Исправление сохранения карты…`](../milestones/veha_2/requirements/customer_tasks/Исправление%20сохранения%20карты%20в%20UserCards%20после%20успешной%20оплаты.md) § **Канон UX checkout** · макеты **1000008924/8925**
**Фикс Фаза 2 (код):** `openCheckoutPayStack` + stacked UX · `prog25`
**Расследование 2026-07-16:** [`usercards_fly_payment_investigate_2026-07-16.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_investigate_2026-07-16.json) — 2× succeeded; **09:56** без Pan/RebillId в момент FA.
**Root cause 3.2:** [`usercards_fly_payment_root_cause_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json) — см. UserCards (общий поток).
**Осталось:** MCP stacked · апрув заказчика (после UserCards 3.4).

[2026-07-21] — Локальный полный прогон `test/integration/shop/` зависает (Windows)
**Статус:** 🟡 **открыт (env, не блокер кода)**
**Симптом:** `ruby bin/rails test test/integration/shop/` — 43 теста прошли, дальше молчание 40+ мин, процесс убит вручную. Таргетный прогон тех же зон (59 runs cart sheet) проходит за секунды.
**Гипотеза:** тест с сетевым вызовом / ожиданием (payments|callbacks) без таймаута на локальной Windows-машине.
**Улика 2026-07-21 (шаг B4 Quick Repeat):** зависание воспроизводится на рендере SPA-shell — `GET /shop?tenant_id=` (`pages#home`) в `cart_persistence_test.rb` и на любом GET к `/shop/*` без `as: :json` (уходит в catch-all `pages#home`). Гипотеза сужена: рендер shell ждёт vite dev server. `tenant_isolation_test.rb` отдельно проходит (2/0).
**Обход:** регрессию зоны гонять таргетными списками файлов; полную зону — в CI.
**Следующий шаг:** локализовать зависший файл бинарным делением списка (отдельная итерация).

[2026-07-21] — `checkout_ui_cleanup_test.rb` противоречит канону «оплата через шторку» (pre-existing)
**Статус:** **resolved** 2026-07-28 · Auth funnel Шаг 1 — ассерты Email/«Способ оплаты» в Checkout сняты; SBP/Оплатить → PaymentMethodsSheet
**Симптом:** `test/integration/shop/checkout_ui_cleanup_test.rb:71` требовал «Способ оплаты» / Email в `Checkout.svelte`, а `shop_checkout_cart_sheet_ux_test.rb:45` — отсутствие «Способ оплаты».
**Чем закрыли:** обновление cleanup-теста под phone wizard + PaymentMethodsSheet.

[2026-07-15] — Checkout CartSheet (промежуточный код, не приёмка)
**Статус:** **superseded** 2026-07-16 — см. UserCards / Checkout UX выше
**Было:** `isCartSheetRoute` catalog+checkout · deploy v359 · grep-тесты PASS — **заказчик не принял**.

[2026-07-04] — B1.11-BUG-OVERNIGHT: нельзя создать точку с ночной сменой (`must be after opens_at`)
Статус: **resolved** 2026-07-05
**Закрыли:** F1–F4 код · Fly MCP PASS · **апрув заказчика 2026-07-05** — [`b111_customer_approval_2026-07-05.json`](milestones/veha_2/artifacts/demo-feedback/b111_customer_approval_2026-07-05.json)

[2026-07-03] — Sentry RUBY-9: Manager::OrdersController#show 500
Статус: **resolved** 2026-07-03
Описание: `Association named 'product' was not found on OrderItem` — `@order.order_items.includes(:product)` при отсутствии `belongs_to :product` (снимок `product_name`/`product_id`).
**Sentry:** RUBY-9 · 1 event · `Manager::OrdersController#show` · 0 users.
**Закрыли:** убрали `.includes(:product)` · тест `manager_orders_show_test.rb` 1 run PASS.
**Archive в Sentry:** RUBY-9 (код) · RUBY-Q/M/N/K/P/R (Neon quota, квота оплачена 2026-07-03) · RUBY-S (pg_stat_statements) · RUBY-T/D (smoke rake).

[2026-06-25] — B1.13-S2 фаза 3: Fly MCP FAIL — S2 не задеплоен
Статус: **resolved** 2026-06-25
Описание: pre-deploy probe 2/9 — на Fly старая сборка (вкладка «Корзина»).
**Закрыли:** deploy владельца → `node bin/acceptance/b113_s2_cart_popup_mcp.mjs` — **9/9 PASS** · [`b113_s2_post_deploy_2026-06-25.json`](milestones/veha_2/artifacts/demo-feedback/b113_s2_post_deploy_2026-06-25.json).

[2026-06-19] — Fly deploy + Neon Launch
Статус: **resolved**
Описание: `DATABASE_URL` → Neon `coffeeos`; Launch plan; `fly deploy` release_command OK; `/up` + `/shop` 200.
Fly MPG `coffeeos-db` destroyed. CI deploy → `workflow_dispatch` only.
**Neon billing:** spending limit **$15** — поднять заказчиком в Console (2026-06-19).

## 🟡 Жёлтые (история)

[2026-05-30] — Kiosk: POST /kiosk/api/auth
Статус: resolved
Описание: Flutter/киоск нужен tenant по device_token; отдельного контроллера не было.
Решение: `Kiosk::Api::AuthController`, контракт [`FLUTTER_API.md`](milestones/veha_2/runbooks/FLUTTER_API.md); shop API без дублирования.
Проверка: 6 tests; curl smoke в FLUTTER_API.md.

[2026-05-28] — Fly: worker crash loop (DB pool < Solid Queue threads)
Статус: resolved
Описание: `bin/jobs` exit code 1 — «Solid Queue is configured to use 5 threads but the database connection pool is 3»; worker machine stopped, jobs не обрабатывались.
Решение: `DB_POOL=8` в `fly.toml`; `database.yml` — `ENV.fetch("DB_POOL")`; rake `fly:callback_smoke` для prod retest.
Проверка: worker `2871332` started; `TbankCallbackJob` Processed order `85bef120` через SolidQueue(critical), без perform_now fallback.
