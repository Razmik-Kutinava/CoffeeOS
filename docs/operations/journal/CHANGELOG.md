# CHANGELOG

## Шапка

**Текущий месяц:** `2026-09`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md` … `CHANGELOG-2026-08.md` · **`CHANGELOG-2026-09-early.md`** (01–17, ctx-trim 2026-09-22)

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца. Ранний сентябрь — `archive/CHANGELOG-2026-09-early.md`.

---

## Текущий месяц (2026-09)

## 2026-09-26 — feat: Задачи-3 Патч 1 — 7d usage / attribution / CTA [GREEN]

- `UsagePricingService` — лимит/over-limit по `subscription_usage_events` (окно 7d), не `drinks_used_this_period`
- Cancel / AutoRenew — usage только в текущем оплаченном периоде; Telegram на cancel без usage
- `RenewalService` — новый период, events + attribution не трогаем
- Attribution: `utm_campaign` / `utm_content` / `offer_channel` (migration + purchase/fulfillment)
- Purchase без PM → Init+payment_url; SBP без фейкового `payment_method_id`
- CTA: tips не fallback при `enabled=false` (Subtask 29)
- Local: `test/services/subscriptions/` + API **29/0** · CTA JS **18 pass**
- Backlog: OrderCreator SKU wiring · Charge в RenewalService

## 2026-09-26 — review: Задача-1 Патч 1 — emergency disable enabled=false

- Local: `order_status_cta_machine_test.mjs` 18 PASS
- bugbot: no bugs · security: no medium+
- Entire `01M3F5K4DJJ5WE8P2755NHQ022` на `61b3fc79` (session attach)
- Push develop · CI [`36252477440`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36252477440) + Semgrep + CodeQL **success**
- Deploy не нужен (config уже на Fly Point A)

## 2026-09-26 — ops: Задача-1 Патч 1 — emergency disable via enabled=false [GREEN]

- Fly Point A: `enabled=false`, `second_cta_mode=subscription` (tips больше не механизм disable)
- Audit: только Point A; других risky нет
- Verify: `order_status_cta_machine_test.mjs` 18 PASS (кейс enabled=false + mode subscription)
- Артефакт: `rollback_point_a_patch_v2_2026-09-26.json` · DEMO_FEEDBACK · customer_tasks · todo Шаг 5
- Код CTA/eligibility / `INTEGRATIONS.md` не менялись

## 2026-09-26 — review: #77 Патч 1 — приоритет 11₽ / CI green

- Local: eligibility 7 · profile offer 9 — PASS
- bugbot: no bugs · security: no medium+
- Entire `01M3ESPX2CJ6Z16E5ED7RFY9BK` на `0b7f0e7f` (session attach)
- CI [`36240947436`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36240947436) + Semgrep + CodeQL success
- GREEN `18c82b91` · Док: https://docs.google.com/document/d/16MJSOBP0lMtZThbrCN8IdtUUqwUQZ7XQdgPHZUktqrk/edit

## 2026-09-26 — feat: #77 Патч 1 — приоритет 11₽ над оффером подписки [GREEN]

- Gate уже в `SubscriptionOfferEligibility` через `GrowthPromo.available?` (не дублирует промо)
- Profile API tests: false пока 11₽ available / true после exhaust
- Синк секции Патч 1 в customer_tasks · `todo.md` Шаг 5
- Док: https://docs.google.com/document/d/16MJSOBP0lMtZThbrCN8IdtUUqwUQZ7XQdgPHZUktqrk/edit
- Local: eligibility 7 PASS · profile offer 9 PASS

## 2026-09-26 — fix: invalidate subscription CTA cache after pay (Патч 1 /review)

- `clearSubscriptionOfferCtaCache()` в `completePaySuccess` + `PaymentResult.prepareSuccessScreen`
- После growth 11₽ `eligible_for_subscription_offer` может flip true — без clear кэш #77 держал false до hard reload
- bugbot medium · security: no medium+
- Entire `01M3EF80ZRWCQSW2HV6TG9N8B6` на `e687317d` · CI [`36231701455`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36231701455) success

## 2026-09-26 — feat: Патч 1 промо 11₽ — GrowthPromo.available? + amount_rub UI [GREEN]

- `Payments::GrowthPromo.available?(customer, point)` — фасад point settings / лимитов / phone-дедупа (без bind checkbox)
- `Shop::SubscriptionOfferEligibility` — false пока промо доступно (не копирует правила GrowthPromo)
- PWA: `promoSaveToday(amountRub)` / nudge из `growth_promo.amount_rub` API (Checkout → PaymentMethodsSheet)
- RED `b5653fa1` · зона: growth_promo 20 · subscription_offer 7 · i18n 4 — PASS
- Док: https://docs.google.com/document/d/1hP-1JZnB3J_3V-cm5Dl7bFRrCk6JWIvrZOZir250x3Y/edit

## 2026-09-25 — ops: Fly v502 fresh deploy (CI green)

- `git push` develop (hosts fix + TEMP iOS diag + ops) → CI / Semgrep / CodeQL **success** (`36115565894`)
- `fly deploy -a coffeeos --remote-only --depot=false` → **v502** `deployment-01M3BWPNB0P1T0PPE2WRP7KBPY`
- Smoke: `https://codeblack.coffee/up` 200 · `/shop?tenant_id=PointA` 200 · fly.dev `/shop` 200
- Витрина заказчику: `https://codeblack.coffee/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`
- Fly MCP full batch: skip (HTTP smoke); Sentry/Neon/УК — не гоняли в этом шаге

## 2026-09-24 — fix: custom domain codeblack.coffee (HostAuthorization 403)

