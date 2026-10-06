# CHANGELOG

## Шапка

**Текущий месяц:** `2026-09`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md` … `CHANGELOG-2026-08.md` · **`CHANGELOG-2026-09-early.md`** (01–17, ctx-trim 2026-09-22)

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца. Ранний сентябрь — `archive/CHANGELOG-2026-09-early.md`.

---

## Текущий месяц (2026-09)

## 2026-10-06 — feat: УК «Code Black» — организации → точки, рабочие модули, команда и ТВ из УК

- **Модель:** УК = компания «Code Black» (платформа, `/admin`) → организации (франчайзи) → точки. Т-Банк — один терминал на все точки (решение владельца, без изменений).
- **УК видит всё:** `UkCatalogScope` — все организации (в т.ч. без точек) и все точки (продажи, цеха, неактивные); колонки «Тип»/«Статус»; кнопки «Новая» всегда; `DEMO_SINGLE_POINT = "false"` в `fly.toml`; бренд «Code Black — УК».
- **Модули работают:** `TenantModuleFlags.enabled?` (нет записи = вкл.) · ТВ-борд выкл → `/tv_board` 403 «TV-борд отключён», рассылка на открытые ТВ не идёт, ТВ не создать, пункт «TV» скрыт · Меню выкл → `/manager/menu` недоступно, пункт скрыт · QR/офферы выкл → оффер абонемента (баннер/push/ЛК, eligibility) скрыт, воронка `/manager/subscription_offer_funnel` 403 · киоск/витрина без изменений.
- **Владелец франшизы** = `franchise_manager` на уровне организации (`user_roles.tenant_id` NULL, `users.tenant_id` NULL) — все текущие и будущие точки; создаётся и до первой точки. `UserRole` пропускает tenant-guard для `ук_global_admin`/`franchise_manager`, `User` — tenant опционален.
- **Команда из УК:** карточка точки → «Создать команду» (`Platform::TenantTeamProvision`): реальные аккаунты (менеджер/бариста/менеджер смены; у цеха — менеджер/работник цеха), пароли генерируются и показываются один раз; всё-или-ничего.
- **ТВ из УК:** карточка точки → блок «ТВ-табло»: создать (ссылка `/tv_board?token=…`), отключить.
- **SBR:** RED `de09a920` → GREEN `417d1bbf` · REVIEW: bugbot 1 (владелец с `tenant_id` первой точки удалялся бы чисткой) + security 2 medium (список ТВ без tenant-RLS, рассылка ТВ при выкл. модуле) → RED `d0fa90e8` → GREEN `aa71cb64` · crit-audit CLEAN · тесты: новые 28/0, зона 895 + 223/0, RuboCop 0.
- **Прод-уборка 2026-10-06 08:38 UTC** (PITR `2026-10-06T08:38:57Z`): организация точки `napi_x_codeBlack`/`demo-coffeeos` → «Тестовая франшиза»/`test-franchise`; точка `code_black` → «Витрина А» (slug и id те же); у `razmikg1988@gmail.com` снята пустая организация (УК над организациями); удалены 7 пустых тест-организаций и 4 киоска (`Smoke QA6`, `Smoke QA6b`, `Prog10 Kiosk MCP`, `зал`); ТВ «зал» оставлен · `/`, `/up`, `/login`, `/shop/api/categories` 200.
- Код не задеплоен — deploy по апруву.

## 2026-10-06 — ops: одна боевая точка `code_black` (`platform:prod_single_point_reset`)

- **Код:** `Platform::ProdSinglePointReset` + rake `platform:prod_single_point_reset` (`OWNER_EMAIL` обязателен, `PROTECT_PHONES`, DRY_RUN=1 по умолчанию) · общий `Platform::ProdPurge` (удаление точек/юзеров/зависимостей заказов/гостей) — `ProdDataCleanup` переведён на него · роль УК владельцу — `insert_all` (в проде `ensure_tenant_id` не даёт create глобальной роли без тенанта) · тест `prod_single_point_reset_test` + `prod_data_cleanup_test` 4/0.
- **APPLY 2026-10-06 07:19 UTC** (апрув; откат — Neon PITR `2026-10-06T07:19:32Z`), verification PASS: на `code_black` один пользователь — `razmikg1988@gmail.com` (`ук_global_admin` + `franchise_manager`) · удалены 16 демо/тест-сотрудников (`barista-a`, `gm-a`, `shift-a`, `franchise`, `uk@demo`, `@prog10.local`) · 15 демо-смен удалены, открытых 0 · `demo-point-b` и `test-cafe` удалены (+22 юзера); цех `demo-prep-kitchen` не тронут · 20 тест-гостей удалены · ключ `mcp-v500-retry` отозван (активных 0).
- **Удалённые успешные оплаты Т-Банка (Demo B, для сверки):** `#202606-0055` 1.79 ₽ PaymentId `8638798951` · `#202606-0056` 3.35 ₽ PaymentId `8638801971`. Платежи `code_black` — 212 = 212.
- `cancel_reason` у `#202606-0291` исправлен на «Ops cleanup: оплата не прошла» (кракозябры из-за кодировки stdin).
- **Проверка после:** точки 2 · юзеров 11 (10 — цех) · платежи tbank 35 succeeded / 143 failed / 40 refunded · Арам 138 заказов (18 issued) · меню 22 · гостей 283 · открытых заказов на табло 0 · `/`, `/up`, `/login` 200 · Sentry unresolved 1h — 0.

## 2026-10-06 — ops: чистка прода от демо/мок-данных (`platform:prod_data_cleanup`, dry-run)

- **Аудит (read-only):** Sentry 7d — 0 unresolved; stuck tbank — 0; смена `code_black` открыта с 21.06 (demo `barista-a`) → на табло 2 теста по 10 ₽, на ТВ «Готово» старые тестовые `ready`; 13 брошенных оформлений `shop`; 143 заказа с имитацией оплаты; 17 тест-точек; ~190 тест-гостей; тест-бариста и `mcp-*` ключи на боевой точке; товары `W12-*`.
- **Код:** `Platform::ProdDataCleanup` + rake `platform:prod_data_cleanup` (DRY_RUN=1 по умолчанию: те же шаги в транзакции + ROLLBACK). Неприкосновенно: платежи с `provider_payment_id` и их заказы, точки с успешными/возвращёнными оплатами, точки с УК-ролями, цех боевой точки, гости с банковскими заказами/картами; текущий месяц заказов (номер = MAX+1).
- **Prod dry-run PASS:** board → issued 17 / cancelled 1 · удалить 17 точек (+52 юзера), 330 заказов без банка, 144 гостя · блок 27 тест-бариста · отзыв 15 ключей · W12 ×3 off · банк-платежи 212 = 212.
- Тест `prod_data_cleanup_test` 2/0.
- **APPLY 2026-10-06 07:04 UTC** (апрув владельца; откат — Neon PITR `2026-10-06T07:04:43Z`): цифры как в dry-run, verification PASS. После: 4 точки, на табло `code_black` 0 заказов, платежи только `tbank` (37 succeeded / 182 failed / 40 refunded), меню 22 позиции, гостей 303, `/up` и `/login` 200, Sentry 1h — 0.

