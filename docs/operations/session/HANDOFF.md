# HANDOFF — Веха 2 (Веха 1 **закрыта** 2026-06-19)

**Дата:** 2026-08-05 (**#41** intake · **#40** Fly **v428**)  
**Ветка:** `develop`  
**Прод:** https://coffeeos.fly.dev (**v428**)

### Order action buttons status panel (#41) — 2026-08-05

| Что | Статус |
|-----|--------|
| Intake (PHASE 0) | **`[x]`** |
| PHASE 1 SPEC | **`[ ]`** ждёт go |
| RED/GREEN / REVIEW / deploy / MCP | **`[ ]`** |

**ТЗ:** [`Динамический блок действий Action Buttons в статусной панели заказа.md`](../milestones/veha_2/requirements/customer_tasks/Динамический%20блок%20действий%20Action%20Buttons%20в%20статусной%20панели%20заказа.md)  
**Артефакты:** [`order_action_buttons_status_panel/`](../milestones/veha_2/artifacts/order_action_buttons_status_panel/) · макет `screenshots/01_mockup_status_panel_action_placeholders_2026-08-05.png`  
**Суть:** заменить оранжевые плейсхолдеры справа от progress bar на динамические CTA (Отмена / Чат / Чаевые / Push|Wallet) по матрице статусов + WS.  
**Дальше:** go → PHASE 1: SPEC (`todo.md`, маппинг Svelte / node:test; не React/Jest из ТЗ).

### T-Bank auto refund on PWA cancel (#40) — 2026-08-04

| Что | Статус |
|-----|--------|
| Intake / SPEC / RED-GREEN 1–7 / REVIEW | **`[x]`** tip REVIEW `e2c10736` |
| Push develop | **`[x]`** `e2c10736` |
| Fly deploy | **`[x]`** **v428** · `deployment-01KZ6M11H6F1RJ4GPMND07P57R` |
| MCP | **PASS** · pending `#202608-0003` · ready `#202608-0005` · **accepted modal `#202608-0006`** · live `/v2/Cancel` E2E deferred |

**ТЗ:** [`Автоматический возврат платежа Т-Банк при отмене заказа в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Автоматический%20возврат%20платежа%20Т-Банк%20при%20отмене%20заказа%20в%20PWA.md)  
**Evidence:** [`mcp/fly_v428_2026-08-04/`](../milestones/veha_2/artifacts/tbank_auto_refund_order_cancellation_pwa/mcp/fly_v428_2026-08-04/)  
**Канон:** `/v2/Cancel` без Receipt; accepted+succeeded → refunded; preparing+ → 422; FE modal/toasts.  
**Дальше:** апрув заказчика «ок»; опционально live Cancel на card `accepted`+PaymentId.

### Order ready cascade WS/Push/Wallet→SMS (#39 v2) — 2026-08-04

| Что | Статус |
|-----|--------|
| Intake / SPEC / GREEN rewrite / REVIEW | **`[x]`** |
| Push develop | **`[x]`** `7b4ff49f` |
| Fly deploy | **`[x]`** **v427** (superseded by v428 for #40) |
| MCP cascade SMS | **PASS** · `#202608-0005` → `sms:sent` · TG=0 · presence skip OK |
| SMS_RU secrets on Fly | **`[ ]`** (fallback log-only) |

**ТЗ:** [`Каскад уведомлений… SMS.md`](../milestones/veha_2/requirements/customer_tasks/Каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20WebPush%20Apple%20Wallet%20SMS.md)  
**Evidence:** [`mcp/fly_v427_2026-08-04/`](../milestones/veha_2/artifacts/order_ready_cascade_ws_push_sms/mcp/fly_v427_2026-08-04/)  
**Дальше:** апрув заказчика «ок»; опционально `SMS_RU_API_ID`/`SMS_RU_FROM` для реального SMS.

### Order ready cascade WS→TG→SMS (#39 v1) — SUPERSEDED

Fly v426 · TG MCP PASS · superseded by v2. Evidence: [`…telegram_sms/mcp/fly_v426_2026-08-04/`](../milestones/veha_2/artifacts/order_ready_cascade_ws_telegram_sms/mcp/fly_v426_2026-08-04/)

### Background FCM progress + Apple Wallet (#38) — 2026-08-03

| Что | Статус |
|-----|--------|
| Intake / SPEC / RED-GREEN 1–5 / REVIEW | **`[x]`** tip `f3f0f2db` · REVIEW `a145ee0c` |
| Fly deploy | **`[x]`** **v421** · `deployment-01KZ3T8HZMBBGBMH2GD7Z20J37` |
| MCP #38 Aram Point A | **PASS** |

**Evidence:** [`mcp/fly_v421_2026-08-03/`](../milestones/veha_2/artifacts/background_notifications_fcm_apple_wallet/mcp/fly_v421_2026-08-03/)  
**Скрины:** `02_*` max-2 CTA subscribed · `03_*` iOS Wallet CTA  
**Дальше:** апрув заказчика «ок» → `[x]` в CBR; или #39 RED шаг 1.

### T-Bank Charge unlocked — пакет MCP (2026-08-03)

ТП: рекуррент + Charge + ChargeQr на терминале `1719235292309`.

| Задача | MCP |
|--------|-----|
| **#32** inline / widget Charge SUCCESS | **PASS** · order `#202608-0005` CONFIRMED |
| **#33** One-Click card Charge | **PASS** · `#202608-0001` `recurrent_charge=true` |
| **#27** SBP Deep Link + card tokenization | **PASS** · QR NSPK + card Charge |
| **#34** SBP Autopay bind Init | **PASS** · `save_sbp_account` → QR (не 3013) |
| **#34** Zero-Click ChargeQr | **ждёт** одну оплату с привязкой в банке (нет AccountToken) |

**Артефакт:** [`tbank_charge_unlocked_mcp_2026-08-03/`](../milestones/veha_2/artifacts/tbank_charge_unlocked_mcp_2026-08-03/)  
**Заказчику:** можно проверять оплату картой в 1 клик + СБП с галочкой привязки (≥10₽).  
**Note:** SBP Recurrent сумма &lt; 10₽ → T-Bank **3016**.

### Order status OS detect + Wallet/WebPush (2026-08-03)

| Что | Статус |
|-----|--------|
| Intake (PHASE 0) | **`[x]`** |
| PHASE 1 SPEC | **`[x]`** |
| RED/GREEN шаги 1–6 | **`[x]`** tip `a0b3d0ea` |
| PHASE 3 REVIEW | **`[x]`** · JS 56 · Rails 11 |
| Push / Fly deploy / MCP | **`[x]`** v419 · MCP **PASS** |

**ТЗ:** [`Адаптивный виджет статуса заказа Детекция ОС и подписка на уведомления.md`](../milestones/veha_2/requirements/customer_tasks/Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md)  
**Артефакты:** [`order_status_os_detect_wallet_webpush/`](../milestones/veha_2/artifacts/order_status_os_detect_wallet_webpush/) · MCP [`mcp/fly_v419_2026-08-03/`](../milestones/veha_2/artifacts/order_status_os_detect_wallet_webpush/mcp/fly_v419_2026-08-03/)  
**Канон:** CTAs в `ActiveOrdersAccordion`; `deviceDetect`; `GET …/wallet_pass`; FCM `subscribeOrderPush`; init LS/permission.  
**Deploy:** push `35b7f00c` · Fly **v419** · `deployment-01KZ3CAC9RNSCPZRZ5VZWEWW8K`  
**MCP:** Android → Push CTA · iPhone CriOS → Wallet CTA · receipt toggle PASS (Point A Aram).  
**Дальше:** апрув заказчика. PKCS7 prod — PRACTICES.

### Status inside cart sheet (2026-07-31)

| Что | Статус |
|-----|--------|
| Intake + SPEC + RED/GREEN | **`[x]`** |
| `OrderStatusSheet` внутри `CartSheet` (embedded) | **`[x]`** |
| Убран overlay mount из `App.svelte` | **`[x]`** |
| Push + Fly deploy | **`[x]`** v418 · `876b5432` |
| MCP Fly (DOM inside cart) | **PASS** · [`mcp/fly_v418/`](../milestones/veha_2/artifacts/status_inside_cart_sheet/mcp/fly_v418/) |

**ТЗ:** [`Статус заказа внутри шторки корзины не слой поверх.md`](../milestones/veha_2/requirements/customer_tasks/Статус%20заказа%20внутри%20шторки%20корзины%20не%20слой%20поверх.md)  
**Дальше:** апрув заказчика.

### Quick Repeat Bottom Sheet — ревизия (2026-07-31)

| Что | Статус |
|-----|--------|
| Intake + SPEC + RED/GREEN B1–B4 + F1–F3 | **`[x]`** |
| PHASE 3 REVIEW (tests + sanity + ops) | **`[x]`** |
| MCP local feedback 07 | **PASS** · full-width 390/390 · repeat hidden |
| Push + Fly deploy | **`[x]`** v417 · tip `6fa90731` (код с `0b71d5f9` / v416) |
| MCP Fly (hide + full-width + one-open) | **PASS** · [`mcp/fly_v417/`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/mcp/fly_v417/) (+ v416 archive) |
| Full-width OrderStatusSheet | **`[x]`** MCP `390/390` z60 |

**ТЗ:** [`Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md`](../milestones/veha_2/requirements/customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md)  
**Артефакты:** [`quick_repeat_bottom_sheet/`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/)  
**Канон:** hide «повторить» при `accepted|preparing|ready`; API `has_active_order`; cache v3; barista bust; FE clear+gate; status sheet full-width.  
**Коммиты:** `01c61262` (BE) · `ba0abf7f` (FE) · REVIEW `0b71d5f9` · evidence tip `6fa90731`.  
**Дальше:** апрув заказчика; optional visible-repeat MCP после закрытия залипших active.

### Active orders accordion + receipt #36 (2026-07-31)

| Что | Статус |
|-----|--------|
| Intake + ревизия ТЗ (чек read-only) | **`[x]`** |
| PHASE 1–3 SPEC/RED/GREEN/REVIEW | **`[x]`** |
| Push + Fly deploy | **`[x]`** v415 · `cdab89ee` |
| MCP Fly vs скрины 01/02 | **PASS** · evidence `mcp/` |
| Stub CTA / accordion split | **backlog** PRACTICES |

**ТЗ:** [`Мульти-статусная шторка активных заказов с просмотром состава чека.md`](../milestones/veha_2/requirements/customer_tasks/Мульти-статусная%20шторка%20активных%20заказов%20с%20просмотром%20состава%20чека.md)  
**Артефакты:** [`active_orders_accordion_receipt/`](../milestones/veha_2/artifacts/active_orders_accordion_receipt/) · MCP [`mcp/`](../milestones/veha_2/artifacts/active_orders_accordion_receipt/mcp/)  
**Дальше:** апрув заказчика на визуал; stub CTA copy.

### Order status compact sheet + Push #35 (2026-07-31)

| Что | Статус |
|-----|--------|
| Intake + SPEC + RED + GREEN A/B/C | **`[x]`** |
| PHASE 3 REVIEW (tests + sanity + ops) | **`[x]`** |
| Push + Fly deploy | **`[x]`** v414 · `3bbd62a8` |
| MCP Fly vs скрины артефактов | **PASS** labels/track/z60 · evidence `mcp/` |
| PKCS7 / device register / pass UI | **backlog** PRACTICES |

**ТЗ:** [`Интеграция статусной модели…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md)  
**Артефакты:** [`order_status_compact_sheet_push/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/) · MCP [`mcp/`](../milestones/veha_2/artifacts/order_status_compact_sheet_push/mcp/)  
**Runbook Wallet:** [`APPLE_WALLET_ORDER_PASS.md`](../milestones/veha_2/runbooks/APPLE_WALLET_ORDER_PASS.md)  
**Дальше:** апрув заказчика на визуал; PKCS7 backlog.

### T-Kassa SBP Autopay AccountToken #34 (2026-07-30)

| Что | Статус |
|-----|--------|
| Intake + SPEC + RED + GREEN | **`[x]`** |
| REVIEW: ownership fix + settle ChargeQr + ops | **`[x]`** |
| Checkout UI checkbox / default «Ваш счет СБП» | **`[x]`** |
| MCP Fly UI/API smoke | **`[x]`** — чекбокс, `save_sbp_account`, `sbp_accounts`, `sbp/charge` route |
| MCP Setup bind (Recurrent) | **PASS** 2026-08-03 — QR NSPK (не 3013) |
| MCP manual SBP | **PASS** — NSPK QR |
| MCP Zero-Click ChargeQr SUCCESS | **ждёт банк** — AccountToken после первой привязки |

**MCP:** [`mcp_fly_sbp_autopay_2026-07-30.json`](../milestones/veha_2/artifacts/tbank_sbp_autopayments_account_token/mcp_fly_sbp_autopay_2026-07-30.json) · пакет [`charge_unlocked`](../milestones/veha_2/artifacts/tbank_charge_unlocked_mcp_2026-08-03/)  
**ТЗ:** [`Интеграция Автоплатежей СБП Т-Касса в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20Автоплатежей%20СБП%20Т-Касса%20в%20PWA.md)  
**Артефакты:** [`tbank_sbp_autopayments_account_token/`](../milestones/veha_2/artifacts/tbank_sbp_autopayments_account_token/)  
**Дальше:** заказчик: 1× СБП с привязкой в банке → «Ваш счет СБП» → Zero-Click; затем короткий MCP ChargeQr.

**Review findings (закрыты в REVIEW):**
- P1 session мог списать свой AccountToken за чужой заказ → 404 mismatch
- P2 CONFIRMED без settle order → PaymentStatusUpdater после ChargeQr
- P1 race double charge → with_lock (частично; полный idempotency key — backlog)

### T-Bank inline payment + button statuses #32 (2026-07-30)

| Что | Статус |
|-----|--------|
| Intake + SPEC + BE + FE FSM/UI/SMS | **`[x]`** |
| Фикс MCP (order + remount + full-width + no ERROR reset) | **`[x]`** |
| defer_payment_init + WidgetPaymentInitiator Charge+settle | **`[x]`** `c9e68271` deployed |
| MCP Fly PASS (PROCESSING / ERROR / СБП / карта+ / SMS) | **`[x]`** |
| SUCCESS ✔ live | **PASS** 2026-08-03 — widget_init CONFIRMED `#202608-0005` |

**MCP SUCCESS:** пакет [`charge_unlocked`](../milestones/veha_2/artifacts/tbank_charge_unlocked_mcp_2026-08-03/)  
**MCP SUCCESS attempt (blocked):** [`mcp_fly_inline_pay_2026-07-30_charge_blocked.json`](../milestones/veha_2/artifacts/tbank_inline_payment_button_statuses/mcp_fly_inline_pay_2026-07-30_charge_blocked.json)  
**MCP UI PASS:** [`mcp_fly_inline_pay_2026-07-30_pass.json`](../milestones/veha_2/artifacts/tbank_inline_payment_button_statuses/mcp_fly_inline_pay_2026-07-30_pass.json)  
**Дальше:** апрув заказчика.

### T-Kassa Widget One-Click + Fallback #33 (2026-07-29)

| Что | Статус |
|-----|--------|
| BE: connection_type Widget + widget_init endpoint | **`[x]`** |
| FE: shopWidgetPayFsm.js + widgetInlinePay.js | **`[x]`** |
| FE: InlinePayFallback.svelte + RepeatSection inline flow | **`[x]`** |
| FE: Fallback SBP + карта+ + expanded cards | **`[x]`** |
| PHASE 3 REVIEW | **`[x]`** |
| MCP live Charge one_click | **PASS** 2026-08-03 · `#202608-0001` |

**ТЗ:** [`Интеграция виджета быстрой оплаты Т-Кассы…`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20виджета%20быстрой%20оплаты%20Т-Кассы%20и%20One-Click%20сценария%20в%20PWA.md)  
**Дальше:** апрув заказчика.  

### Auth funnel cascade Flash Call×2 → SMS (2026-07-29)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR + артефакты | **`[x]`** |
| PHASE 1: SPEC (`todo.md`) | **`[x]`** |
| PHASE 2: RED (тесты) | **`[x]`** `f7313fdb` |
| PHASE 2: GREEN (BE+FE) | **`[x]`** `b2685910` + `8b76da10` |
| PHASE 3: REVIEW | **`[x]`** `8d94b95b` |

**ТЗ:** [`Рефакторинг воронки авторизации…`](../milestones/veha_2/requirements/customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20x2%20SMS.md)  
**Артефакты:** [`auth_funnel_flash_call_x2_sms_ru/`](../milestones/veha_2/artifacts/auth_funnel_flash_call_x2_sms_ru/)  
**todo:** [`SESSION todo.md`](todo.md)  
**Деплой:** `fly deploy` 2026-07-29 — `cd26cb1b` pushed + deployed, Fly health OK, витрина + API 200.  
**Статус:** **done** (задеплоено).

### Fly Test sticky / inactive last_ordered (2026-07-28)

| Что | Статус |
|-----|--------|
| Root cause: last_ordered = inactive Fly Overnight | **`[x]`** |
| FE preferred + bootstrap bounce | **`[x]`** local |
| BE last_ordered skip inactive | **`[x]`** local |
| Push / Fly / MCP Ленин | **`[ ]`** ждать апрув deploy |

**Телефон Арама:** `+79639124847` — готово (без регресса).  
**Point A:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  

### Aram real phone link (2026-07-28)

| Что | Статус |
|-----|--------|
| Настоящий номер от владельца | **`[x]`** `+79639124847` |
| `link_phone!` + merge donor `e01d7bd4` | **`[x]`** |
| Доказательство заказов/оплат Point A | **`[x]`** |
| Deploy | **не делали** (только данные) |

**Point A:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Артефакт:** [`fly_aram_real_phone_link_2026-07-28.json`](../milestones/veha_2/artifacts/aram_phone_restore/fly_aram_real_phone_link_2026-07-28.json)  
**MCP после deploy v400:** [`fly_mcp_aram_phone_v400_2026-07-28.json`](../milestones/veha_2/artifacts/aram_phone_restore/fly_mcp_aram_phone_v400_2026-07-28.json) · скрины `03_…` Point A · `04_…` профиль `+79639124847`  
**ТЗ:** [`Вернуть номер телефона Арама…`](../milestones/veha_2/requirements/customer_tasks/Вернуть%20номер%20телефона%20Арама%20в%20профиле.md)

### Repeat recommendations missing (2026-07-28)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR + ISSUES | **`[x]`** |
| Root cause Fly Overnight vs Point A | **`[x]`** |
| Код restore→bootstrap + preferred + inactive skip | **`[x]`** |
| Deactivate Fly Overnight prod | **`[x]`** |
| SBP 3001 friendly UX | **`[x]`** |
| Push / Fly / MCP скрин «повторить» | **`[x]`** v399 · [`fly_mcp_repeat_restored_2026-07-28.json`](../milestones/veha_2/artifacts/repeat_recommendations_missing/fly_mcp_repeat_restored_2026-07-28.json) |

**Скрин:** [`02_fly_aram_point_a_repeat_restored.png`](../milestones/veha_2/artifacts/repeat_recommendations_missing/screenshots/02_fly_aram_point_a_repeat_restored.png) — Ленин + «повторить»  
**ТЗ:** [`Пропали рекомендации…`](../milestones/veha_2/requirements/customer_tasks/Пропали%20рекомендации%20повторить%20на%20витрине.md)

### Auth funnel cascade Flash→Messenger→SMS (2026-07-28)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR + артефакты | **`[x]`** |
| PHASE 1: SPEC | **`[x]`** · `todo.md` |
| Шаг 1 Экран 1 (телефон → flash_call) | **`[x]`** GREEN |
| Шаг 2 Экран 2 (PIN 4 + auto-verify) | **`[x]`** GREEN |
| Шаг 3 Flash cascade #1/#2 (20с+20с) | **`[x]`** GREEN |
| Шаг 4 Messenger + SMS fallback | **`[x]`** GREEN (FE; backend messenger — Шаг 5) |
| Шаг 5 Backend messenger + flag + 4-digit OTP | **`[x]`** |
| Шаг 6 rate limits 20/30/60 | **`[x]`** |
| Push / Fly / MCP | **`[x]`** v397 · [`fly_mcp_auth_funnel_2026-07-28.json`](../milestones/veha_2/artifacts/auth_funnel_cascade_flash_messenger_sms/fly_mcp_auth_funnel_2026-07-28.json) |
| Апрув заказчика | **`[ ]`** |

**ТЗ:** [`Рефакторинг воронки авторизации…`](../milestones/veha_2/requirements/customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20Messenger%20SMS.md)  
**Дальше:** апрув заказчика; live NSPK/СБП — отдельно (банк 3001).

### CODE:BLACK T-Kassa SBP · PWA lifecycle (2026-07-27)

| Что | Статус |
|-----|--------|
| Intake / SPEC / GREEN / lifecycle MCP | **`[x]`** |
| Push / Fly | **`[x]`** v396 · Receipt.Email |
| Aram OTP → SBP screenshots 01–07 | **`[x]`** |
| Live nspk deep link | **`[ ]`** банк **3001** СБП недоступна на терминале |
| Апрув заказчика | **`[ ]`** |

**Заказчику:** [`screenshots/`](../milestones/veha_2/artifacts/codeblack_t_kassa_sbp_tokenization/screenshots/)  
**Блокер NSPK:** включить СБП в кабинете Т-Кассы (не код).

### SBP Deep Link + card tokenization · Т-Касса v2 (2026-07-27)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR + артефакты | **`[x]`** |
| PHASE 1: SPEC | **`[x]`** |
| Волна A + UI/poll/char/mask (1–11) | **`[x]`** GREEN |
| Push / Fly deploy | **`[x]`** v394 · `6154539` |
| MCP / UI приёмка на Fly | **`[x]` PASS** (OTP sheet SKIP) · [`fly_mcp_sbp_epic_2026-07-27.json`](../milestones/veha_2/artifacts/sbp_deep_link_card_tokenization/fly_mcp_sbp_epic_2026-07-27.json) |
| Апрув заказчика | **`[ ]`** |

**Deploy:** shopSbpPay в бандле; `POST .../sbp/init` отвечает 401 без сессии (роут жив). Полный клик SBP — после email OTP / вручную.

### Repeat order invalid token · PaymentMethodsSheet (2026-07-27)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR + артефакты | **`[x]`** |
| PHASE 1: SPEC | **`[x]`** |
| RED / GREEN | **`[x]`** · Node 14/0 · Ruby repeat+payment 27/0 |
| Push / Fly deploy | **`[x]`** v393 · `f0877ac` |
| MCP / UI приёмка на Fly | **`[x]` PASS** · [`fly_mcp_repeat_invalid_token_2026-07-27.json`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/fly_mcp_repeat_invalid_token_2026-07-27.json) |
| Апрув заказчика | **`[ ]`** |

**Backlog:** proactive `rebill_valid` в API карт (cold start без prior one_click fail) — отдельный шаг + migration gate.

### Profile Email↔Phone merge (2026-07-27)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR + артефакты | **`[x]`** |
| PHASE 1: SPEC | **`[x]`** |
| RED / GREEN | **`[x]`** · тесты 47/0 + регрессия 30/0 |
| DDL verified flags | **`[x]`** `20260727100000` |
| Push / Fly deploy | **`[x]`** v392 · `9184cde` |
| MCP Fly | **`[x]` PASS** · [`fly_mcp_profile_merge_2026-07-27.json`](../milestones/veha_2/artifacts/profile_email_phone_merge/fly_mcp_profile_merge_2026-07-27.json) |
| Апрув заказчика | **`[ ]`** |

### Phone OTP SMS / Flash Call (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake / SPEC / RED / GREEN | **`[x]`** |
| Push + Fly deploy | **`[x]`** v390 · `SHOP_OTP_LOG_FALLBACK=true` |
| MCP Fly | **`[x]` PASS** · [`fly_mcp_phone_otp_2026-07-24.json`](../milestones/veha_2/artifacts/phone_otp_sms_flash_call/fly_mcp_phone_otp_2026-07-24.json) |
| Апрув заказчика | **`[ ]`** |

### Долговечные сессии PWA (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** |
| PHASE 1: SPEC | **`[x]`** · `todo.md` |
| RED / GREEN | **`[x]`** · тесты 13+18 / 0 |
| Push + Fly deploy | **`[x]`** v388 → fix → **v389** |
| MCP Aram Silent Refresh | **`[x]` PASS** · [`fly_mcp_aram_silent_refresh_2026-07-24.json`](../milestones/veha_2/artifacts/pwa_durable_sessions_silent_refresh/fly_mcp_aram_silent_refresh_2026-07-24.json) |

### Анализ статусной модели платежей (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** |
| Read-only анализ Init/webhook/статусы/Cancel | **`[x]`** ответ в чате |
| Код / Cancel-Refund API | не меняли · API банка **нет** |

### Peek repeat plus → cart (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** |
| Embedded `+` → `addToCart` · prog35 | **`[x]`** код · тесты 52/0 |
| Redeploy + MCP Aram | **`[ ]`** по апруву |

### Default peek empty (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** |
| Empty → peek · prog34 | **`[x]`** код · тесты 23/0 |
| Redeploy + MCP guest | **`[ ]`** по апруву |

### MCP Арам — cart sheet fixes (2026-07-24)

| Что | Статус |
|-----|--------|
| Fly deploy | **v384** · build prog33 |
| OTP Aram Demo Point A | **`[x]`** |
| Скрины | [`screenshots/`](../milestones/veha_2/artifacts/cart_sheet_fixes_mcp_2026-07-24/screenshots/) 01–04 |
| JSON | [`fly_mcp_aram_fixes_2026-07-24.json`](../milestones/veha_2/artifacts/cart_sheet_fixes_mcp_2026-07-24/fly_mcp_aram_fixes_2026-07-24.json) |
| Checks | **5/5 PASS** |

### Repeat remove global pay (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** |
| Убрать «повторить в 1 клик» + «+ещё» · prog33 | **`[x]`** код |
| Redeploy + MCP | **`[x]`** v384 · 5/5 PASS |

### Empty orders placeholder (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** |
| Надпись только без истории · prog32 | **`[x]`** код · тесты 52/0 |
| Redeploy + MCP | **`[ ]`** по апруву |

### Cart sheet remove undo button (2026-07-24)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** |
| Убрать кнопку/полоску undo · prog31 | **`[x]`** код · тесты 43/0 |
| Redeploy + MCP | **`[ ]`** по апруву |

### MCP UI Арама — скрины на диске (2026-07-23)

| Что | Факт |
|-----|------|
| PNG | [`screenshots/aramfifa_mcp_2026-07-23/`](../milestones/veha_2/artifacts/usercards_save_card/screenshots/aramfifa_mcp_2026-07-23/) 01…07 |
| JSON | [`aramfifa_mcp_ui_2026-07-23.json`](../milestones/veha_2/artifacts/usercards_save_card/aramfifa_mcp_ui_2026-07-23.json) |
| Карты UI | **\*5953** + **\*8782** (04_payment_sheet_two_cards.png) |
| Redeploy OTP-fix | **`[ ]`** по апруву |

### Worker + OTP/session restore (2026-07-23)

| Что | Факт |
|-----|------|
| Worker Fly `48ee61ea…` | **started** · SolidQueue · restart always |
| OTP на F5 | Fix: status → linker + `GuestCustomerResolver` + `restoreGuestSession` |
| Тесты | 26/0 (restore + OTP/cards) |
| Redeploy Fly (OTP UI) | **`[ ]`** по апруву |
| Витрина Арама | https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 |

### Diag aramfifa UserCards (2026-07-23) — read-only

| Что | Факт |
|-----|------|
| Customer | `aramfifa100@gmail.com` → `2bc37279…` |
| Карты в БД | **\*5953** (default) + **\*8782**, active, last_used сегодня |
| Заказы | 53 на **Demo Coffee Point A** only; Fly Test = 0 |
| Worker | был stopped → **started** |
| Артефакт | [`aramfifa_full_diag_2026-07-23.json`](../milestones/veha_2/artifacts/usercards_save_card/aramfifa_full_diag_2026-07-23.json) |

### Expanded no catalog grid (2026-07-23)

| Что | Статус |
|-----|--------|
| Убрать сетку из expanded · оставить список заказов | **`[x]`** код prog30 · тесты 51/0 |
| Redeploy + MCP | **`[ ]`** по апруву |

### Cart sheet gesture hit area (2026-07-23)

| Что | Статус |
|-----|--------|
| Intake ТЗ + CBR | **`[x]`** `d5fec5e` |
| Hit-area `min-h-20` · `SWIPE_UP_PX=20` · prog29 | **`[x]`** код · тесты 45/0 |
| Redeploy Fly + MCP | **`[x]`** v380 · 7/7 PASS · [`fly_gesture_hit_area_mcp_2026-07-23.json`](../milestones/veha_2/artifacts/cart_sheet_gesture_hit_area/fly_gesture_hit_area_mcp_2026-07-23.json) |
| Вторая правка заказчика | **`[ ]`** текста нет |

### Rules (2026-07-22)

| Что | Статус |
|-----|--------|
| Апрув шага = смысл текста («ебашь/сделай»), не культ `go` | **`[x]`** `a1d9383` |

### Quick Repeat layout = скрины заказчика (2026-07-22 → 2026-07-23)

| Что | Статус |
|-----|--------|
| Hidden без «повторить» · peek одна шторка заказ→+цена→embedded repeat · prog28 | **`[x]`** код · тесты 57/0 |
| Redeploy Fly + MCP визуал | **`[x]`** v378 · 6/6 PASS · [`fly_layout_prog28_mcp_2026-07-23.json`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_layout_prog28_mcp_2026-07-23.json) |

### Quick Repeat Bottom Sheet (2026-07-21) — код DONE, ждёт deploy + MCP

| Что | Статус |
|-----|--------|
| ТЗ + 6 скринов в артефактах (`quick_repeat_bottom_sheet/`) | **`[x]`** |
| B1 сервис · B2 категории · B3 кэш+bust (hot-path OrderCreator/PaymentStatusUpdater) · B4 API | **`[x]`** GREEN |
| F1 клиентский кэш · F2 секция «повторить» · F3 счётчики · F4 действия+тосты · F5 «оплатить в 1 клик» | **`[x]`** GREEN |
| REVIEW: rubocop 0 offenses · services+API+RLS 123/0 · оплата §2.3+one_click 29/0 · шторка 27/0 | **`[x]`** |
| **Deploy Fly** — `deployment-01KY2FKAVV4MDDXR3ANANCCCJE` (release + smoke OK) | **`[x]`** 2026-07-21 |
| **MCP на Fly** — 6/6 PASS · [`fly_acceptance_mcp_2026-07-21.json`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_acceptance_mcp_2026-07-21.json) + 6 скринов | **`[x]`** 2026-07-21 |
| **MCP real-run без стабов** — 8/8 PASS + 1 SKIP (живое списание) · [`fly_real_run_mcp_2026-07-21.json`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_real_run_mcp_2026-07-21.json) + 5 скринов + **чеклист заказчику** (`customer_checklist`). Посеян клиент `mcp-quickrepeat@example.com` с историей (4 mobile-заказа, Neon), вход штатным email-OTP | **`[x]`** 2026-07-21 |
| UX-вопросы владельцу: UX-1 (empty клипает повтор) · UX-2 (peek 2+ повтор вытесняет корзину) · UX-3 (повтор перекрывает форму email на checkout) | **open** → DEMO_FEEDBACK |
| **Код-ревью** (SBR): блокеров нет; 3 замечания исправлены — стабильный ключ счётчика, тост «Добавлено N из M», rescue в `bust_cache!` (RED `397dd5c` / GREEN `9afdff7`); регрессия оплаты §2.3 24/0 + callback 31/0 | **`[x]`** 2026-07-21 |
| **Редеплой фиксов ревью + FIX-A…F на Fly** | **`[x]`** owner deploy `01KY4MHZPD7YS2D9NS4NP54B09` (v377) |
| **FIX-A…F жалоба заказчика** — OTP→customer_id, нормализация модификаторов, UI по скринам | **`[x]`** код `6ab3081`/`ac1f894` |
| **MCP DevTools после redeploy** — FIX-A…F на Fly | **`[x]`** 9/9 PASS · [`fly_fix_af_mcp_2026-07-22.json`](../milestones/veha_2/artifacts/quick_repeat_bottom_sheet/fly_fix_af_mcp_2026-07-22.json) |
| Апрув заказчика / `[x]` в CBR | **`[ ]`** |

**Решения, требующие сверки на приёмке:** hidden — без секции повтора (канонные чипы корзины) · клик по карточке каталога — переход в Product (конфликт Шагов 9/12 ТЗ) · «оплатить в 1 клик» — автооткрытие шита оплаты, списание с подтверждением «Оплатить».
**Pre-existing (не блокер):** `checkout_ui_cleanup_test.rb` конфликтует с каноном оплаты через шторку → ISSUES 🟡.

### Bottom sheet expanded grid (2026-07-21) — ЗАКРЫТА

| Что | Статус |
|-----|--------|
| ТЗ (поправлено владельцем: «внутри сетки») + скрины в артефактах | **`[x]`** |
| Grid в шторке (`7683dee`) — отклонён, откачен | **`[x]`** откат `4f1d3e8` |
| Канон принят владельцем: expanded — 1-й ряд сетки · peek — 2-й ряд · hidden — половина | **`[x]`** скрин `01_…` |
| Тесты-фиксаторы `bottom_sheet_heights_canon_test.rb` · регрессия cart sheet 59/0 | **`[x]`** |
| **Deploy** | **`[ ]`** — только по явному апруву владельца |

**Не деплоили.** Локальные env-грабли (не блокеры): полный `test/integration/shop/` зависает (ISSUES 🟡), `vite build` зациклен на Windows — компиляция проверялась через svelte/compiler.

### Intake-правило (новое, 2026-07-21)

| Что | Статус |
|-----|--------|
| `coffeeos-customer-intake.mdc` (PHASE 0: доки до SPEC) | **`[x]`** |
| `RULES_INDEX.md` строка | **`[x]`** |

**Следующий шаг:** апрув/MCP «Bottom sheet expanded grid» по go владельца; либо следующая задача по CHECKLIST/CBR.

### Точка отката (не потерять)

| | |
|--|--|
| **UI-код** | `a1abfa0` — catalog −15% · vh prog26 · hidden chips |
| **Артефакт** | [`../milestones/veha_2/artifacts/product_card_hidden_mode/CHECKPOINT.md`](../milestones/veha_2/artifacts/product_card_hidden_mode/CHECKPOINT.md) |
| **Скрин принятого** | `04_fly_accepted_hidden_chips_2026-07-20.png` |
| **Ops-коммит** | **`fa4ae08`** |

```bash
git checkout a1abfa0   # код UI этого положения
```

### Cart sheet / каталог — **принято**

| Что | Статус |
|-----|--------|
| Карточки −15% · vh prog26 · hidden chips | **`[x]`** на Fly |
| `demo:catalog_images` | **`[x]`** |
| Код в checkpoint-шаге | **не меняли** |

**Следующий шаг:** новые фичи отдельно; откат сюда — таблица выше.

### SBR workflow (новое)

| Что | Статус |
|-----|--------|
| `spec-build-review.mdc` | **`[x]`** |
| `todo.md` в `docs/operations/session/` | **`[x]`** |
| RED/GREEN substep в commit-ops / task-workflow | **`[x]`** |

**Использование:** Agent Mode + `@spec-build-review.mdc` + SPEC → ждёт **go** на каждую фазу.

**Следующий шаг:** применить SBR на следующую фичу по CHECKLIST/CBR.

### Checkout CartSheet UX (эталон заказчика)

| Что | Статус |
|-----|--------|
| Канон в ТЗ | **`[ ]`** § **Канон UX checkout** — stacked peek+pay |
| Код peek + pay из шторки (без inline) | **`[x]`** |
| **Фаза 2 stacked** (одна шторка, без backdrop) | **`[x]`** код · MCP **`[ ]`** |
| MCP Fly stacked + 8924/8925 | **`[ ]`** NOT_RUN |
| **Апрув заказчика** | **`[ ]`** |

### UserCards / save_card — канон ТЗ

| Что | Статус |
|-----|--------|
| Канон-ТЗ | [`Исправление сохранения карты в UserCards…`](../milestones/veha_2/requirements/customer_tasks/Исправление%20сохранения%20карты%20в%20UserCards%20после%20успешной%20оплаты.md) |
| Review БАГ-1/2/3 | **`[x]`** · deploy **v359** |
| Fly Фаза 0 diagnose | **`[x]`** [`usercards_fly_diagnose_2026-07-16.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_diagnose_2026-07-16.json) |
| Фаза 1 fix persist | **`[x]`** deploy **v362** |
| Runbook привязки (Фаза 3.1) | **`[x]`** [`USERCARDS_SAVE_CARD_FLOW.md`](../milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md) |
| Root cause 8866531465 (Фаза 3.2) | **`[x]`** [`usercards_fly_payment_root_cause_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_fly_payment_root_cause_2026-07-18.json) |
| Deploy v366 + 3.4 MCP 2 карты | **`[x]`** [`usercards_phase34_mcp_2026-07-18.json`](../milestones/veha_2/artifacts/usercards_save_card/usercards_phase34_mcp_2026-07-18.json) · скрин [`usercards_phase34_live_2026-07-18_payment_sheet_two_cards.png`](../milestones/veha_2/artifacts/usercards_save_card/screenshots/usercards_phase34_live_2026-07-18_payment_sheet_two_cards.png) |
| Апрув заказчика (3.5) | **`[ ]`** — скрин 8925 (2 строки *5953 + *8782) |

**Следующий шаг UserCards:** апрув скрина 8925 → **go 3.5** · E2E fix 3.3 — живая MIR карта заказчика ≠ *5953 (prod отклоняет test PAN).

### WIPE 2026-07-14 — сохранение карты / checkout card UX

Старые ТЗ и реализация **снесены**. Не читать git-историю / удалённые артефакты как канон.

| Что | Статус |
|-----|--------|
| Канон-ТЗ | см. выше |
| Код / старые ТЗ / артефакты | **удалены / stub wipe** |
| Регрессия wipe | **PASS** · 44 + 105 runs, 0 fail |

### Product card peek cart — отображение набранных позиций в карточке товара

| Что | Статус |
|-----|--------|
| ТЗ | [`отображение набранных позиций и функциональность в режиме pee.md`](../milestones/veha_2/requirements/customer_tasks/отображение%20набранных%20позиций%20и%20функциональность%20в%20режиме%20pee.md) |
| Скрины 2 шт. | **`[x]`** `artifacts/product_card_peek_cart/screenshots/` |
| S1 red-тест | **`[x]`** → **green** после Шага 4 |
| S2 red-тест | **`[x]`** → **green** после Шага 4 |
| Код Product + ProductCartPeek | **`[x]`** S1–S7 |
| Shop suite регрессия | **`[x]`** 313 PASS (до S3) · S1–S7 unit PASS |
| Отчёт Было/Стало (Шаг 5) | **`[x]`** в ТЗ customer_tasks |
| **Следующий шаг** | MCP UI на Fly / апрув заказчика — ждать `go` |

### B1.13-CR-BOTTOM-NAV — убрать нижний бар (rev3)

| Что | Статус |
|-----|--------|
| ТЗ | **`[x]`** B1_13 § CR стр. **~69** · **КАРТА** стр. **~14** |
| Ответы 1–7 | **`[x]`** 2026-07-07 · [`b113_cr_bottom_nav_answers_2026-07-07.json`](../milestones/veha_2/artifacts/demo-feedback/b113_cr_bottom_nav_answers_2026-07-07.json) |
| Код F1–F4 | **`[x]`** · shop 297 PASS |
| Cart sheet прижат к низу | **`[x]`** `CART_SHEET_BOTTOM_REM=0` · build `prog22` · visibility catalog+checkout |
| Deploy / A1 | deploy **`[ ]`** (ждёт go) · **A1 апрув `[ ]`** |

### B1.13 — S4: openEditCard trigger (Expanded cart image)

| Что | Статус |
|-----|--------|
| Код | `ae0fd0e` · `CartSheet.svelte` + `cartSheetStore.js` |
| Тест | `test/integration/shop/cart_expanded_image_open_edit_card_test.rb` — PASS |

### B1.13 — S2/S2.1: dynamic +X₽ on checkout button (undo/error)

| Что | Статус |
|-----|--------|
| Код | `e1f34eb` · `CartSheet.svelte` + `cartSheetStore.js` |
| Тесты | `test/integration/shop/cart_checkout_button_total_dynamic_test.rb` — PASS; `b113_s2_cart_popup_test.rb` updated |

### B1.13 — S2 экстремумы: auto font + unavailable cart UX

| Что | Статус |
|-----|--------|
| Код | `ff0a42c` · `CartSheet.svelte` + `cartSheetStore.js` |
| Тесты | `cart_checkout_button_total_dynamic_test.rb` — PASS |

### B1.13 — сумма только внутри кнопки checkout

| Что | Статус |
|-----|--------|
| Код | `46e8f0b` · `CartSheet.svelte` — убран серый span рядом с кнопкой |
| Тесты | `cart_checkout_button_total_dynamic_test.rb` + b113_s2* — PASS |

### Batch апрув 2026-07-05 (задачи «проверено»)

| Что | Статус |
|-----|--------|
| B1.4 PWA · B2-S1 · B1.11 · B1.14-client · B1.13-S1 | **апрув `[x]`** |
| ISSUES B1.11-BUG-OVERNIGHT | **resolved** |
| Артефакт | `customer_verified_batch_2026-07-05.json` |

### B1.11 — BUG-OVERNIGHT Fly MCP (2026-07-05)

| Что | Статус |
|-----|--------|
| Deploy | **`[x]`** (заказчик) |
| Fly MCP | **PASS** — create пн 09:23–01:24 · tenant `af4f78d6-c66b-428e-8ee4-5a609c5c9131` |
| Артефакты | `b111_bug_overnight_fly_post_deploy_2026-07-05.json` · 3 скрина Fly |
| **Следующий шаг** | ~~апрув~~ **`[x]` 2026-07-05** · ISSUES closed |

### B1.11 — BUG-OVERNIGHT fix (2026-07-05)

| Что | Статус |
|-----|--------|
| F1–F4 | **`[x]`** · 36 tests PASS |
| MCP | Chrome DevTools локально PASS — create пн 09:23–01:24 |
| Артефакты | `b111_bug_overnight_mcp_2026-07-05.json` · 3 скрина |
| **Следующий шаг** | **A1** — `fly deploy` + апрув заказчика на Fly |
| ТЗ файл | [`B1_11_tenant_operating_hours.md`](../milestones/veha_2/requirements/customer_tasks/B1_11_tenant_operating_hours.md) |

### B1.11 — BUG-OVERNIGHT docs (2026-07-04)

| Что | Статус |
|-----|--------|
| Канон | код MVP `[x]` · ночная смена **в scope** (Q2 «полночь не MVP» — **архив**) |
| Баг | УК create: `09:23`–`01:24` → `must be after opens_at` |
| Root cause | `TenantWeekdaySchedule#closes_after_opens` + `TenantOperatingHours` same-day |
| Docs | `B1_11` § BUG-OVERNIGHT · ISSUES · DEMO_FEEDBACK · CBR/CHECKLIST/README выровнены |
| Артефакт | `b111_bug_overnight_customer_2026-07-04.json` |
| **Следующий шаг** | ~~**`go`** → F1–F4~~ → **A1 deploy+апрув** |
| ТЗ файл | [`B1_11_tenant_operating_hours.md`](../milestones/veha_2/requirements/customer_tasks/B1_11_tenant_operating_hours.md) |


| Что | Статус |
|-----|--------|
| ТЗ | **rev2 only** — v1 iframe / «без галочки» = архив |
| Код R1–R3 · Q-R2 | **`[x]`** · MCP 10/10 · RSA Fly `[x]` |
| **Фикс** | fallback `TbankPaymentSync.sync_order!` (GetState) в `settle_confirmed!` · коммит **`1081dac`** |
| **Тесты** | 7 + 14 runs, 0 failures |
| **Следующий шаг** | **A1** — живая CONFIRMED оплата заказчика → ISSUES close (Fly v328 уже есть) |

### Security hygiene (2026-07-03)

| Что | Статус |
|-----|--------|
| `permit!` → explicit weekday permit | `[x]` |
| rack / rack-session / view_component CVE | `[x]` |
| Регрессия shop + tenants controller | PASS |
| **V2-SEC-08** bundler-audit CVE (rails/puma/nokogiri) | **open — обязательно** → `PRACTICES.md` |
| **Следующий шаг** | баги по списку · V2-SEC-08 · deploy по `go` |

### Sentry triage (2026-07-03)

| Issue | Суть | Действие |
|-------|------|----------|
| RUBY-9 | `includes(:product)` на OrderItem без ассоциации | **fixed** commit |
| RUBY-Q/M/N/K/P/R | Neon compute quota exceeded (~2wk ago) | **Archive** — квота оплачена |
| RUBY-S | pg_stat_statements без superuser | **Archive** — известно |
| RUBY-T/D | fly smoke rake (403/ArgumentError) | **Archive** — не user-facing |
| RUBY-R | db:migrate queue local socket (при quota outage) | **Archive** |

### B1.14 вЂ” Р°РґСЂРµСЃ С‚РѕС‡РєРё + РІС‹Р±РѕСЂ С‚РѕС‡РєРё РІ С€Р°РїРєРµ РІРёС‚СЂРёРЅС‹

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| РўР— СЌС‚Р°Рї 0 | `[x]` 2026-06-23 вЂ” С‚РµРєСЃС‚ Р·Р°РєР°Р·С‡РёРєР° РґРѕСЃР»РѕРІРЅРѕ + РѕС‚РІРµС‚С‹ РІР»Р°РґРµР»СЊС†Р° Q1вЂ“Q10 |
| Р­С‚Р°Рї 0 JSON | [`b114_stage0_scope_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_stage0_scope_2026-06-23.json) В· [`b114_screenshot_baseline_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_screenshot_baseline_2026-06-23.json) |
| РЎРєСЂРёРЅС‹ В«РґРѕВ» | [`b114_shop_header_coffeeos_before_2026-06-23.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b114_shop_header_coffeeos_before_2026-06-23.png) В· [`b114_uk_tenants_card_before_2026-06-23.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b114_uk_tenants_card_before_2026-06-23.png) |
| РљРѕРґ | **B1.14-3d index map** `[x]` 2026-06-23 В· **B1.14-4** cart `[ ]` |
| **Deploy** | `bin/fly_deploy.sh` вЂ” WSL fix (`--remote-only`, staging `/mnt/c/`) В· РїРѕРІС‚РѕСЂРёС‚СЊ РґРµРїР»РѕР№ |
| **РЎР»РµРґСѓСЋС‰РёР№ С€Р°Рі** | **`go` B1.14-4** cart |
| **РђРіРµРЅС‚** | **СЃС‚РѕРї** вЂ” deploy РІР»Р°РґРµР»СЊС†Р° |

РўР—: [`B1_14_shop_tenant_address_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_14_shop_tenant_address_header.md)

### B1.13 вЂ” РЅРѕРІР°СЏ РЅР°РІРёРіР°С†РёСЏ РІРёС‚СЂРёРЅС‹ (СЌРїРёРє S1вЂ“S4 + rev2)

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| **rev1** | S1 MCP `[x]` В· S2 MCP 9/9 `[x]` В· S3 РєРѕРґ `[x]` |
| **rev2 docs** | 4 С‚РµРєСЃС‚Р° РґРѕСЃР»РѕРІРЅРѕ: **S1-R1, S2a, S2b, S3-rev2** `[x]` 2026-06-25 |
| **S3-rev2** | РєРѕРґ `[x]` В· **Fly MCP 12/12** post-redeploy 2026-06-26 (bump-queue РЅР° СЃС‚РµРЅРґРµ) |
| **Q-rev1** | 2 РІРєР»Р°РґРєРё + РїСЂРѕС„РёР»СЊ РІ С€Р°РїРєРµ вЂ” **Р—РђРљР Р«РўРћ** |
| **Q-rev5** | minus @1 disabled вЂ” **Р—РђРљР Р«РўРћ** (S3-rev2) |
| **Q-rev2** | РїСѓСЃС‚Р°СЏ РєРѕСЂР·РёРЅР° вЂ” **РћРўРљР Р«РўРћ** |
| **Q-rev3,4** | **Р—РђРљР Р«РўРћ** 2026-06-26 |
| **S2b РїСЂРѕРіРѕРЅ 1** | СЃРєСЂРѕР»Р» 100/200 px вЂ” **РєРѕРґ `[x]`** |
| **S2b РїСЂРѕРіРѕРЅ 2** | localStorage СЂРµР¶РёРјР° вЂ” **РєРѕРґ `[x]`** |
| **S2a РїСЂРѕРіРѕРЅ 3** | РїСЂРёС‘РјРєР° СЃ С‚РѕРІР°СЂРѕРј вЂ” **РєРѕРґ `[x]`** |
| **B1.13 rev2** | S1-R1 + S2a/S2b/S3-rev2 · prog20 · MCP 22/22 | **`[x]` ЗАКРЫТ** апрув 2026-07-01 |
| **S4-b1/b2/b3** | tapToProduct · editMode · scrollDots · 114 runs PASS | **`[x]`** |
| **S4 MCP browser** | 12/12 checks PASS · Fly deployed 2a34ada · 2026-07-02 | **`[x]`** |
| **РђРіРµРЅС‚** | **СЃС‚РѕРї** |

РўР—: [`B1_13_shop_nav_profile_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md)

### B1.13 rev1-S3 (Р°СЂС…РёРІ)

РљРѕРґ `6fcc9d8` вЂ” РїСЂРёС‘РјРєР° РїРµСЂРµРЅРµСЃРµРЅР° РІ В§ **S3-rev2** РІ [`B1_13`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md).



### B1.11 вЂ” СЂРµР¶РёРј СЂР°Р±РѕС‚С‹ С‚РѕС‡РєРё

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| РўР— СЌС‚Р°Рї 0 | `[x]` 2026-06-18 |
| РћС‚РІРµС‚С‹ Q1вЂ“Q10 + СЂР°СѓРЅРґ 2 | `[x]` 2026-06-19 В· [`b111_customer_answers_round2_2026-06-19.json`](../milestones/veha_2/artifacts/demo-feedback/b111_customer_answers_round2_2026-06-19.json) |
| **РЎС‚Р°С‚СѓСЃ** | **+ С€Р°РїРєР° РІРёС‚СЂРёРЅС‹** `schedule_display` В· demo A/B СЂР°Р·РЅРѕРµ СЂР°СЃРїРёСЃР°РЅРёРµ В· С‚РµСЃС‚С‹ 13/13 С€Р°РіР° |
| **Fly MCP** | `[x]` header A/B 2026-06-21 вЂ” [`b111_header_schedule_post_deploy_2026-06-21.json`](../milestones/veha_2/artifacts/demo-feedback/b111_header_schedule_post_deploy_2026-06-21.json) |
| **РЎР»РµРґСѓСЋС‰РёР№ С€Р°Рі** | **Р°РїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР°** В· В«РѕРєВ» РёР»Рё РїСЂР°РІРєРё |
| **РђРіРµРЅС‚** | **СЃС‚РѕРї** |

РўР—: [`B1_11_tenant_operating_hours.md`](../milestones/veha_2/requirements/customer_tasks/B1_11_tenant_operating_hours.md)

### B1.10 вЂ” СѓР±СЂР°С‚СЊ В«Р‘Р»РѕРіВ»

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| В«Р‘Р»РѕРіВ» СѓР±СЂР°РЅ РёР· С€Р°РїРєРё | `[x]` |
| РђРїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР° | `[x]` 2026-06-18 вЂ” [`b110_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b110_customer_approval_2026-06-18.json) |

РўР—: [`B1_10_remove_blog_nav.md`](../milestones/veha_2/requirements/customer_tasks/B1_10_remove_blog_nav.md)

### B1.7 вЂ” checkout (РІ С‚.С‡. BR-5)

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| BR-5 РІС‚РѕСЂРѕР№ С‚РѕРІР°СЂ РІ РєРѕСЂР·РёРЅСѓ | **Р·Р°РєСЂС‹С‚** В· Р°РїСЂСѓРІ `[x]` 2026-06-18 вЂ” [`b17_br5_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b17_br5_customer_approval_2026-06-18.json) |
| BR-6 РѕС‚РјРµРЅР° РЅР° `#/payment` | **Р·Р°РєСЂС‹С‚** В· Р°РїСЂСѓРІ `[x]` 2026-06-18 вЂ” [`b17_br6_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b17_br6_customer_approval_2026-06-18.json) |
| B1.9 toggle-РјРѕРґРёС„РёРєР°С‚РѕСЂС‹ | **Р·Р°РєСЂС‹С‚Р°** В· Р°РїСЂСѓРІ `[x]` 2026-06-18 вЂ” [`b19_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b19_customer_approval_2026-06-18.json) В· CC-2 РІ backlog |
| B1.7 С†РµР»РёРєРѕРј | **Р·Р°РєСЂС‹С‚Р°** В· Р°РїСЂСѓРІ `[x]` 2026-06-04 |

РўР—: [`B1_7_checkout_order_screen.md`](../milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md)

### B2.1 вЂ” С‚Р°Р±Р»Рѕ Р±Р°СЂРёСЃС‚Р°

| Р§С‚Рѕ | РЎС‚Р°С‚СѓСЃ |
|-----|--------|
| MVP СЌС‚Р°РїС‹ 0вЂ“5 + СЂРµРІРёР·РёСЏ R0вЂ“R4 | `[x]` OPS_PASS |
| РђРїСЂСѓРІ Р·Р°РєР°Р·С‡РёРєР° | `[x]` 2026-06-18 вЂ” [`b21_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b21_customer_approval_2026-06-18.json) |
| Backlog С„Р°Р·Р° 2 | CBR В«Р‘Р»РѕРє 2 вЂ” backlogВ» (Р±СЂР°Рє, defect_reasons, Р·РІСѓРє РѕС‚РјРµРЅС‹, СЃРїРёСЃР°РЅРёРµ, prep_kitchen, СЌСЃРєР°Р»Р°С†РёСЏ) |
| **РЎР»РµРґСѓСЋС‰РёР№ С€Р°Рі** | **B2.2** СЌС‚Р°Рї 1 |

РўР—: [`B2_1_barista_order_board.md`](../milestones/veha_2/requirements/customer_tasks/B2_1_barista_order_board.md)

### B1.1 вЂ” СЌРєСЂР°РЅ СЃС‚Р°С‚СѓСЃР° Р·Р°РєР°Р·Р°

| Р­С‚Р°Рї | РЎС‚Р°С‚СѓСЃ |
|------|--------|
| 0 РњР°РїРїРёРЅРі + РјР°РєРµС‚С‹ | `[x]` вЂ” [`b11_stage0_mapping_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage0_mapping_2026-06-09.json) |
| 1 РЎС‚Р°С‚РёС‡РµСЃРєРёР№ UI `/order/:id` | `[x]` вЂ” [`b11_stage1_static_ui_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage1_static_ui_2026-06-09.json) |
| 2 WebSocket | `[x]` вЂ” [`b11_stage2_websocket_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage2_websocket_2026-06-09.json) |
| 3 РћС‚РјРµРЅР° | `[x]` вЂ” [`b11_stage3_cancel_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage3_cancel_2026-06-09.json) |
| 4 РўРµСЃС‚С‹ + MCP | `[x]` вЂ” [`b11_acceptance_2026-06-10.json`](../milestones/veha_2/artifacts/demo-feedback/b11_acceptance_2026-06-10.json) В· **deploy Fly** в†’ РїСЂРѕРіРѕРЅ Р·Р°РєР°Р·С‡РёРєР° |

РўР—: [`B1_1_order_status_progress.md`](../milestones/veha_2/requirements/customer_tasks/B1_1_order_status_progress.md)

### РЎРµСЃСЃРёСЏ 2026-06-08 вЂ” РїСЂР°РІРёР»Р° Cursor (СЃРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅРѕ)

**РљР°СЂС‚Р°:** `docs/operations/RULES_INDEX.md` В· РёРЅРґРµРєСЃ `.cursor/rules/coffeeos-index.mdc`

| Р§С‚Рѕ | Р“РґРµ |
|-----|-----|
| **РљРѕРјРјРёС‚ + ops (РєР°РЅРѕРЅ)** | `workflow/coffeeos-commit-ops.mdc` |
| **Р—Р°РґР°С‡Рё, go, РѕС‚С‡С‘С‚** | `workflow/coffeeos-task-workflow.mdc` |
| Workflow + project | `.cursor/rules/workflow/`, `.cursor/rules/project/` |
| Symlinks | `.cursor/rules/coffeeos-*.mdc` в†’ `project/` (СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚СЊ) |

**РљРѕРјРјРёС‚:** РІСЃРµРіРґР° РїРѕСЃР»Рµ С€Р°РіР° СЃ РїСЂР°РІРєР°РјРё, **РґРѕ РѕС‚С‡С‘С‚Р°**, Р±РµР· РІРѕРїСЂРѕСЃР°. **Push:** С‚РѕР»СЊРєРѕ РїРѕ СЏРІРЅРѕР№ РїСЂРѕСЃСЊР±Рµ. **РћС‚С‡С‘С‚:** С‚Р°Р±Р»РёС†Р° РЎРґРµР»Р°РЅРѕ | РќРµ СЃРґРµР»Р°РЅРѕ + `РљРѕРјРјРёС‚: <С…РµС€>`. **Scratch:** `scripts/scratch/`.

### РЎС‚Р°С‚СѓСЃ РІРµС… (РІР°Р¶РЅРѕ РґР»СЏ Р°РіРµРЅС‚Р°)

| Р’РµС…Р° | РћС„РёС†РёР°Р»СЊРЅРѕ | РџРѕ С„Р°РєС‚Сѓ |
|------|------------|----------|
| **Р’РµС…Р° 1** | **РќРµ Р·Р°РєСЂС‹С‚Р°** вЂ” РЅРµС‚ В§ I, H.3 Р¶РёРІРѕРіРѕ РґРµРјРѕ, РґР°С‚С‹/РїРѕРґРїРёСЃРё РІ С‡РµРєР»РёСЃС‚Рµ | РљРѕРґ AвЂ“G РЅР° `develop`, С‚РµСЃС‚С‹ Р·РµР»С‘РЅС‹Рµ, РґРµРїР»РѕР№ Fly РїРѕСЃР»Рµ v1.53 |
| **Р’РµС…Р° 2** | **РЎС‚Р°СЂС‚ СЂР°Р±РѕС‚** вЂ” РѕСЃРЅРѕРІРЅРѕР№ С„РѕРєСѓСЃ РЅРѕРІРѕРіРѕ РѕРєРЅР°/Р°РіРµРЅС‚Р° | Roadmap В§ В«Scale & StabilityВ» |

**Р РµР¶РёРј:** СЂР°Р·СЂР°Р±РѕС‚РєР° **Р’2 РёРґС‘С‚ РїР°СЂР°Р»Р»РµР»СЊРЅРѕ**. Р—Р°РєСЂС‹С‚РёРµ Р’1 вЂ” **Р·Р°РѕС‡РЅРѕ**, РєРѕРіРґР° РІР»Р°РґРµР»РµС† РїСЂРѕР№РґС‘С‚ H.3 Рё РєС‚Рѕ-С‚Рѕ РѕС‚РјРµС‚РёС‚ В§ I РІ `milestones/veha_1/checklists/CHECKLIST.md`. **РќРµ РїРёСЃР°С‚СЊ** РІ ops В«Р’РµС…Р° 1 Р·Р°РєСЂС‹С‚Р°В», РїРѕРєР° В§ I РЅРµ `[x]`.

---

## Р§С‚Рѕ СЃРґРµР»Р°РЅРѕ РІ СЌС‚РѕР№ СЃРµСЃСЃРёРё (РѕРїРµСЂР°С†РёРѕРЅРєР° + РєРѕРґ)

### РљРѕРґ (СѓР¶Рµ РЅР° `develop`)

| РћР±Р»Р°СЃС‚СЊ | Р§С‚Рѕ |
|---------|-----|
| **A** | Service Objects: `OrderCancellationService`, `OrderStatusUpdateService`, `PaymentStatusUpdater`, `MovementCreator` fix, СЂРµС„Р°РєС‚РѕСЂ РєРѕРЅС‚СЂРѕР»Р»РµСЂРѕРІ |
| **B** | MVP-РјРѕРґРµР»Рё, `Demo::EnvironmentSetup`, `demo:seed`, shop API, RLS-С‚РµСЃС‚С‹, РѕРЅР±РѕСЂРґРёРЅРі РЈРљ |
| **C** | RBAC integration-С‚РµСЃС‚С‹ РІСЃРµС… 7 СЂРѕР»РµР№ РїР°РЅРµР»РµР№ |
| **D** | MCP-РѕР±С…РѕРґ РїР°РЅРµР»РµР№ (Р¶СѓСЂРЅР°Р» РІ `PRACTICES.md` В§ Block D) |
| **E** | Svelte `/shop`: РєР°С‚Р°Р»РѕРі, РєРѕСЂР·РёРЅР°, РјРѕРґРёС„РёРєР°С‚РѕСЂС‹, mock-РѕРїР»Р°С‚Р°, РёСЃС‚РѕСЂРёСЏ |
| **F** | `Inventory::OrderRecipeDeduction`, РјРёРіСЂР°С†РёСЏ block F, prep_kitchen movements |
| **G** | Р“РёР±СЂРёРґ СЃРјРµРЅС‹: shop Р±РµР· СЃРјРµРЅС‹, barista С‚РѕР»СЊРєРѕ СЃ open shift; РѕС‚РјРµРЅР° СЃ reason + audit |
| **РРЅС„СЂР°** | `bin/ensure-server`, `lib/port_killer.rb`, `lib/dev_server.rb` |
| **РўРµСЃС‚С‹** | **479 runs, 0 failures** (2026-05-25) |
| **Review** | N+1 РІ `app/services/shop/order_creator.rb` вЂ” preload products |
| **Р”РµРїР»РѕР№** | РЈР±СЂР°РЅС‹ win32 npm bindings РёР· `package.json`; `Dockerfile`: `npm ci` (РєРѕРјРјРёС‚ `4a25187`) |

### Git (РїСѓС€Рё РЅР° develop)

1. **15 РєРѕРјРјРёС‚РѕРІ** вЂ” РїРѕР»РЅС‹Р№ РѕР±СЉС‘Рј Р’1 (db, services, frontend shop, tests, product docs, ops milestones РІ git, agents).
2. **1 РєРѕРјРјРёС‚** вЂ” fix Fly build (`fix(deploy): remove Windows-only npm bindingsвЂ¦`).

Р”РµРїР»РѕР№: `.github/workflows/deploy.yml` в†’ `flyctl deploy` РїСЂРё push РІ `develop`. РќРµ Р¶РґР°С‚СЊ Р°РІС‚РѕРґРµРїР»РѕР№ РѕС‚ РѕРґРЅРѕРіРѕ git Р±РµР· CI.

### Р”РѕРєСѓРјРµРЅС‚Р°С†РёСЏ РѕРїРµСЂР°С†РёРѕРЅРЅР°СЏ

| Р¤Р°Р№Р» | РЎС‚Р°С‚СѓСЃ |
|------|--------|
| `milestones/veha_1/checklists/CHECKLIST.md` | AвЂ“G, H.2 вЂ” `[x]`; H.3 РґРµРјРѕ вЂ” `[ ]`; В§ I вЂ” `[ ]` |
| `milestones/veha_1/reference/PRACTICES.md` | Р–СѓСЂРЅР°Р» Р±Р»РѕРєРѕРІ, С‚РµС…РґРѕР»Рі Р’1, QA H.2, code review |
| `milestones/veha_1/qa/QA_ACCEPTANCE_RUN.md` | РџСЂРѕС‚РѕРєРѕР» СЃСѓС…РѕР№ + MCP |
| `milestones/veha_1/qa/CODE_REVIEW.md` | CR-1 РёСЃРїСЂР°РІР»РµРЅ |
| `milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md` | Р“РёР±СЂРёРґ A/B, СЂРµРµСЃС‚СЂ 8 РІС…РѕРґРѕРІ |
| `milestones/veha_1/reference/DEMO_LOGINS.md` | 9 РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№, РїР°СЂРѕР»СЊ `demo123456` |
| `milestones/veha_1/qa/LIVE_DEMO_SCENARIOS.md` | РўРµС…РЅРёС‡РµСЃРєРёРµ СЂСѓС‡РЅС‹Рµ СЃС†РµРЅР°СЂРёРё (**С„Р°Р№Р» РµСЃС‚СЊ Р»РѕРєР°Р»СЊРЅРѕ, РІ git РјРѕР¶РµС‚ РЅРµ Р±С‹С‚СЊ**) |
| `milestones/veha_1/qa/LIVE_DEMO_SCENARIOS_PLAIN.md` | РџСЂРѕСЃС‚РѕР№ СЏР·С‹Рє РґР»СЏ Р·Р°РєР°Р·С‡РёРєР° + URL РІРёС‚СЂРёРЅ (**С‚Рѕ Р¶Рµ**) |
| `docs/operations/journal/CHANGELOG.md` | v1.50вЂ“v1.54 |
| `docs/operations/session/SESSION_STATE.md` | РћР±РЅРѕРІР»С‘РЅ РїРѕРґ handoff |
| `.gitignore` | Р Р°Р·СЂРµС€С‘РЅ `docs/operations/milestones/**/*.md` |

### РџСЂРѕРґСѓРєС‚РѕРІС‹Рµ РґРѕРєРё (СЃРёРЅС…СЂРѕРЅ СЃ Р’1)

`01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`, `ARCHITECTURE.md`, `development_roadmap.md` вЂ” **РєРѕРґ Р’1** РІ roadmap В«СЂРµР°Р»РёР·РѕРІР°РЅВ»; **ops-Р·Р°РєСЂС‹С‚РёРµ Р’1** вЂ” РѕС‚РґРµР»СЊРЅРѕ, СЃРј. С‡РµРєР»РёСЃС‚ В§ I.

---

## Р§С‚Рѕ **РЅРµ** Р·Р°РєСЂС‹С‚Рѕ (РѕСЃС‚Р°С‚РѕРє Р’1)

1. **H.3** вЂ” Р¶РёРІРѕРµ РґРµРјРѕ Р·Р°РєР°Р·С‡РёРєРѕРј РїРѕ `LIVE_DEMO_SCENARIOS_PLAIN.md` (РјРёРЅРёРјСѓРј 4 РёСЃС‚РѕСЂРёРё В§ 10).
2. **В§ I** С‡РµРєР»РёСЃС‚Р° вЂ” `SESSION_STATE` В«Р’РµС…Р° 1 Р·Р°РєСЂС‹С‚Р°В», Р·Р°РїРёСЃСЊ РІ CHANGELOG Рѕ Р·Р°РєСЂС‹С‚РёРё, С„РёРЅР°Р»СЊРЅС‹Р№ СЃРїРёСЃРѕРє С…РІРѕСЃС‚РѕРІ РІ `PRACTICES.md`.
3. **РљРѕРјРјРёС‚** С„Р°Р№Р»РѕРІ `LIVE_DEMO_SCENARIOS*.md` + Р°РєС‚СѓР°Р»СЊРЅС‹Р№ `CHECKLIST`/`README` РµСЃР»Рё РµС‰С‘ РЅРµ РІ СЂРµРїРѕР·РёС‚РѕСЂРёРё.
4. Р§РµРєР»РёСЃС‚ **B** Рї. QA 5.1 (РѕС‚РєР°С‚ РѕРЅР±РѕСЂРґРёРЅРіР° РїСЂРё РѕС€РёР±РєРµ) вЂ” `[ ]`, СЂСѓС‡РЅРѕР№ РЅРµРіР°С‚РёРІРЅС‹Р№ С‚РµСЃС‚.

---

## Р”Р»СЏ Р°РіРµРЅС‚Р° Р’РµС…Рё 2 вЂ” СЃ С‡РµРіРѕ РЅР°С‡Р°С‚СЊ

**Р¤РѕРєСѓСЃ:** Р’2. Р’1 РЅРµ РґРѕРґРµР»С‹РІР°С‚СЊ РІ СЌС‚РѕРј РѕРєРЅРµ, РєСЂРѕРјРµ СЏРІРЅРѕР№ РїСЂРѕСЃСЊР±С‹ (РґРµРјРѕ H.3, В§ I).

1. РџСЂРѕС‡РёС‚Р°С‚СЊ **`docs/product/development_roadmap.md`** В§ В«Р’Р•РҐРђ 2 (Scale & Stability)В».
2. РЎРѕР·РґР°С‚СЊ/РЅР°РїРѕР»РЅРёС‚СЊ **`docs/operations/milestones/veha_2/`** (СЃРµР№С‡Р°СЃ С‚РѕР»СЊРєРѕ `README.md`-Р·Р°РіРѕС‚РѕРІРєР°).
3. **РќРµ Р»РѕРјР°С‚СЊ** РіРёР±СЂРёРґ СЃРјРµРЅС‹ Р’1 Р±РµР· СЏРІРЅРѕРіРѕ РїСЂРѕРґСѓРєС‚Р° вЂ” РІ Р’2 РїР»Р°РЅРёСЂСѓРµС‚СЃСЏ СѓР¶РµСЃС‚РѕС‡РµРЅРёРµ (РµРґРёРЅР°СЏ СЃРјРµРЅР° РЅР° РІСЃРµС… РєР°РЅР°Р»Р°С…), СЃРј. `ORDER_ENTRY_AUDIT.md`.
4. РўРµС…РґРѕР»Рі Р’1 вЂ” С‚РѕР»СЊРєРѕ РІ **`milestones/veha_1/reference/PRACTICES.md`** В§ В«РўРµС…РґРѕР»Рі Р’1В», РЅРµ СЂР°Р·РјР°Р·С‹РІР°С‚СЊ РїРѕ Vision/Architecture.
5. РџСЂР°РІРёР»Р° РєРѕРґР°: `.cursor/rules/project/coffeeos-core.mdc`, `coffeeos-performance.mdc`, `coffeeos-services.mdc`; РєР°СЂС‚Р° вЂ” `RULES_INDEX.md`.

### РџСЂРёРѕСЂРёС‚РµС‚С‹ Р’2 (РёР· roadmap, РЅРµ РЅР°С‡Р°С‚Рѕ)

- Р РµР°Р»СЊРЅР°СЏ РѕРїР»Р°С‚Р° (`SHOP_SIMULATE_PAYMENT=0`, С€Р»СЋР·, callbacks).
- Offline-first / sync РґР»СЏ POS.
- Flutter + РєРёРѕСЃРє (Р·Р°РєР°Р·С‹ Р±РµР· СЃРјРµРЅС‹ РєР°Рє shop).
- Outbox (Solid Queue), Circuit Breaker (РєРѕРЅРµС† Р’2).
- Р Р°СЃС€РёСЂРµРЅРёРµ РєР°СЃСЃРѕРІРѕР№ РґРёСЃС†РёРїР»РёРЅС‹ РЅР° СЃРµС‚СЊ С‚РѕС‡РµРє.

### Р”РµРјРѕ-СЃС‚РµРЅРґ (develop в†’ Fly)

**URL РІРёС‚СЂРёРЅС‹:** РґРІР° СЂРµР¶РёРјР° вЂ” [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md). РЎРµР№С‡Р°СЃ **СЂРµР¶РёРј B** (Fly): `?tenant_id=`. **Р РµР¶РёРј A** (РїСЂРѕРґ): `{slug}.shop.РґРѕРјРµРЅ` РїРѕСЃР»Рµ СЃРІРѕРµРіРѕ DNS/TLS.

**РџРѕСЃР»Рµ РґРµРїР»РѕСЏ** (H.3): `fly.toml` вЂ” `demo:seed` РІ release; **Р±РµР·** `SHOP_BASE_DOMAIN`.  
`fly ssh console -a coffeeos -C 'bin/rails demo:shop_urls'` вЂ” URL С‚РѕС‡РµРє A/B.

- РРЅСЃС‚СЂСѓРєС†РёСЏ: `FLY_DEMO_STAND.md`, С‡РµРєР»РёСЃС‚ В§ H.0 `veha_1/checklists/CHECKLIST.md`
- Р›РѕРіРёРЅС‹: `milestones/veha_1/reference/DEMO_LOGINS.md` (`demo123456`)
- **РџРµСЂРµРґР°С‚СЊ Р·Р°РєР°Р·С‡РёРєСѓ:** [`../demo/CUSTOMER_HANDOFF.md`](../demo/CUSTOMER_HANDOFF.md) + `LIVE_DEMO_SCENARIOS_PLAIN.md`
- РЎРІРѕР№ РґРѕРјРµРЅ: `veha_2/checklists/CHECKLIST.md` В§ **A-inf**

---

## Р‘Р»РѕРєРµСЂС‹

РќРµС‚ РґР»СЏ СЃС‚Р°СЂС‚Р° Р’2. Р”РµРїР»РѕР№ Fly РїРѕСЃР»Рµ v1.53 РґРѕР»Р¶РµРЅ СЃРѕР±РёСЂР°С‚СЊСЃСЏ; РїСЂРё РїР°РґРµРЅРёРё вЂ” СЃРјРѕС‚СЂРµС‚СЊ GitHub Actions в†’ Build Image в†’ `npm ci`.

---

## РћС‚РєСЂС‹С‚С‹Рµ РІРѕРїСЂРѕСЃС‹ (РЅР° РїСЂРѕРґСѓРєС‚/РІР»Р°РґРµР»СЊС†Р°)

- РџРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ Р¶РёРІРѕРіРѕ РґРµРјРѕ H.3 Рё РґР°С‚Р° Р·Р°РєСЂС‹С‚РёСЏ Р’1.
- РџСЂРёРѕСЂРёС‚РµС‚ РІРЅСѓС‚СЂРё Р’2: РѕРїР»Р°С‚Р° vs offline vs Flutter.

---

**РџСЂРµРґС‹РґСѓС‰РёР№ РєРѕРЅС‚РµРєСЃС‚ (schema):** Р±Р°С‚С‡Рё B1вЂ“B5, `GAP_LIST_CORE_SCHEMA.md` вЂ” done; РЅРµ СЃРјРµС€РёРІР°С‚СЊ СЃ С‡РµРєР»РёСЃС‚РѕРј Р’1 Р±РµР· РЅРµРѕР±С…РѕРґРёРјРѕСЃС‚Рё.