- `config.hosts`: `codeblack.coffee`, `www.codeblack.coffee` + `ADDITIONAL_HOSTS`
- `fly.toml` `APP_HOST=codeblack.coffee`; mailer host из `APP_HOST`
- DNS/сертификат Fly уже Active — без whitelist Rails отдавал 403
- Fly **v501** `deployment-01M39802N9J3ZGMJR64VJ6DN2X` — `https://codeblack.coffee` → **200**
- Коммит: `ccd37e7d` (+ ops)

## 2026-09-22 — diag: TEMP toast-шаги iOS push (#81)

- `registerShopPush({ onToast })` — накопительный лог 1…10 / ОШИБКА на шаге N
- OrderStatus: `ctaToast` + `pushErr` у кнопки «Разрешить» (без delay до requestPermission)
- `subscribeOrderPush` прокидывает onToast; не затирает diag outcome-тостами
- **Не финал** — убрать отдельным коммитом после on-device
- Коммит: `9b3c1488`

## 2026-09-22 — ops: ctx-trim токенов (CHANGELOG early-Sep + ISSUES + todo)


- Архив: `journal/archive/CHANGELOG-2026-09-early.md` (2026-09-01…17)
- Живой CHANGELOG: шапка + **09-18+** (~650 строк vs ~1986)
- ISSUES: UTF-8 fix · 🔴 сжата · #93/#26/FLY_TOKEN/min-charge → «Решено недавно»
- `todo.md` → stub; полный SPEC → `session/archive/todo-task84-receipt-2026-09.md`
- `ctx_trim: 2026-09-22` в HANDOFF/SESSION_STATE
- Экономия: **~16.7k tok** live CHANGELOG · **~0.7k tok** старт (todo+ISSUES)

## 2026-09-21 — ops: Fly v500 deploy + MCP batch (post-v499)

- Push `ad0421c6` · CI green [`35584900523`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35584900523)
- Fly **v500** `deployment-01M31NTDXYAJYWZQK3ZYGHHEZX` (web+worker)
- Deep MCP Point A **19/21 PARTIAL** · browser catalog/cart/1-click · Sentry RUBY-1M resolved
- Artifacts: `artifacts/mcp/fly_v500_2026-09-21/` · `critical_path_hardening/mcp/fly_v500_deep*_2026-09-21/`
- Soft-fail: phone verify without Callcheck · H overflow runner probe
- G5 TASK_84 expand receipt / #73 fiscal live — ещё unmet

## 2026-09-21 — docs: update COMPONENT_MAP — ActiveOrdersAccordion / receiptPanelView

- Строки: ActiveOrdersAccordion · activeOrdersAccordion.js · ActiveOrdersPresenter
- Дыра «Presenter items уже в JSON» снята (TASK_84-RECEIPT-DISPLAY-EXT)

## 2026-09-21 — docs: CI green TASK_84-RECEIPT-DISPLAY-EXT REVIEW close

- CI green [`35579839261`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35579839261) · Semgrep · CodeQL
- GREEN `4e84a4b4` · Entire `01M31GK06473NABJMKATBKCJD0`
- Next: deploy апрув · G5 Fly после deploy

## 2026-09-21 — docs: REVIEW TASK_84-RECEIPT-DISPLAY-EXT runtime receipt

- GREEN `4e84a4b4`: `receiptPanelView` + ActiveOrdersAccordion wire
- Local PASS · bugbot clean · security: no med+
- Entire `01M31GK06473NABJMKATBKCJD0` на `4e84a4b4`
- G5 Fly unmet до deploy
- Next: push/CI · deploy апрув

## 2026-09-21 — docs: /unlazy reverify TASK_84-RECEIPT-DISPLAY-EXT pre-REVIEW

- G1–G4 **met** (reverify) · G5 **unmet** (Fly Point A)
- Ledger: `active_orders_receipt_display_restore/GATES.md`
- Next: `/review`

## 2026-09-21 — docs: regress PASS TASK_84-RECEIPT-DISPLAY-EXT

- JS `active_orders_accordion_test.mjs` 27/27 PASS
- Rails зона: 15 runs, 117 assertions, 0 failures
- GATES G1–G4 reverify PASS · G5 Fly unmet
- Next: `/review`

## 2026-09-21 — docs: SPEC TASK_84-RECEIPT-DISPLAY-EXT runtime receipt

- todo.md: SBR + 4 пути + Не ломать/Проверка (hot-path status sheet)
- Next: `/sbr` RED (runtime DOM)

## 2026-09-21 — docs: /unlazy TASK_84-RECEIPT-DISPLAY-EXT GATES

- Ledger: `artifacts/active_orders_receipt_display_restore/GATES.md`
- G1–G4 **met** (baseline approve+run) · G5 **unmet** (Fly MCP after deploy)
- Next: `/spec` → `/sbr`

## 2026-09-21 — docs: intake TASK_84-RECEIPT-DISPLAY-EXT runtime receipt

- Google Doc → `customer_tasks/TASK-84-RECEIPT-DISPLAY-EXT-…ActiveOrdersAccordion.md`
- artifacts `active_orders_receipt_display_restore/` · CBR + customer_tasks README
- ID: EXT к #84 (не #94 — занят LK history); заголовок Doc «TASK_94» → канон `TASK_84-RECEIPT-DISPLAY-EXT`
- Next: `/spec`

## 2026-09-21 — docs: REVIEW #73 Патч 1 fiscal OFD poll
- GREEN `ced2ad97`: OrderReceipt poll + claim-release / unique ofd tests
- Local PASS · bugbot clean · security no med+
- Entire `01M31CYA74N9H6HHS2DX30M2AY` на `d50f167a` · CI [`35571998446`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35571998446) green
- Subtask 3 ops + 21/26 prepayment Type — ещё открыты
- Next: deploy апрув · G5 после fiscal notify ON