## 2026-10-06 — fix: Quick Repeat Патч 1 — «повторить» не всплывает после оплаты из-за гонки кэша

- **Баг:** `PaymentStatusUpdater` удалял кэш `shop/freq/v3` внутри транзакции оплаты (до COMMIT); параллельный `GET /frequent_products` успевал записать `has_active_order=false` → «повторить» видна при активном заказе до 30 мин.
- **Фикс:** `CustomerFrequentProductsService.mark_order_active_after_commit!` — запись `{ has_active_order: true, frequent_items: [] }` через `ActiveRecord.after_all_transactions_commit` (без SQL — после COMMIT RLS-тенант снят; заказ старше 24 ч → обычный bust) · `cached_payload` на cache miss пишет с `unless_exist: true` — поздний GET не перетирает.
- Не менялись: окно 45 дней, статусы, TTL, ключ v3, `/orders/active`, frontend.
- Коммиты: intake `2aee74a1` · RED `6e4c2537` (2 fail) · GREEN `394ff4f8` · Local Quick Repeat 43/0 · зона 1410 (1 флак → ISSUES) · RuboCop 0.

## 2026-10-05 — fix: просроченные платежи Т-Банка больше не висят в pending (Fly v510)

- 4 тестовых СБП-платежа по 11 ₽ с сентября висели `pending`: Т-Банк возвращал `DEADLINE_EXPIRED`, наш маппинг статусов его не знал → джоб зависших платежей каждые 15 минут гонял их заново (источник N+1 в Sentry и алертов).
- RED `05c83aef` → GREEN `b58fe367`: `DEADLINE_EXPIRED` и `AUTH_FAIL` → `failed` (как `REJECTED`). Регрессия оплаты 216/0, CI green, v510.
- Прод: 4 платежа `failed`, заказы `cancelled`, зависших 0.

## 2026-10-05 — fix: RUBY-1P — алерты о зависших платежах ставятся в очередь одной вставкой (Fly v509)

- Sentry MCP подключён; за 24 ч один issue — N+1 `INSERT INTO solid_queue_jobs` в `StuckPaymentsCheckJob` (алерт на каждый платёж отдельно).
- RED `93f01b59` → GREEN `b784c934`: `ActiveJob.perform_all_later` после цикла · payments 182/0 · CI green · v509 · на проде 1 пакетная вставка на 4 алерта · RUBY-1P resolved, Sentry 24h = 0.
- Живые проверки на проде: TASK_101 «Итого», TASK_100 (тексты 1051/119 без списания), TASK_94 (реальная оплата 10 ₽ → статус + табло) — PASS. Push на Android — нужен телефон.
- Найдено: на Fly нет `TELEGRAM_CHAT_ID` → Telegram-алерты не отправляются (ISSUES).

## 2026-10-05 — ops: Fly v508 — деплой 9 патчей + приёмка на проде

- В прод ушли TASK_100, TASK_101, TASK_86 Патч 1, TASK_90 Патч 1, TASK_37 Патч 1, #71 Патч_2, ЛК Патч 3, TASK_94 Патч 1, TASK_102 (#75 Патч 1) — `47be43cc..c878c8bf`, 2 миграции.
- До деплоя: CI/Semgrep/CodeQL green на `c878c8bf` · JS 690 (60 legacy) · сводный crit-audit CLEAN.
- После: миграции применены, backfill промо 4 записи, dry_run 0 · SW Firebase регистрируется · шапка без поддержки · экран ожидания СБП сам уходит в «не завершена» · табло barista-a работает · 5xx нет · Sentry не проверен (MCP недоступен). Артефакт: `artifacts/mcp/fly_v508_2026-10-05/MCP_RESULT.md`.

## 2026-10-05 — feat: TASK_102 (#75 Патч 1) — промо 11 ₽ не повторяется при уже сохранённом способе оплаты

- Аудит: право на промо считалось только по growth-записям `card_binding_attempts`; карты/СБП, сохранённые до #75 или без промо, записей не имели → `growth_promo.eligible = true`.
- **RED** `ea28c9fb` → **GREEN** `eb2d3d1d`: колонка `card_binding_attempts.source`; миграция запускает `Payments::GrowthLedgerBackfill` (все card/sbp, вкл. неактивные → `is_growth_event`, `backfill_pre_promo`, `point_id = NULL`); `GrowthPromo.cover_saved_method!` пишет `saved_without_promo` после `consume_from_payment!` в `SavedCardStore` и `SbpAccountTokenFromWebhook`; rake `growth_ledger:backfill:{dry_run,apply}`. Логика `eligible?` / `available?` / `price!` не менялась.
- **Local:** целевые 21/0 · payments/shop/subscriptions/models/integration shop/jobs 1489/0 · RuboCop 0. Найдено вне scope: SBP webhook падает на `RATE_LIMITED` → ISSUES.
- **/regress** 1550/0, миграция rollback → migrate OK. **REVIEW:** bugbot 0 · security 2 medium → not-critical (гости без телефона — до патча так же, вопрос владельцу; fail-open журнала — осознанно, чтобы не откатывать сохранение карты в callback) · crit-audit CLEAN.
- `COMPONENT_MAP.md`: +3 строки — `GrowthPromo`, `CardBindingAttempt`, `GrowthLedgerBackfill` (инварианты журнала промо, `point_id = NULL`, порядок `cover_saved_method!`).

## 2026-10-05 — fix: Задача_2 (ЛК в PWA) Патч 3 — в шапке витрины нет иконки поддержки

- Патч 1 (2026-09-17) не был выполнен: кнопка `shop-header-support-chat` в `Header.svelte` стояла вне `{#if narrow}` → видна на всех ширинах. Патч 3 (2026-10-02) из Google Doc вписан в ТЗ ЛК.
- RED `f935fcdd` → GREEN `440a686a`: удалены кнопка, `MessageCircle`, `onSupportChatClick`, импорт и монтирование `SupportContactSheet`. «Профиль ID» без изменений. `SupportContactSheet.svelte` / `Profile.svelte` / `supportConfig.js` не тронуты (запрет ТЗ).
- Тест `shop_header_no_support_chat_test.mjs`: SSR (обычная ширина) + исходник (узкая). /regress: JS 687 — 60 legacy · Rails шапка/ЛК 17/0 · vite OK. Review: bugbot 0 · security 0 · crit-audit CLEAN.

## 2026-10-05 — feat: TASK_94 Патч 1 — ЛК → Повторить: успех на главный экран, отказ на экран оплаты

- **RED** `314bf518` → **GREEN** `c29c14a2`: `historyRepeatAdapter.runHistoryRepeatPayFlow` — CONFIRMED → сброс inline-UI + `push("/")` (статус в существующем `OrderStatusSheet`), reset-таймер не ставится; REJECTED/CANCELED → существующий `openRepeatPaymentSheet` (`#/checkout`, сохранённые карты / новая / СБП); нет карт → форма новой карты; сеть/timeout — inline retry как было.
- **REVIEW:** security 0 · bugbot #1 — ключ `history:*` оставался в общем store → Quick Repeat на `/` показывал чужой fallback → RED `7dbff0c5` → GREEN `6e10a462` · bugbot #2 — то же в окне retry → `releaseHistoryRepeatUi` при уходе с `Profile`/`OrderReceipt` → RED `35b8618f` → GREEN `9bd2d690` · bugbot #3 — только код базовой TASK_94 → backlog · crit-audit CLEAN.
- **Local:** зона 15/0 · JS 688 — 60 legacy · Rails shop+payments 825/0 · vite build OK. Checkout, Quick Repeat, `OrderStatusSheet`, `cartSheetStore`, payment API не тронуты.

## 2026-10-05 — docs: TASK_94 Патч 1 — /patch (ЛК → Повторить: успех на `#/`, отказ на экран оплаты)

- Патч 1 (2026-10-01) из Google Doc вписан 1:1 секцией в TASK-94 + аудит (файл:строка). Тип — ПАТЧ (Subtask 5, 6).
- Факт: после CONFIRMED в ЛК нет перехода на `#/`; при отказе `Profile`/`OrderReceipt` показывают только текст ошибки, fallback (карты/СБП) не открывается.
- Решение для билда: CONFIRMED → `push("/")` как Quick Repeat; REJECTED/CANCELED → существующий `openRepeatPaymentSheet` (`#/checkout`). Код не менялся. Next: `/sbr`.

## 2026-10-05 — fix: #71 Патч_2 — email после оплаты в `receipt_email`, сервер первичен, чек как до Патч_1