## 2026-09-21 — docs: REVIEW #73 фискальные чеки в ЛК

- Local PASS · bugbot: RLS JobTenantContext + UI (no Url / cancelled) · security: no med+
- Entire `01M319ZHF0R2YQGJYXFH1459KR` на `12caceb7`
- GREEN `439a87af` · fix `12caceb7`
- CI green [`35569642319`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35569642319)
- G5 Fly unmet до fiscal notify ON
- Next: deploy апрув · затем Патч 1 `/patch`

## 2026-09-21 — docs: /unlazy reverify #73 перед REVIEW

- G1–G4 **met** (reverify) · G5 **unmet** (Fly Point A)
- Ledger: `fiscal_receipts_personal_cabinet/GATES.md`
- Next: `/review`

## 2026-09-21 — docs: /regress #73 фискальные чеки в ЛК

- JS `order_fiscal_receipt_lk_test.mjs` 3/3 PASS
- Rails зона: 37 runs, 153 assertions, 0 failures
- GATES G1–G4 reverify PASS · G5 Fly unmet (fiscal notify ON)
- GREEN `439a87af` · Entire `01M319ZHF0R2YQGJYXFH1459KR`
- Next: `/review` · Fly MCP Point A ещё нужен для «готово заказчику»

## 2026-09-21 — docs: /spec #73 фискальные чеки в ЛК

- `todo.md`: полный SBR · без Патч 1 · 5 файлов · Не ломать/Проверка
- GATES G1–G4 baseline · G5 Fly после fiscal notify ON
- Next: `/sbr`

## 2026-09-21 — docs: /unlazy #73 фискальные чеки в ЛК

- Ledger: `artifacts/fiscal_receipts_personal_cabinet/GATES.md`
- Scope: основная задача (без Патч 1; без email/QR-допов)
- G1–G4 **met** (handler / API / callbacks / receipt_builder)
- G5 **unmet** — Fly MCP Point A после fiscal notify ON + deploy
- Next: `/spec`

## 2026-09-19 — docs: REVIEW #69 Патч 2 ЛК Telegram label

- Local PASS 14/14 · bugbot: no bugs · security: no med/high/crit
- Entire `01M2WSS8C919PDRPZJ8ECAH6WP` на `3bae4b26` (session attach)
- GREEN `4f8ee541` · Subtask 21 patch v1 · COMPONENT_MAP не трогали
- CI green [`35442696778`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35442696778)
- Next: deploy апрув

## 2026-09-19 — docs: #69 Патч 1 рис.1 ЛК intake + understanding

- Google Doc после TODO → Патч 1: убрать иконку «Обратная связь» из шапки гл. экрана
- Артефакт: `pwa_personal_account_lk/screenshots/patch1_2026-09-17_fig1_lk_ux_markup.png`
- Understanding: [`PATCH1_FIG1_UNDERSTANDING_2026-09-19.md`](../milestones/veha_2/artifacts/pwa_personal_account_lk/PATCH1_FIG1_UNDERSTANDING_2026-09-19.md)
- Next: `/review` Патч 2 · затем отдельным шагом Патч 1 (не PLG/ОФД)

## 2026-09-19 — feat: #69 Патч 2 ЛК «Tg» → «Telegram» [GREEN]

- Subtask 21 patch v1: `ContactSupportSheet` подпись Telegram (как на гл. экране)
- Артефакт рис.2: `pwa_personal_account_lk/screenshots/patch2_2026-09-17_fig2_telegram_label.png`
- Тест: `telegram_support_test.mjs` 14/14 · URL/email/механика без изменений
- Next: `/review`

## 2026-09-19 — docs: Патч 1 screen compare (customer + Fly)

- Artifact `tbank_inline_payment_button_statuses/PATCH1_SCREEN_COMPARE_2026-09-19.md`
- Customer markup + Fly idle/during/paid · during_pay: статус в fallback, не в `shop-repeat-card-pay`
- Вывод: Local PASS · Fly v499 ещё без Патча 1 UI · next = deploy апрув

## 2026-09-19 — docs: todo Патч 1 inline pay (Исправленный сценарий)

- Google Doc + customer_tasks: только Патч 1 Subtask 8/10/12/13 patch v1
- Код уже GREEN (2026-09-18) · REVIEW CI green — reverify Local PASS (JS 15/15 · Rails patch1 4/4)
- `todo.md` переключён на итерацию Патч 1 · чеклист Исправленный сценарий `[x]`
- Next: deploy апрув · Fly MCP

## 2026-09-19 — docs: REVIEW TASK_94 LK history repeat one-click

- Local PASS · bugbot: no bugs · security: no med/high/crit (app auth scoped)
- Entire `01M2WE9CRRMSBH3NM8QQWWG50X` на `4336854`
- GREEN `ff63997d` · GATES G1–G4 met · G5 Fly после deploy
- CI green [`35434127135`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35434127135)
- Next: deploy апрув

## 2026-09-19 — docs: unlazy reverify TASK_94 G1–G4 met

- `--approve` + `--reverify`: G1–G4 PASS · G5 Fly unmet (после deploy)
- Next: `/review`

## 2026-09-19 — docs: regress PASS TASK_94 LK history repeat

- JS 12/12 · Rails 16/16 (LK + QR + personal account)
- GREEN `ff63997d` · Entire `01M2WE9CRRMSBH3NM8QQWWG50X`
- Next: `/review` · Fly MCP G5 после deploy

## 2026-09-19 — docs: SPEC TASK_94 LK history repeat one-click

- `todo.md`: Profile + OrderReceipt + `historyRepeatAdapter.js` · Не ломать/Проверка
- GATES G1–G2 на RED · Next: `/sbr`

## 2026-09-19 — docs: /unlazy TASK_94 GATES ledger

- `session/GATES.md` + `artifacts/lk_history_repeat_one_click/GATES.md`
- Baseline: G3/G4 PASS · G1/G2 unmet (тесты на RED) · G5 Fly pending
- Next: `/spec`

## 2026-09-19 — docs: intake TASK_94 LK history repeat one-click

- `customer_tasks/TASK-94-Повтор-покупки-из-истории-ЛК-с-one-click-оплатой.md` — Google Doc 1:1
- artifacts `lk_history_repeat_one_click/` · CBR #94 · customer_tasks README
- Next: `/spec`

## 2026-09-19 — docs: REVIEW Патч 1 inline pay button statuses

- Local PASS · bugbot: clearPayResetTimer · security: no med/high/crit
- Entire `01M2WC1SCBV10YQZW2HFQ6DNM7` на `9eab6800` (attach)
- GREEN `9e0a295c` · REVIEW fix `9eab6800` · lint unblock `fd3a0abd`
- CI green [`35431986540`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35431986540)

## 2026-09-18 — feat: Патч 1 inline pay статусы в кнопке [GREEN]

- Subtask 8/10/12/13 patch v1: `cardPayLabel` в `shop-repeat-card-pay`; 1051→«Недостаточно средств»; ERROR/timeout→IDLE 3s
- `statusInHostButton` в InlinePayFallback; rotation «Платеж принимается от банка...»
- Local: JS 25/25 · Rails patch1 4/4 · quick_repeat_pay 5/5 · Next: `/review`
- RED `ddd04998`

## 2026-09-18 — ops: TASK_93-L deep MCP Point A PASS 20/20

- Artifact `critical_path_hardening/mcp/fly_v499_deep_2026-09-18/` · scripts `bin/acceptance/task_93_l_deep_mcp*.rb`
- Redis store + OTP 429 · phone verify 6-digit · worker/SolidQueue · Events/callback reject · short `/o/` · history · GUC
- Browser: cart → `#/checkout` · live charge/Callcheck device skipped (`SHOP_SIMULATE=0`)

## 2026-09-18 — ops: Fly v499 deploy + Point A smoke (TASK_93-L)

- Deploy Actions **success** `35340979415` · image `deployment-01M2T582RETP2608KZMBMXAE1A` · web/worker **v499**
- Blockers fixed: Upstash Redis `coffeeos-rack-attack` + secret `RACK_ATTACK_REDIS_URL` (TASK_93-I); retry after ConcurrentMigrationError
- Pack: `/up`+shop+categories **200** · browser catalog/cart PASS · Sentry unresolved 24h **0** · logs OK
- Artifact: `artifacts/critical_path_hardening/mcp/fly_v499_2026-09-18/MCP_RESULT.md` · deep G5 matrix = next

## 2026-09-18 — docs: REVIEW #93 TASK_93-E Init idempotency

- Local **86/0** · bugbot: ClientOrderReused Init вне rolled-back txn · security: no med/high/crit
- GREEN `2eb22c71` · REVIEW fix `ead5cf38` · Entire `01M2SZBBAQEGHNGEJCXYHG76XH`
- CI green `35338088214` · GATES G1–G4 met · G5→L · **без deploy**

## 2026-09-18 — docs: CI green #93 TASK_93-J REVIEW

- CI `35337468382` green `6b6cf8a0` · J1–J4 · G5→L
- Unblocks: bugbot dead-token + ready PassUpdate skip (`5fba4622`)

## 2026-09-18 — docs: REVIEW #93 TASK_93-J Push / worker

- Local zone **87/0** · bugbot: INVALID_ARGUMENT + ready race → fix `5fba4622` · security PASS
- Entire `01M2T11SGYVJM111FYJ5D47A1P` · GREEN `566dba9b` · G5→L
- Table J1–J4 PASS · Next: push/CI · deploy = апрув L

## 2026-09-18 — docs: REVIEW re-check #93 TASK_93-H (this chat)

- Local zone **55/0** · [bugbot](0089a9a9-c512-478f-a78c-b68bacc1ec99) no bugs · [security](24935038-d61b-47a3-8a5d-afb74e5ca88d) med+ 0
- Fix already on origin `e80790c9` · Entire `01M2STWJAMB844CP992D067NWP` @ `628f1922` · H session `01M2T02AF0Y1N208P1E4H4TYB3`
- Table H1–H3 PASS · G5→L · push develop

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-J G1–G4 met (G5 to L)

- `GATES-block-J.md`: `--reverify` · **met 4** · **abandoned 1** (G5→L)
- Local G1–G4 CHECK PASS (reran 4); Fly MCP Point A = TASK_93-L
- Next: `/review`

## 2026-09-18 — docs: REVIEW #93 TASK_93-I OTP / Rack::Attack

- Local zone PASS · bugbot: assets DUMMY MemoryStore · security: PhoneNormalizer throttle keys
- Fix ce45d164 · GREEN c14f5202 · GATES G1–G4 met · G5→L
- Next: push/CI · deploy Redis = апрув

## 2026-09-18 — docs: regress PASS #93 TASK_93-J Push / worker zone

- Zone: jobs/shop + presence + push_notifier + barista/broadcaster/fcm/updater + tbank
- Local: **87 runs / 0 failures** · GREEN `566dba9b` · gate-check G1–G4 met · G5→L
- Next: `/review` · Fly MCP Point A = TASK_93-L

## 2026-09-18 — docs: REVIEW close #93 TASK_93-H cart overflow