- **Intake** `5ebf03b0` — Патч_2 (Google Doc п.6) 1:1 в ТЗ #71. 2-й патч → следующий = переписать ТЗ.
- **Причина регрессии чека:** Патч_1 писал неподтверждённый post-pay email в `MobileCustomer.email` → `TbankReceiptBuilder.for_order!` слал `Receipt.Email` вместо `Phone`; очистка стирала OTP-email.
- **RED** `1123d987` → **GREEN** `ad6b448e`: колонка `mobile_customers.receipt_email` (миграция + перенос неподтверждённых email; у строк без телефона `email` не обнуляем) · `Orders::EmailService` пишет только `receipt_email` · `profile` API отдаёт `receipt_email` · `resolveReceiptEmailPrefill` (сервер → LS → guest profile) в `PaymentResult` · пустой submit чистит LS (`clearReceiptEmail`). `TbankReceiptBuilder` / payment / callcheck / `Checkout.svelte` не тронуты.
- Тесты: новый `orders_email_patch2_test.rb` (receipt Phone, OTP-email цел, изоляция A/B, чужой order → 404, order#1 → profile → order#2) · P1-тесты переписаны под `receipt_email` · JS 6 кейсов приоритета.
- **Local:** зона 39/0 · Rails shop+payments+jobs 1225/0 · JS 677 — 60 legacy · vite build OK · RuboCop 0.
- **REVIEW:** bugbot — `CustomerProfileMerger` терял `receipt_email` донора при слиянии → RED `d0e9d883` → GREEN `20138734` · повторный bugbot 0 · security 0 · crit-audit CLEAN · Entire `01M45YZTD6Z31SD7MP9Q7KS21X`.
- **COMPONENT_MAP:** строка `PaymentResult` — prefill server `receipt_email` → LS → guest, `clearReceiptEmail`, `MobileCustomer.email` не для prefill.

## 2026-10-05 — fix: TASK_86 Патч 1 — WAITING-экран СБП переходит в результат без remount

- Патч 1 (2026-10-02) из Google Doc вписан секцией в TASK-86-EXT.
- `shopSbpPay.js`: `resolveWaitingScreenTransition` — из `waiting` того же `order_id`: `ok/ok_sbp/success` → success, `fail/cancel` → incomplete, иначе ничего.
- `PaymentResult.svelte`: `hashchange` → `applyWaitingTransition` (success — существующий `prepareSuccessScreen` с серверным finalize; incomplete — `clearPendingOrder` + «Оплата не завершена»), повторная сверка hash после reconnect. Backend, TTL, PENDING, polling — без изменений.
- Тест `test/javascript/sbp_waiting_screen_transition_test.mjs`.
- RED `0e85e41d` → GREEN `e553a6a7` · /regress JS 664 (60 legacy) · Rails 814/0 · bugbot/security 0 · crit-audit CLEAN · Entire `01M45JR1SGADBM4RF8EZZDQBZ7` · CI green [37283046314](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37283046314).

## 2026-10-05 — fix: TASK_37 Патч 1 — CSP Service Worker Firebase

- Патч 1 (2026-10-02) из Google Doc вписан секцией в TASK-37.
- `Shop::FirebaseSwController`: локальная `content_security_policy` — глобальный `script-src` + `https://www.gstatic.com` (SW делает `importScripts` Firebase SDK). Глобальная CSP, `connect-src`, `show.js.erb`, `firebasePush.js` не менялись.
- Тест `test/integration/shop/firebase_sw_csp_test.rb` (CSP ответа SW + охрана глобальной CSP).
- RED `46de7f82` → GREEN `9608d9f2` · Rails 24/0 · JS 45/0 · Entire `01M45HNNHAF3YGAFK4X55X00Z4`.
- REVIEW: bugbot — на 304 Rails не отдаёт CSP, браузер держал бы старую политику → RED `19fff712` → GREEN `e91f2daa`: `Cache-Control: no-store` + уникальный weak ETag на ответ SW. Повторный bugbot 0 · security 0 · crit-audit CLEAN.

## 2026-10-05 — feat: TASK_90 Патч 1 — подписка продолжается после возврата из настроек

- Intake Патча 1 (Subtask 7 patch v1) `cba87679` · RED `736d79a9` · GREEN `2f3d39de`
- `resumePushAfterSettings` в `orderStatusNotifyActions.js`; `ActiveOrdersAccordion` слушает `visibilitychange`/`pageshow`, пока показан recovery UI → при `granted` существующий `registerShopPush()` без повторного клика
- `registerShopPush` / backend / SW / FCM не менялись · тест 34/0 · JS зона 183/1 (legacy) · vite build OK
- REVIEW: bugbot 0 · security 0 · crit-audit CLEAN · Entire `01M45J5ZBRMVT395VJPVB9BZNC` · CI green [37283046314](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37283046314) на `3f14dda9`
- `COMPONENT_MAP.md` `9c5bc91b`: `ActiveOrdersAccordion` (номера строк 327–337 / 387–413 + re-entry 212–223), `orderStatusNotifyActions.js` (`resumePushAfterSettings`)

## 2026-10-05 — feat: TASK_101 «Итого» в шторке способов оплаты

- Строка «Итого 3 245 ₽» под заголовком `PaymentMethodsSheet` (над картами / СБП / «Картой +»): серверный `total` корзины (`cartTotalRub`), видна при загрузке и ошибке оплаты, скрыта при 0 / незагруженной сумме; `labelOrderTotal` / `formatRubAmount` (NBSP) в `paymentMethodI18n.js`. Backend/оплата не менялись.
- Решение владельца: «Итого» = сумма корзины и при акции привязки 11 ₽.
- RED `3b752e0a` → GREEN `5fdefa93` · JS 10/0 · Rails `cart_total_amount_test` 3/0 (total = Amount/100) · /regress JS 650 (60 legacy) + Rails 811/0 · bugbot/security 0 · crit-audit CLEAN.
- `COMPONENT_MAP.md`: строка `PaymentMethodsSheet` — связи `cartTotalRub` / i18n, TASK_101, правила «Итого».

## 2026-10-05 — docs: intake TASK_101 (сумма заказа в блоке способов оплаты)

- ТЗ 1:1 из Google Doc → `customer_tasks/TASK-101-Сумма-заказа-в-блоке-способов-оплаты.md`, строка #101 в CBR. Код не менялся.
- /unlazy: ledger `artifacts/order_total_payment_methods/GATES.md` G1–G8, baseline G3–G6 met; открыт вопрос промо-скидки (cart.total vs Amount) → G7.

## 2026-10-05 — feat: TASK_100 точные сообщения ошибки оплаты + отдельный CTA (REVIEW)

- `shopPayFsm.js`: `classifyPaymentError` / `resolvePaymentErrorUi` / `PAY_ERROR_CATEGORY` — 1051 / 1014 / 119·2200 / карточный / общий fallback; NET и 5xx как были; старый общий текст удалён.
- Тексты Матрицы — `paymentMethodI18n.js`; в шторке alert = сообщение, кнопка = CTA (`errorCta`: change_card / close / retry).
- `Checkout.svelte`: `showPayError` (вкл. 3DS abort → общий), «Попробовать позже» закрывает шторку со сбросом, повторное открытие сбрасывает ошибку.
- Фиксы по пути: регрессия СБП #79 (`060ef61f`), 2 находки bugbot (`82a300b8`, `ebef66bf`).
- Local: JS 652 (60 legacy) · Rails shop 673/0 · GATES G1–G6 · bugbot/security 0 · crit-audit CLEAN. Deploy — по апруву.

## 2026-10-05 — docs: intake TASK_100 (сообщения ошибки оплаты + CTA)

- ТЗ 1:1 из Google Doc → `customer_tasks/TASK-100-Точные-сообщения-при-ошибке-оплаты-и-отдельный-CTA.md` + строка #100 в CBR.
- Новая задача (не патч/EXT), полный SBR. Ссылка на `TASK-26-REPEAT-ORDER-INVALID-TOKEN-EXT.md` — файла в репо нет.
- Код не менялся. Дальше `/spec`.
- /unlazy: ledger `artifacts/payment_error_messages_cta/GATES.md` (G1–G7), baseline JS зоны 68/0.
- /spec: todo TASK_100 — классификация 12 кодов (G6 met), решения владельца (1013/1053/1061/1078 → карточный, 3DS abort → общий, NET/BANK без изменений, «Попробовать позже» = закрыть шторку), 7 файлов.

## 2026-10-05 — docs: превью шторок для заказчика (4 пункта, без кода)

- Заказчик хочет увидеть компоненты глазами и дал шаблон: крестик · `>`/`v` peek/scroll · толстый отступ у Home Indicator · разный отступ на экранах. Сняты 13 скринов: local (= код v506) iPhone 390×844 с safe-area 34px, Android 412×915 (8px), прод v506; активный заказ — подмена `GET /shop/api/orders/active` в браузере.
- Работает как задумано: × в шторке статуса нет, «Состав заказа >/v», шторка остаётся peek, чек листается внутри себя до итога.
- Находки: шторка «Связь с поддержкой» (`SupportContactSheet`) открывается под `CartSheet` (обе `z-index: 50`), `✕` недоступен — и на проде → ISSUES; на iPhone под `CartSheet` пустая полоса 34px, сквозь неё видна страница; нижние отступы шторок разные (34 пусто / 50 внутри / 16 без safe-area).
- [MEASURE + черновик сообщения заказчику](../milestones/veha_2/artifacts/active_orders_receipt_display_restore/customer_preview_2026-10-05/MEASURE.md).

## 2026-10-05 — deploy: Fly v507 (seed guard Point A)

- Push `41a2d245..47be43cc` · CI [37273023483](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37273023483) + Semgrep + CodeQL green · deploy [37273363637](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37273363637) → v507.
- После выката: `/up` и витрина Point A 200 · barista-a на табло видит `#202609-0035` · guard в коде прода · демо-логины на `2fdee1ac`, дубль inactive · логи без 5xx.

## 2026-10-05 — fix: заказы витрины Point A не видны на табло бариста (prod data + seed guard)

- **Причина (prod):** 15.09 Point A `2fdee1ac` переименована (`napi x code_black`, slug `code_black`); 18.09 `demo:seed` искал точку по slug `demo-point-a` → создал пустой дубль `Demo Coffee Point A` (`c1bf2ab1`) и перепривязал barista-a / gm-a / shift-a / uk / franchise. Витрина пишет в `2fdee1ac`, бариста смотрел табло дубля (0 заказов). Код цепочки витрина→callback→табло исправен: все оплаченные заказы 29.09–01.10 получили `accepted` за 2–3 с.
- **Prod data (апрув владельца):** 5 демо-логинов + роли → `2fdee1ac`, дубль `c1bf2ab1` → `inactive` (без удаления). Проверено: barista-a на codeblack.coffee видит `#202609-0035`; live Turbo-рассылка заменяет `#barista-board-slots` без reload.
- **Код:** тест связи `test/integration/shop_order_to_barista_board_test.rb` (RED `2c2f9395`); `Demo::EnvironmentSetup` прерывается, если `SHOP_DEFAULT_TENANT_ID` — точка с другим slug (GREEN `8ee27e88`). Local 13/0 + зона barista/callback 56/0. Не запушено, deploy по апруву.

## 2026-10-04 — deploy: Fly v506 (RUBY-1N)

- RUBY-1N «Regressed» в 10:45 UTC: фикс не был запушен — прод v505 крутил старый код; Sentry resolved час назад без деплоя → следующий сэмпл = регрессия.
- Push `09620222..0fa72666` · CI/Semgrep/CodeQL green · deploy [`37198218226`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37198218226) → v506.
- Worker 11:30 UTC OK (4 stuck, 1668 ms) · Point A 200 · Sentry RUBY-1N → resolved · [MCP_RESULT](../milestones/veha_2/artifacts/mcp/fly_v506_2026-10-04/MCP_RESULT.md).

## 2026-10-04 — fix: RUBY-1N — хвост N+1 при save_card=true

- Sentry MCP: последнее событие RUBY-1N (04.10 09:00 UTC) — прод v505 без фикса; в трейсе 4 stuck → 8 `SELECT payments WHERE id`.
- `01efc828` закрывал только `save_card=false`; при `save_card=true` `rebill_still_needed?` всё ещё делал reload на каждый pending.
- RED `6f401fb5` → GREEN `1642a746`: в `TbankPaymentSync#apply_state!` rebill-ветка только для `succeeded` (RebillId приходит лишь с CONFIRMED; ErrorCode у failed пишется через `PaymentStatusUpdater`).
- Local: `test/jobs/payments` + `test/services/payments` 146/0 · rebill/UserCards/callback 57/0.

## 2026-10-04 — audit: /crit-audit CLEAN (`6309066c..0319513b`)

- Scope: 2 файла кода (RUBY-1N): `StuckPaymentsCheckJob` без `payment.reload`, `TbankPaymentSync#rebill_still_needed?` ранний выход по in-memory `save_card`.
- C1–C5 кандидатов нет: смена статуса — `PaymentStatusUpdater` + `@payment.reload` на том же объекте; `save_card` пишется только до/при Init.
- Local: `test/services/payments` 137/0, `test/jobs/payments` + sync 15/0 · CI pending · Fly MCP skip (не витрина).
- Backlog: лишний Telegram-алерт при гонке webhook vs job (шум, не критично).

## 2026-10-01 — fix: RUBY-1N — N+1 в StuckPaymentsCheckJob

- Sentry `RUBY-1N` (perf N+1): на проде 4 stuck T-Bank платежа (`save_card=false`, GetState → всё ещё pending) → по 2 `SELECT payments WHERE id` на каждый.
- RED `4e5452d7`: 3 платежа → 6 by-id SELECT. GREEN `01efc828`: в job убран `payment.reload` (sync держит тот же объект и reload после смены статуса); `TbankPaymentSync#rebill_still_needed?` — reload только если `save_card` разрешён.
- Local: 160/0 (stuck job + services/payments + tbank callback), 419/0 (jobs/payments + §2.3 + shop/subscriptions services).

## 2026-10-01 — deploy: Fly v505 (TASK_83 / TASK_84 аудит) — MCP Point A PASS

- Push `09620222` → CI `36841893742` + Semgrep + CodeQL green → Deploy to Fly.io `36842242232` (workflow_dispatch) → v505.
- Приёмка: `/up` 200, витрина 200; bundle — `aoa__dismiss` 0, `aoa__receipt-arrow`, `receipt-open`, `max(8px` есть; DOM `--shop-safe-bottom` = 8px, CartSheet на 8px. Sentry 24h — RUBY-1N (до деплоя). Live шторки — skip (нет активного заказа).
- Артефакт: `artifacts/mcp/fly_v505_2026-10-01/MCP_RESULT.md` + скрин.

## 2026-10-01 — docs: номера строк TASK_83 + COMPONENT_MAP после Review

- `ba5f67c2`: TASK_83 §2–3 / «Файлы» / таблица — `dismissOrder` 137–146, `refreshMode` 95–100, `aoa__dismiss` и проброс `onDismiss` удалены; Subtask patch v1 отмечены.
- `COMPONENT_MAP.md`: `OrderStatusSheet` (без dismiss, peek-only `receipt-open`, safe-bottom), `ActiveOrdersAccordion` (без ×, CTA 293–303 со стрелкой, чек 353–379), `orderStatusSheet.js` (137–146 / 95–100).

## 2026-10-01 — review: TASK_SAFE-BOTTOM-MIN — CI green

- `/regress` PASS (JS 616 / 60 legacy · vite build · Rails `test/integration/shop` 420/0).
- bugbot: резерв `Catalog` / `CategoryProducts` / `Product` под CartSheet не учитывал её подъём на `--shop-safe-bottom` (последний ряд мог уйти под шторку на 8px; на iPhone — на 34px и раньше) → RED `835566b2` → GREEN `6309066c` → повторный bugbot 0.
- security 0 · `/crit-audit` CLEAN · CI + Semgrep + CodeQL green [36837366924](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36837366924) на `f74e2e5d`.

## 2026-10-01 — feat: TASK_SAFE-BOTTOM-MIN — минимальный нижний отступ 8px (GREEN)

- Intake `5e516968`: доп.задачи 3 (шторка статуса) и 4 (все экраны) слиты — шторка встроена в CartSheet, её низ = `--shop-safe-bottom`. N = 8px.
- RED `e6a57efb` → GREEN `1c21dbda`: `app.css` `--shop-safe-bottom: max(8px, env(…))`; `shopWebViewLayout.js` `SHOP_SAFE_BOTTOM_MIN_PX`; `CatalogFiltersSheet`, `CatalogSortSheet`, `ContactSupportSheet`, `OrderReceipt`, `OrderStatusSheet` на `var(--shop-safe-bottom)`.
- Тесты: новый 11/0, JS зона 344/1 (legacy), Rails 67/0.

## 2026-10-01 — review: TASK_84-RECEIPT-ARROW-EXT — CI green

- `/regress` PASS (JS 605 / 60 legacy · vite build · Rails 100/0) · bugbot 0 · security 0 · `/crit-audit` CLEAN · CI + Semgrep + CodeQL green [36832232323](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36832232323) на `f4658bb7`.

## 2026-10-01 — feat: TASK_84-RECEIPT-ARROW-EXT — стрелка >/v на кнопке «Состав заказа» (GREEN)

- Intake `86a123ce` (сценарий владельца; стрелка только на кнопке чека). RED `c0aef683` → GREEN `d3f929a8`.
- `ActiveOrdersAccordion.svelte`: в `aoa__receipt-cta` декоративная `aoa__receipt-arrow` (`aria-hidden`) из `row.chevron`; `aria-label` и `LABELS.receipt` без изменений; chevron #36 на шапке не возвращён.
- Тесты: новый 3/0, JS зона 197/1 (legacy). Браузерная проверка не пройдена — browser MCP завис.

## 2026-10-01 — review: TASK_84-PEEK-ONLY-EXT — CI green

- `/regress` PASS (JS 602 / 60 legacy · vite build · Rails 100/0) · bugbot 0 · security 0 · `/crit-audit` CLEAN · CI + Semgrep + CodeQL green [36825940981](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36825940981) на `f6f95987`.

## 2026-10-01 — feat: TASK_84-PEEK-ONLY-EXT — статусная шторка только peek (GREEN)

- Intake `c4f4bd0e` (сценарий владельца, вариант а — CartSheet не поднимаем). RED `8f795504` → GREEN `8b75d868`.
- `OrderStatusSheet.svelte`: `statusSheetMode` только hidden/peek; открытый чек → `.oss__panel.receipt-open { overflow-y: auto }` без роста высоты; CSS `.expanded` удалён. Rails-тест `EXPANDED` перевёрнут.
- Тесты: JS зона 173/1 (legacy), Rails 20/0, браузер 390×844 — чек 101px в peek 136px, `Total Amount` через scroll чека.

## 2026-10-01 — review: TASK_83 Патч 1 — CI green

- `/regress` PASS (JS 597 / 60 legacy · vite build · Rails active_orders 13/0) · bugbot 0 · security 0 · `/crit-audit` CLEAN.
- CI `scan_ruby` упал на brakeman `--ensure-latest` (вышел 8.1.0) → `Gemfile.lock` brakeman 8.0.6 → 8.1.0 (`f2253be4`) → CI + Semgrep + CodeQL green [36821953421](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36821953421).

## 2026-09-30 — feat: TASK_83 Патч 1 — убран × из статусной шторки (GREEN)

- RED `f7a6dc49` → GREEN `93f500ee`: в `ActiveOrdersAccordion.svelte` удалены кнопка `×` (`status-widget-dismiss`), проп `onDismiss`, CSS `.aoa__dismiss`; в `OrderStatusSheet.svelte` удалены проброс `onDismiss={onDismissOrder}`, `onDismissOrder`, импорт `dismissOrder`.
- `dismissOrder` / `refreshMode` в `lib/orderStatusSheet.js` оставлены — покрыты `order_status_sheet_test.mjs`. Чек #84 / EXT и `accordionState` не трогались.
- Тесты: 51/0; зона 168/1 (1 = legacy «422/500», ISSUES). Deploy запрещён до закрытия задачи.

## 2026-09-30 — feat: TASK_84-RECEIPT-DISPLAY-EXT Патч 1 — чек в статусной шторке виден целиком (REVIEW)

- `fitReceiptInView` (`activeOrdersAccordion.js`) + `ActiveOrdersAccordion.svelte`: при раскрытии CTA прокручивается к верху `.oss__panel`, `max-height` чека = видимое место до клипа (`CartSheet`), свой scroll + `overscroll-behavior: contain`. Refit на `transitionend` панели, `ResizeObserver` (CartSheet драг), смену push recovery/toast; устаревший async fit отбрасывается (`fitGeneration`).
- Браузер 390×844: было 61/196px видно → целиком; `Total Amount` через scroll чека, внешняя панель не скроллится. `CartSheet`/`OrderStatusSheet`/`receiptView` не менялись.
- REVIEW: bugbot 2 раунда (4 находки → fixed) · security чисто · `/crit-audit` CLEAN · JS зона 138/0 · Rails `active_orders_receipt` 4/0 · vite build OK.

## 2026-09-30 — docs: TASK_84-RECEIPT-DISPLAY-EXT Патч 1 — причина исчезновения чека доказана

- Local dev 390×844, реальный клик «Состав заказа»: `.aoa__receipt` в DOM (196px), видно 61px. Режут `.oss__panel.embedded.expanded` 224px (`OrderStatusSheet.svelte:348–350`) и `CartSheet` `overflow:hidden` 287px. Артефакт: `artifacts/active_orders_receipt_display_restore/patch1_browser_2026-09-30/`. Код не менялся.

## 2026-09-30 — test: TASK_84-RECEIPT-DISPLAY-EXT Патч 1 — SSR DOM-контракт receipt

- `test/javascript/svelte_ssr_helper.mjs`: loader-хук `svelte/compiler` (generate server) + `svelte/server` render, без новых зависимостей. 3 теста: свёрнуто — нет `.aoa__receipt`; после `openOrderReceipt` — `.aoa__receipt` + позиция + `Total Amount` + scroll 350px, без кнопок; только один раскрытый.
- Результат: 30/0 сразу; мутация рендера → 2 fail. Дефекта в рендере/стейте нет — причина исчезновения вне компонента (гипотеза: обрезание внешней панелью, нужен браузер). Код приложения не менялся.

## 2026-09-30 — docs: /patch — TASK_83 Патч 1 (убрать ×) + TASK_84-RECEIPT-DISPLAY-EXT Патч 1 (receipt DOM + scroll)

- Классификация по read-only аудиту: `×` → ПАТЧ TASK_83; receipt не подтверждён DOM-тестом + внешний `max-height: min(36vh, 14rem)` (`OrderStatusSheet.svelte:348–350`) перекрывает внутренний scroll 350px → ПАТЧ EXT (Subtask 11/13). Причина исчезновения receipt не установлена — определяется RED.
- Доп.задачи в `DEMO_FEEDBACK` (`open`): «только peek», новые `>`/`v`, min Home Indicator (шторка / все экраны). Номера строк TASK_83 / `COMPONENT_MAP` — после Review. Код не менялся.

## 2026-09-29 — ops: первый /crit-audit — CLEAN (baseline)

- Scope `0a3ac0db..dd072f3f`: 0 файлов в app/ lib/ db/ config/ frontend/ → находок нет · CI+Semgrep+CodeQL green на `0a3ac0db` · smoke/Fly MCP skip (код = CI-прогон) · `CRITICAL_LEDGER` baseline `dd072f3f`

## 2026-09-29 — docs: /crit-audit — конечный аудит критических ошибок

- Новое правило `workflow/coffeeos-critical-audit.mdc`: критично = только C1–C5 (тенанты, деньги/оплата, авторизация, падение hot-path, потеря данных); находка только с `файл:строка` + сценарием + падающим тестом; scope = дифф от `last_audited_sha`; вердикт `CLEAN` / `BLOCKED: N` по объективным гейтам (CI · `bin/smoke` · Fly MCP Point A)
- Журнал `docs/operations/dev/CRITICAL_LEDGER.md` (открыто / исправлено / отклонено) — новый чат не повторяет закрытое
- Команда `/crit-audit`; встроена в `/review` и PHASE 3 шаг 2 (`spec-build-review.mdc`); блокеры в `coffeeos-code-review.mdc` = C1–C5; индексы обновлены

## 2026-09-29 — ops: Fly v504 deploy (TASK_95–99) + пачка приёмки

- CI + Semgrep + CodeQL green на `0a3ac0db` ([36578912741](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578912741)) → `fly deploy` v504
- Миграции `subscription_offer_states` + `marketing_events` на проде · Fly logs без 5xx · Sentry 24h 0 issues
- Проверка на проде: эндпоинты `subscription_offer/*` → 401 без auth; bundle с баннером/LK/`requestPermission`; SW `offer_url`; `OfferFunnelReport` / `OfferPresentationService` read-only OK · [MCP_RESULT](../milestones/veha_2/artifacts/mcp/fly_v504_2026-09-29/MCP_RESULT.md)
- Открыто: TASK_99 G4 физический iPhone · live offer — после billing UI

## 2026-09-29 — feat: TASK_99 iOS WebPush — системный диалог разрешения (REVIEW)

- `firebasePush.js`: `Notification.requestPermission()` — первый async после sync-проверки `"Notification" in window`; `isSupported()` / `firebaseClientConfigured()` / `getToken()` / `/push/register` — только после `granted`; `opts.deps` для тестов (дефолт = реальные функции)
- `orderStatusNotifyActions.js`: статический импорт `registerShopPush` вместо `await import()` в пути аккордеона
- RED `b016f7dc` → GREEN `48fa2646` · JS 27/0 · зона 88/0 · Rails push 19/0 · bugbot 0 · security 0 · CI green [36578386943](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578386943)
- Открыто: G4 физический iPhone · G5 Fly MCP — после deploy по апруву

## 2026-09-29 — docs: TASK_98 /regress PASS

- Rails зона 22 файла: `test/services/subscriptions/**`, `test/jobs/shop/*`, `test/integration/shop/**/subscription*`, `marketing_event_test`, `profile_subscription_offer_test`, `subscription_offer_eligibility_test`, manager reports RBAC (general/shift) + `manager_office_panel_test` — 172 runs / 845 assertions / 0 failures
- JS `subscription_offer_banner/card_test.mjs` — 39/0

## 2026-09-29 — test: TASK_98 /sbr (пустой отчёт воронки)

- `00bdcf64`: +2 теста в `subscription_offer_funnel_test.rb` — `OfferFunnelReport` на пустом диапазоне (`rows: []`, totals нулевые) и `/manager/subscription_offer_funnel` JSON 200 с пустыми rows
- Сразу зелёные (2/0) — поведение уже было верным, прод-код не менялся; RED-substep не применим (характеризация)
- `--reverify` G1–G6 met · G7 Fly manual
- Entire: attach `--force` в WSL amend-нул HEAD параллельной сессии (`a832cc3` → `e592af1a`, только trailer, не запушен); чекпоинт `01M3PPM41DS4J8RQG6RB3TK0K2` перепривязан на ops-коммит. Урок: перед attach проверять `git log -1` в той же команде

## 2026-09-29 — feat: TASK_97 push-оффер подписки (REVIEW)

- Реализация — в TASK_96 `63a317a1` (`OfferPushNotifier`, side-effect `mark_shown`); TASK_97 закрыл пробел «idempotency при параллельных вызовах»
- RED `d798968b`: `offer_push_concurrency_test` (non-transactional, реальные соединения) — 2 параллельных `OfferPushNotifier.call` с одним ключом → 2 push
- GREEN `c187fd81`: `create_once` — `already_sent?` + `create!` в транзакции под `pg_advisory_xact_lock(hashtext(key))`, job после коммита; без миграции
- Local: зона 28 файлов 176/0 · concurrent ×5 · GATES G1–G3, G5, G6 met · G4 Fly после deploy
- Review: bugbot — 0 · security-review — 0 medium+

## 2026-09-29 — docs: TASK_98 /unlazy ledger

- Новый `artifacts/subscription_offer_funnel_utm/GATES.md` (G1–G7); Google Doc TASK_98 — без патчей/доп.задач, комментариев нет
- TASK_98 ⊂ TASK_96 Subtask 22–33: 7 событий, `MarketingEventLogger`, атрибуция в `subscriptions.utm_*`, `OfferFunnelReport` + `/manager/subscription_offer_funnel` уже в `63a317a1`
- PASS: G1 модель+API 17/0 · G2 push_sent 12/0 · G3 атрибуция+отчёт 9/0 · G4 JS баннер/карточка · G6 зона 89/0
- G5 FAIL: пустой диапазон отчёта не покрыт тестом (0 runs) — RED на /sbr · G7 Fly manual
- `EXPECT` с regex — только в `/…/` (иначе literal substring)

## 2026-09-29 — docs: TASK_99 /unlazy ledger

- Новый `artifacts/ios_webpush_permission/GATES.md` (G1–G5); `session/GATES.md` → указатель на TASK_99
- Baseline: G1 `order_status_push_subscribe_test.mjs` 18/0 · G3 зона notify/accordion/SW/sheet 88/0 · G2 статический оракул (порядок `requestPermission` < `isSupported` < `getToken`, нет `import("./firebasePush.js")`) FAIL — ожидаемо до GREEN
- ТЗ: `npm test`/`npm run typecheck` отсутствуют в `package.json` → `node --test`; статический импорт `firebasePush.js` в Node грузится (IMPORT_OK)

## 2026-09-29 — docs: TASK_97 SPEC

- `todo.md` — блок TASK_97 сверху (TASK_96 ниже без изменений): сверка Subtask 1–9 с GREEN #96 `63a317a1` — всё покрыто, кроме concurrent idempotency
- Файлы: новый `offer_push_concurrency_test.rb` (non-transactional, потоки) · фикс `OfferPushNotifier` (advisory lock) только если тест красный · COMPONENT_MAP владелец +TASK_97
- `GATES.md` +G5 concurrent

## 2026-09-29 — fix: CI scan_ruby — rack-proxy 2.0.1 (TASK_95 REVIEW)

- `Gemfile.lock`: rack-proxy 0.7.7 → 2.0.1, vite_ruby 3.10.2 → 3.11.0 (`bundle update --conservative`) — GHSA-42qh-8mx8-7wqm, bundler-audit чисто
- Local: layout/Vite 3 файла + TASK_95 — 50/0
- Push `23565015` (cherry-pick поверх `origin/develop`, без RED #96) · CI [36567405779](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36567405779) green · Semgrep/CodeQL green

## 2026-09-29 — docs: TASK_97 /unlazy ledger

- `artifacts/subscription_offer_push/GATES.md` — 4 gates: G1 `offer_push_notifier_test` · G2 OfferPresentationService/state API (TASK_95) · G3 push/FCM regression (8 файлов) · G4 Fly MCP manual
- `--approve`: G1–G3 PASS (evidence на незакоммиченном GREEN TASK_96 в рабочей копии) · G4 pending (deploy по апруву)
- Пробел: «idempotency при параллельных вызовах» покрыт последовательными повторами, не concurrent-тестом

## 2026-09-29 — docs: TASK_97 intake

- `customer_tasks/TASK-97-Push-оффер-подписки.md` — Google Doc 1:1 + заметки агента; патчей/EXT/комментариев в доке нет
- CBR #97 (intake) · пересечение: целиком ⊂ TASK_96 Subtask 14–21 (backend `OfferPushNotifier`), без SW deep link / аналитики → не зависит от billing UI · судьба — решение владельца

## 2026-09-29 — docs: TASK_96 SPEC

- `todo.md` → TASK_96 (весь scope, Subtask 1–36): 14 групп путей (frontend модуль+баннер+карточка · OfferPushNotifier · SW `offer_url` · marketing_events + logger · `POST subscription_offer/opened` · атрибуция в PaymentFulfillment · OfferFunnelReport + manager JSON) + Не ломать / Проверка
- 13 решений по умолчанию (idempotency push = id `banner_shown` на переход; UTM `subscription_offer` / `<channel>_v1`; sendBeacon; без RLS как `subscriptions`)
- **BLOCKED:** во frontend нет экрана оформления подписки (billing UI, Задача-3) — решение владельца: TASK_96 ждёт; TASK_97/98 — пересечение учтено, не делаем

## 2026-09-29 — docs: TASK_96 intake

- `customer_tasks/TASK-96-Оффер-подписки-frontend-push-и-аналитика.md` — Google Doc 1:1 + заметки агента (overlap TASK_97/98, зависимость от #95)
- `artifacts/subscription_offer_frontend_push_analytics/README.md` · CBR #96 (intake · ждёт `/spec`)
- /unlazy `GATES.md` — 7 gates: G1–G4 новые тесты (unmet, RED на `/sbr`) · G5 backend regression PASS · G6 OrderStatus JS regression PASS · G7 Fly MCP pending

## 2026-09-29 — feat: TASK_95 subscription offer guest state (REVIEW)

- Новое: таблица `subscription_offer_states` (1 на гостя, без RLS как `subscriptions`) · `Subscriptions::OfferPresentationService` · `POST /shop/api/subscription_offer/{shown,dismiss,viewed}` (401 без сессии) · `GET /shop/api/profile` +`should_show_banner`/`has_unread_offer_in_lk` · `PaymentFulfillment` → `mark_purchased!`
- Правила: промо 11₽ блокирует · повтор после ≥3 новых completed заказов на текущей точке после dismiss · purchased/активный подписчик — оффер off на любой точке
- Bugbot фиксы: повтор не сравнивает снимок другой точки; подписчики без state не видят оффер
- Local 194/0 (TASK_95 34 · подписки/промо/профиль 94 · T-Bank callback 50 · RLS 16) · bugbot + security-review чисто
- Коммиты: RED `a88558cb` · GREEN `42b61e1c` · fix `bb64f742` · Entire `01M3P4QA99DMBM0JSZYKKWSHZ5`
- Docs: `shop-api.md`, `pwa-realtime.md`, `COMPONENT_MAP.md`
- Не сделано: Fly MCP G7 (после deploy по апруву) · frontend баннера/ЛК/push — отдельные задачи

## 2026-09-29 — docs: TASK_95 SPEC

- `todo.md` → TASK_95: 7 путей (migration · model · OfferPresentationService · SubscriptionOffersController · routes · profile · PaymentFulfillment) + Не ломать / Проверка
- Решения по умолчанию: флаги в `/shop/api/profile` · +`POST subscription_offer/shown` (пробел ТЗ) · `mark_purchased` в `PaymentFulfillment` · заказы на текущей точке · таблица без RLS как `subscriptions`

## 2026-09-29 — docs: TASK_95 intake + /unlazy ledger

- Intake: [`TASK-95-…`](../milestones/veha_2/requirements/customer_tasks/TASK-95-Состояние-оффера-подписки-на-гостя.md) · CBR #95 · полный SBR (новая фича)
- Ledger: [`artifacts/subscription_offer_guest_state/GATES.md`](../milestones/veha_2/artifacts/subscription_offer_guest_state/GATES.md) — G1–G4 unmet (тестов нет) · G5–G6 regression baseline PASS · G7 Fly после deploy
- Вопросы к `/spec`: `profile/config` = `/shop/api/profile` или `/shop/api/config`; eligibility уже учитывает GrowthPromo; purchased cross-tenant vs RLS

## 2026-09-29 — ops: Fly v503 deploy + Point A MCP (batch since v502)

- HEAD `2a9adacb` · CI [`36253679528`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36253679528) + Semgrep + CodeQL green
- В релизе: GrowthPromo `amount_rub` · CTA cache clear · #77 Patch 1 · Задача-1 Patch 1 · Задачи-3 Patch 1 (migration `20260926190000`)
- Local: Rails зона подписок **65/0** · JS **22/0**
- Prod: миграция/колонки/индекс OK · health passing · 5xx нет
- MCP Point A: catalog/cart/checkout PASS · `growth_promo.amount_rub=11` · offer `enabled=false` · subscriptions без auth 401 · Sentry skip (OAuth)
- Finding: фото `/uploads/products` 404 после деплоя (эфемерный диск) → ISSUES
- Артефакт: `milestones/veha_2/artifacts/mcp/fly_v503_2026-09-29/`

## 2026-09-26 — review: Задачи-3 Патч 1 — CI green

- Local: subscriptions 29/0 · CTA JS 18 PASS
- bugbot: no bugs · security: no medium+
- Entire `01M3F6KCQVG7SF39R9KE8EEARD` на `0fe747a0` (session attach)
- Push develop · CI [`36253473587`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36253473587) + Semgrep + CodeQL **success**
- Deploy — апрув; OrderCreator SKU wiring — backlog

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