- Local bugbot+security → fix `e80790c9` · CI green on develop tip
- H1–H3 PASS · G5→L · без deploy
- Next: deploy — только по апруву владельца

## 2026-09-18 — docs: CI green #93 TASK_93-K REVIEW

- CI `35335419241` green `c87377fc` · K1–K7 · G5→L
- Unblocks: Brakeman deep_dup · Rack::Attack test MemoryStore

## 2026-09-18 — docs: REVIEW done #93 TASK_93-F CI green

- Local 68/0 · F1–F5 PASS · bugbot + security PASS · Entire `01M2SSQXT1V67AK260SH1P9RAX`
- CI green `35335419241` · GREEN `1b28a128`
- Next: deploy апрув · Fly MCP = L

## 2026-09-18 — fix: #93 TASK_93-H REVIEW cart overflow holes

- `MAX_SESSION_CART_BYTES` 3072→**2048** (OTP/customer/cookie crypto headroom)
- `remove!`/`clear!`/qty−: `touch_cart_session!(enforce_budget: false)` — legacy over-cap не 500
- `CartController` `rescue_from OverflowError` на все actions + CookieOverflow gate
- Tests T-H1d · T-H2d · zone Local PASS
- Next: push/CI · deploy апрув · Fly MCP = L

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-I GATES G1-G4 met

- --reverify GATES-block-I: met **4** · abandoned **1** (G5→L)
- Next: /review (код не трогали)

## 2026-09-18 — feat: #93 TASK_93-J Push/worker async + FCM cache [GREEN]

- `PassUpdateJob` · GuestOrderBroadcaster без sync PassUpdater · cascade wait GRACE+5s
- `PaymentStatusUpdater` broadcaster после `with_lock` · FCM OAuth cache 50m + UNREGISTERED clear
- Runbook `SOLID_QUEUE_FLY.md` · Local T-J* + zone 53/0 · barista/tbank 20/0
- Next: `/regress`

## 2026-09-18 — docs: REVIEW #93 TASK_93-F Callbacks/stuck/Events

- Local notify pack **68/0** · F1–F5 PASS · bugbot no bugs · security PASS
- Entire `01M2SSQXT1V67AK260SH1P9RAX` · GREEN `1b28a128`
- Next: push/CI · deploy апрув · Fly MCP = L

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-H G1–G4 met (G5 to L)

- `GATES-block-H.md`: `--approve` + `--reverify` PASS (G1–G4); G5 abandoned→L
- automatic-evidence на overflow + cart_service + persistence/modifiers
- Next: `/review`

## 2026-09-18 — docs: regress PASS #93 TASK_93-I OTP / Rack::Attack

- Matrix: **23 runs / 0 fail / 1 skip** (T-I1b no local Redis) — store · verify · short_link · phone_otp
- Zone: **27 runs / 0 fail** — phone_otp API · order_short_links · phone_otp service
- GATES I G1–G4 met · G5→L · GREEN \c14f5202- Next: \/review\ · Fly Redis = L

## 2026-09-18 — docs: regress PASS #93 TASK_93-H cart cookie overflow

- Zone: `cart_service` + `cart_overflow` + `cart_persistence` + `b113_s4_cart_modifiers` → **53 runs, 0 fail**
- GATES-block-H G1–G4 met · G5→L
- Next: `/review`

## 2026-09-18 — docs: REVIEW #93 TASK_93-K hygiene + PaymentURL blank fix

- bugbot: prod blank PaymentURL → empty (not 422) · security: no med+ · K6 sha · K7-B note
- Table K1–K7 PASS · G5→L · push

## 2026-09-18 — feat: #93 TASK_93-H cart cookie overflow [GREEN]

- `CartService::OverflowError` · `MAX_CART_LINES=20` · `MAX_SESSION_CART_BYTES=3072` · rollback guard
- Controller add+update → 422 + clear; no bare CookieOverflow
- RED `5a635be3` · GREEN `d8e5636b` · Local 28 PASS (T-H* · T-H2c SKIP)
- Next: `/regress`

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-F G1–G4 met (G5 to L)

- `GATES-block-F.md`: reverify PASS (G1–G4); G5 abandoned→L
- Первый reverify flake: missing `redis` gem (TASK_93-I) → `bundle install` → PASS
- Next: `/review`

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-E G1–G4 met (G5 to L)

- `session/GATES.md` + `GATES-block-E.md`: G1–G3 approve+reverify PASS · G4 cite met · G5→L
- `--status`: met 4, abandoned 1 · коммит `4905294f`
- Next: `/review`

## 2026-09-18 — docs: REVIEW #93 TASK_93-B Checkout identity

- Local 50/0 · bugbot R4 fix (`find_existing!` ≡ orders) · security: EmailVerification tenant DB → ISSUES backlog
- GREEN `2213cbeb` · R4 `4217cab5` · Entire `01M2STWJAMB844CP992D067NWP`
- Next: push/CI · deploy апрув · Fly = L

## 2026-09-18 — docs: regress PASS #93 TASK_93-F Callbacks/stuck/Events

- Notify pack: **68/0** · zone callbacks/jobs/sync: **74/0**
- GATES-block-F G1–G4 met · G5→L · GREEN `1b28a128`
- Next: `/review` · Fly MCP Point A = TASK_93-L

## 2026-09-18 — docs: regress PASS #93 TASK_93-E Init idempotency

- G1 Init: **30/0** · G2 orders+§2.3+base: **55/0** · total **85/0**
- GREEN `2eb22c71` · Next: `/review` · Fly MCP Point A = TASK_93-L

## 2026-09-18 — docs: REVIEW #93 TASK_93-G Tenant GUC / RLS

- Local 30/0 · bugbot clean · security: no med/high/crit
- Entire `01M2SSXE54SV4CM341NHXR0SCE` на `7c34314a` · GATES G1–G4 met · G5→L
- Таблица G1–G6 PASS · push/CI · **без deploy**

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-K G1–G4 met (G5 to L)

- `GATES-block-K.md`: reverify PASS G1–G4; G5 abandoned → TASK_93-L
- Next: `/review`

## 2026-09-18 — feat: TASK_93-E Init idempotency [GREEN]

- GREEN `2eb22c71` · RED `0a7e72ba` · zone 53/0
- `base_controller`: session SET GUC (не long txn) · `OrderCreator`: savepoint + pid guard + `ClientOrderReused`
- Next: `/regress` §2.3

## 2026-09-18 — docs: regress PASS #93 TASK_93-K hygiene pack

- Zone: sanitize · demo · paymentUrl · merger · collector · menu sort_order · onboarding
- Local: **35 runs / 0 failures** (seed 50003) · GREEN `39b38d58` · G1–G4 met · G5→L
- Next: `/review` · Fly MCP Point A = TASK_93-L

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-G gates met

- GATES-block-G: G1–G4 **met** (--reverify); G5 Fly **abandoned** → TASK_93-L
- Local evidence automatic; Next: /review

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-B gates met

- `GATES-block-B.md`: G1–G3 **met** (--reverify); G4 UI; G5 Fly **abandoned** → TASK_93-L
- Next: `/review`

## 2026-09-18 — review: TASK_93-D history per_page PASS

- D1–D3 PASS · Local 20/0 · bugbot 0 · security 0 · Entire `01M2STB3BHJ65BAYQM492QTT7P`
- GREEN `9d2b98a8` · Deploy = TASK_93-L (не сейчас)

## 2026-09-18 — docs: regress PASS #93 TASK_93-G Tenant GUC / RLS

- Zone: staff_pg_context + rls_tenant_isolation + db_triggers + customer_tenant_history → **22/0**
- GATES-block-G: G1–G4 met · G5 abandoned→L
- Next: `/review`

## 2026-09-18 — docs: regress PASS #93 TASK_93-B Checkout identity

- Zone: order_creator + recurrent + checkout_identity + email_otp + one_click + new_card → **47/0**
- `gate-check --reverify` GATES-block-B: G1–G3 met · G4 UI · G5 abandoned→L
- Next: `/review`

## 2026-09-18 — docs: unlazy reverify #93 TASK_93-D gates met

- `GATES-block-D.md`: G1–G3 **met** (--reverify + G3 grep); G4 Fly **abandoned** → TASK_93-L
- Next: `/review`

## 2026-09-18 — docs: REVIEW done #93 TASK_93-C SMS short link · CI green

- C1–C5 PASS · GREEN `c2ef2d68` · fix `6254ab0d` · CI https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35326857443
- bugbot clean · security no medium+ · Entire `01M2SSQXT1V67AK260SH1P9RAX` · GATES G1–G5 met · G6→L
- Next: deploy — только апрув (TASK_93-L)

## 2026-09-18 - review done: #93 TASK_93-A CI green

- A1-A6 PASS · FIX 77291dc6 trigger no-op · push develop · CI 35326857443 SUCCESS (tip 7c34314a)
- Entire 01M2SSQXT1V67AK260SH1P9RAX · GATES G1-G3 met · G4 Fly = L
- Next: deploy only with owner approval

## 2026-09-18 - review: #93 TASK_93-A money-order + trigger no-op

- bugbot/security: hard auto_deduct bypassed soft-fail -> migration no-op; Ruby sole deduct
- FIX 77291dc6 · Local A zone 80/0 · Entire 01M2SSQXT1V67AK260SH1P9RAX
- Next: push · CI · deploy=L

## 2026-09-18 — feat: GREEN #93 TASK_93-B Checkout identity phone-first

- `Shop::CheckoutIdentity` · OrderCreator / RecurrentOrderCreator
- Checkout `identityReady = phoneVerified || emailVerified`
- Tests 47/0 · RED `f6e2f3ca` · GREEN `2213cbeb` · Entire `01M2STWJAMB844CP992D067NWP`
- Next: `/regress`

## 2026-09-18 — docs: REVIEW #93 TASK_93-C SMS short link

- Local 18/0 · bugbot clean · security no medium+ · Entire `01M2SSQXT1V67AK260SH1P9RAX` на `c2ef2d68`
- GATES G1–G5 met · G6→L · push/CI · без deploy

## 2026-09-18 — docs: regress PASS #93 TASK_93-D history per_page

- Local: `orders_controller_test` + `mvp_flow_test` — **20 runs, 0 failures**
- `GATES-block-D`: G1/G2 **met** (--approve); G3 REVIEW; G4→L
- Next: `/review`

## 2026-09-18 — docs: SPEC #93 TASK_93-K Hygiene pack (K1–K7)

- `todo-block-K.md` (+ session todo): R1–R7 · K7-**B** · paymentUrl prod 422 · DEFER пусто
- Не ломать / Проверка · Next: `/sbr` RED

## 2026-09-18 — docs: SPEC #93 TASK_93-I OTP / Rack::Attack / auth abuse

- `todo-block-I.md` (+ session todo): R1 Redis · R8 fail-boot · R3/R4 verify 5/min · R5 I3=6 · R6 no dupe /o/ · R9 CI redis
- Файлы 7 + blast · Не ломать · Проверка
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: pin TASK_93-G SPEC (todo-block-G canon)

- Канон: `todo-block-G.md` + `GATES-block-G.md` + `RLS_PG_INVENTORY.md`
- R1–R6 · **R3-B** · `app.shop_city_lookup` · Next: `/sbr` RED

## 2026-09-18 — docs: SPEC #93 TASK_93-G Tenant GUC / RLS / schema

- `todo-block-G.md` + `RLS_PG_INVENTORY.md`: R1 txn · R2 staff · **R3-B** · R5 city GUC · R6 raise except test
- Не ломать · Проверка · Next: `/sbr` RED

## 2026-09-18 — docs: unlazy #93 TASK_93-G Tenant GUC / RLS / schema

- `GATES-block-G.md` + session `GATES.md`: G1 staff T-G1 · G2 inventory/ensure/fresh T-G2–G4 · G3 city T-G5 · G4 regress+T-G6 · G5→L
- `--status`: unmet 4 · abandoned 1 (G5)
- Next: `/spec` (код не трогали)

## 2026-09-18 — docs: SPEC #93 TASK_93-F Callbacks/stuck/Events

- `todo.md` + `todo-block-F.md` → TASK_93-F: R1 fail-closed · R2/R3 release claim on reject · R4 stuck GetState · R5 fiscal report+1 retry · R6 422
- Файлы 7 + blast · Не ломать · Проверка G1/G4
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: unlazy #93 TASK_93-F Callbacks/stuck/Events

- `GATES-block-F.md` + session `GATES.md`: G1 Events T-F1/F2/F5 · G2 stuck T-F3 · G3 fiscal T-F4 · G4 regress · G5→L
- `--status`: unmet 4 · abandoned 1 (G5)
- Next: `/spec` (код не трогали)

## 2026-09-18 — docs: SPEC #93 TASK_93-E Init idempotency

- `todo.md` + `todo-block-E.md` → TASK_93-E: R1 pid · R2 uuid/failed txn · R3 HTTP вне base_controller txn · R4 tests
- Файлы 7 + blast · Не ломать · Проверка G1/G2 · зеркало от race с A/B/D
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: restore SPEC #93 TASK_93-B (todo after D race)

- `todo.md` снова TASK_93-B phone-first (после параллельного SPEC D)
- Next: `/sbr` RED

## 2026-09-18 — docs: SPEC #93 TASK_93-D history per_page

- `todo.md` → TASK_93-D: R1–R5 default 20 / max 50 · T-D1/T-D3
- Файлы 5 + blast · Не ломать · Проверка G1/G2
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: SPEC #93 TASK_93-B Checkout identity

- `todo.md` → TASK_93-B: phone-first R1–R5 · файлы OrderCreator/Recurrent/Checkout · Не ломать · Проверка G1–G3
- CBR `#93` SPEC B · Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-E Init idempotency

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES-block-E.md`
- G1 double Init / pid · G2 RecordNotUnique / concurrent uuid · G3 §2.3 regress · G4 HTTP вне txn (REVIEW) · G5 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 4, abandoned 1; `--approve` после GREEN (baseline ≠ DoD без T-E*)
- Параллельно: A SPEC · C SPEC · B/D в `GATES-block-B/D.md`

## 2026-09-18 — docs: SPEC #93 TASK_93-C SMS short link

- `todo.md` → TASK_93-C: R2-A · TTL 48h · throttle 30/min · one-time SKIP
- Файлы 7 + blast · Не ломать · Проверка G1–G5
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — fix: CI ABAC-015 (revert TenantOperatingHours preload)

- Loaded-empty `weekday_schedules` → `open_now?` всегда true → 3 CI fails
- Revert preload; RUBY-1J batch aggregate остаётся (`94a7644b`)
- CI green: https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/35323013520

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-B Checkout identity

- Канон ledger: `artifacts/critical_path_hardening/GATES-block-B.md` (session/GATES.md гоняют A/C/D)
- `--approve`: G3 baseline PASS; G1/G2 unmet (нет test files); G4 manual; G5→L
- Next: `/spec` B

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-D history per_page

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES-block-D.md`
- G1 T-D1/T-D3 · G2 orders+mvp_flow · G3 D2 клиент (REVIEW) · G4 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 3, abandoned 1; `--approve` после GREEN (baseline file PASS ≠ DoD без T-D*)
- Параллельно: A SPEC · B/C в `GATES-block-B/C.md`

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-C SMS short link (active)

- Активный `session/GATES.md` = **C** · канон `GATES-block-C.md` · зеркало `artifacts/.../GATES.md`
- G1 SMS host · G2 `/o/` bind · G3 throttle · G4 TTL · G5 zone · G6 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 5, abandoned 1; `--approve` после GREEN (не сейчас)
- Параллельно: A SPEC · B/D в `GATES-block-B/D.md`

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-B Checkout identity (active)

- Активный `session/GATES.md` = **B** (восстановлен после коллизии с C)
- `--approve`: G3 baseline PASS; G1/G2 unmet (нет `recurrent_order_creator_test` / `checkout_identity_test`); G5→L
- `GATES-block-A/B/C.md` в artifacts; C сохранён в `GATES-block-C.md`
- Next: `/spec` B

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-C SMS short link

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES.md` (+ `GATES-block-C.md`)
- B → `GATES-block-B.md`; A остаётся `GATES-block-A.md`; todo A → pointer на block-A
- G1 SMS host · G2 `/o/` bind · G3 throttle · G4 TTL · G5 zone · G6 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 5, abandoned 1; `--approve` после GREEN (не сейчас)

## 2026-09-18 — docs: SPEC #93 TASK_93-A Critical path (деньги↔заказ)

- `todo.md` → TASK_93-A: файлы A1–A6 · Не ломать · Проверка G1/G2 · матрица T-A*
- Next: `/sbr` RED (код не трогали)

## 2026-09-18 — docs: unlazy GATES #93 TASK_93-A Critical path (деньги↔заказ)

- `session/GATES.md` + `artifacts/critical_path_hardening/GATES.md`
- G1 матрица T-A* · G2 zone regress · G3 A4 Amount · G4 Fly **ABANDON** → TASK_93-L
- `gate-check --status`: unmet 3, abandoned 1; `--approve` после GREEN (не сейчас)

## 2026-09-18 — fix: Sentry RUBY-1J ChannelOrderStats N+1

- `Analytics::ChannelOrderStatsCollector`: один aggregate `GROUP BY tenant_id, source` + `SET LOCAL row_security = off` (вместо SET LOCAL tenant на каждый tenant)
- `TenantOperatingHours`: если `weekday_schedules` preloaded — фильтр в памяти
- Tests: collector + job + menu sort_order (RUBY-1K regression) PASS
- RUBY-1K: фикс уже в `64b99477`, ждёт deploy

## 2026-09-18 — docs: intake #93 TASK_93-B Checkout identity

- `customer_tasks/TASK-93-B-Checkout-identity.md` — ТЗ 1:1 (phone-first; UI Pay ≡ бэкенд)
- CBR `#93` → блок B · artifacts `critical_path_hardening/` · ISSUES #93
- Next: `/spec` (не код)

## 2026-09-18 — docs: intake #93 TASK_93 Critical path hardening (блок A)

- `customer_tasks/TASK-93-Critical-path-hardening.md` — ТЗ 1:1 (зонтик A–L; сейчас A: деньги↔заказ)
- CBR `#93` · `artifacts/critical_path_hardening/` · ISSUES строка #93
- Next: `/spec` (не код)

## 2026-09-18 — security: Dependabot pack (gems + npm)

- `view_component` 3.25 → **4.15.0** (GHSA preview/helper + system-test path; floor ≥4.9)
- `vite` → **8.0.16**, `devalue` → **5.9.2**, `svelte` lock 5.57 (npm audit 0)
- Rails/AS stack уже **8.1.3.1**, rack-session 2.1.2, puma 8.0.2 — bundler-audit clean
- **main** `d33f83c7`: sync lockfiles с develop → Dependabot **0 open / 93 fixed**; closed PRs #16–20
- Local: auth sessions 18 PASS; VC render smoke OK

## 2026-09-18 — fix: CodeQL ruby syntax warning on main

- `db/migrate/20250115000002_create_stage_2_payments.rb` на main: orphan `, if_not_exists: true, if_not_exists: true` → файл как на develop
- Push main `7ab6456c`; CodeQL Advanced main SUCCESS (ruby + js)

## 2026-09-18 — fix: CI Block F stock hard-fail test

- `BlockFStockFlowTest`: sale при нехватке остатка → 422 + stock unchanged (не soft-negative QA 4.2)
- Согласовано с `Inventory::OrderRecipeDeduction` hard-fail
- Local: block_f + deduction 8 PASS

## 2026-09-18 — ci: Semgrep → GitHub Code Scanning

- `.github/workflows/semgrep.yml`: p/ruby + p/javascript + p/rails → SARIF → `upload-sarif` (category semgrep)
- Алерты: Security → Code scanning (рядом с CodeQL); Actions → Semgrep

## 2026-09-18 — fix: CodeQL ReDoS + dismiss false positives

- ReDoS: `URI::MailTo::EMAIL_REGEXP` в email_otp / email_service / purchase / tbank_receipt; JS login_form без nested `+`
- Dismiss 13 alerts: CSRF callbacks/API (#2–#9, #15), test password (#14/#16), acceptance SSRF (#12), bank_card_id FP (#13)
- Open до rescan: #1 / #10 / #11 (закроются после CodeQL на push)
- Local: email_otp + receipt_builder 15 PASS

## 2026-09-18 — ci: CodeQL Advanced on develop + main (push)

- develop push `adae7af5`; main fix `fe1349a4` (убран broken manual if)
- Один workflow на обеих ветках — не удалять с main (триггеры develop+main)
- Languages: ruby + javascript-typescript; build-mode none

## 2026-09-18 — ci: CodeQL Advanced workflow (ruby + JS)

- `.github/workflows/codeql.yml`: develop+main; `javascript-typescript` + `ruby`; `build-mode: none`
- Без шага manual if (ломал GH expression на `"manual"`)

## 2026-09-18 — fix: GetState Amount + inventory hard-fail + #78 cancel/confirm

- GetState CONFIRMED: `notification_amount_matches?` до succeeded; blank Amount fail-closed
- Inventory: недостаточно остатка → `OrderRecipeDeduction::Error` (не clamp в 0)
- #78: `CancelService` + `ConfirmPaymentService` (GetState + PaymentFulfillment); Shop API не 501
- Local: Rails 46+4 PASS · JS CTA 17 PASS · Fly MCP skip (нет deploy)

## 2026-09-18 — fix: P0/P1 crits (tips, Tbank mismatch, FCM tenant, Callcheck×2, SMS HMAC)

- Tips CTA: default URL + same-tab fallback как chat (#94); FCM `action=tips` → `openTipsService`
- Tbank amount mismatch: raise + release idempotency claim + HTTP 422 (не silent OK)
- FCM payload `tenant_id`; SW cancel `?tenant_id=` + `X-Shop-Tenant`
- Callcheck ×2 (80s) затем SMS; SMS `/o/:hash` HMAC (не reversible UUID)
- #78: subscription CTA скрыт (501 stubs); Wallet CTA скрыт без certs; Events Amount kopecks; stock clamp ≥0
- Local: JS 73+45 PASS · Rails 82+25 PASS · Fly MCP skip (нет deploy)

