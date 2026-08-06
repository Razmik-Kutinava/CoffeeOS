# Бизнес-требования заказчика (после прогонки)

**Индекс** потоков, волн, §2.3, табло. **Полные ТЗ заказчика** — [`customer_tasks/`](customer_tasks/README.md). Код — после MCP/статуса в файле задачи.

**Источник слов заказчика:** чат 2026-06 + PDF [`artifacts/demo-feedback/customer_qa_prog10_2026-06.pdf`](artifacts/demo-feedback/customer_qa_prog10_2026-06.pdf) (RU: `customer_qa_prog10_2026-06_ru.pdf`, 56 стр.).

---

## Контекст для агента (простыми словами)

| Что | Зачем |
|-----|--------|
| **PDF прогонка** | Заказчик **сам прошёл** все сценарии, оставил комментарии «ок / не ок» в PDF. |
| **`DEMO_FEEDBACK.md`** | Мы **вытащили баги из PDF §1–3**, починили, MCP на Fly → строки **`done`** (2026-06-04). **Не значит**, что весь PDF или все новые слова заказчика закрыты. |
| **Прогон 10 (ops)** | **Наш** техпрогон блоков 0–14: [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md), JSON в [`artifacts/prog10/`](artifacts/prog10/). Это **не** то же самое, что PDF заказчика. |
| **Этот файл** | Индекс потоков, волн, §2.3, табло. **ТЗ заказчика** — [`customer_tasks/`](customer_tasks/README.md). |
| **УК → витрины** | Уже закрыто на Fly — [`HANDOFF_UK_MENU_VITRINA.md`](HANDOFF_UK_MENU_VITRINA.md). |

**Стадия (2026-06-06):** **§2.3 закрыт**, **2A закрыт**, **волна 4 W1.1–W1.5 закрыта**. **Следующий фокус:** **блок 2** (табло). **Backlog потока 1** — таблица ниже (не забыть).

**Принципы (согласовано с владельцем):**
- Бариста/TV — только **`accepted`** (оплаченные). Fail/отказ — **менеджер/УК**, не табло.
- MCP DevTools на Fly **обязателен** перед `done` в чеклисте; без MCP — статус `open` / `needs_mcp`.
- Deploy Fly должен быть **актуален** перед прогоном §2.3.
- **Северная звезда:** PDF **56 стр.** — заказчик **сам прошёл** все сценарии; в любом порядке работ мы **не теряем** эту карту. Новые вводные **дополняют**, но не отменяют PDF без явного решения.

---

## Три потока продукта (канон — общими мазками)

| № | Поток | Суть | Сейчас |
|---|-------|------|--------|
| **1** | **Приём заказа** | Витрина (mobile first → PWA → app → kiosk): меню, модификаторы, цены, оплата, регистрация, уведомления, юр. | **§2.3 + W1.1–W1.5 `[x]`** (mobile web готов); **backlog** — см. ниже |
| **2** | **Обработка заказа** | Табло баристы (Flutter или web): заказы, статусы, отмена/возврат, стоп-лист. **Плюс УК:** журнал, логин, транзакции, мониторинг | **2A `[x]`**; **табло — `[ ]`** ← **сейчас** |
| **3** | **Тест-приёмка** | Сквозной happy path: витрина → табло → уведомления; изоляция точек; возвраты; **отказ на каждом экране** | **`[ ]`** — после потоков 1–2 |

> **Было раньше в этом файле:** «блок 3 — обратная связь гостю» (push, чек на почту). Это **часть потока 1** (уведомления), не отдельный поток. **Поток 3** — именно **сквозная приёмка**, как в таблице выше.

---

## Траектория: как шли → новые вводные → куда сместились

**Зачем этот блок:** фиксируем **курс** и **отклонения**, чтобы не забыть, с чего начинали и почему сейчас делаем не «по порядку PDF страница за страницей».

| Волна | Период | Фокус | Откуда вводные | От PDF 56 стр. |
|-------|--------|-------|----------------|----------------|
| **0** | до 2026-06 | Прогон 10 ops, онбординг, prog10 JSON | Наш техпрогон блоков 0–14 | **Параллельно** PDF — не замена |
| **1** | 2026-06-04 | DEMO_FEEDBACK §1–3, баги из PDF | Заказчик прошёл PDF, мы вытащили §1–3 | **Близко** к PDF §1–3 |
| **2** | 2026-06-04…06 | **§2.3 оплата витрина** (этапы 1–5) | Жалобы после банка, iframe, журнал отказов | **PDF §2.3–2.4** — прямое попадание |
| **3** | 2026-06-06 | **Блок 2A** — УК: мониторинг, журнал, сессии, транзакции | Решение: **до табло** нужна видимость для УК | **Вставка** — в PDF нет отдельного «2A», но нужна для §3 УК |
| **4** | **2026-06-06** | **Поток 1 волна 4** W1.1–W1.5 | Меню/цены/модификаторы/категории на Fly | **§2.1–2.2, §1.3** — закрыто для mobile web |
| **5** | **сейчас** | **Поток 2** — табло баристы | После волны 4 | **§3 табло**, §1.4–1.6 |
| **6** | далее | **Поток 3** — сквозной happy path | Приёмка по PDF | **Финиш** — 56 стр. |

**Честно про отклонение:** мы **не шли** PDF строго 1→56. Сначала закрыли **§2.3** (оплата), потом **вставили 2A** (УК). Это **осознанный** сдвиг: без оплаты и без мониторинга табло бессмысленно. **Не отходим от главного:** в конце **поток 3** = прогон сценариев заказчика + наш MCP по [`ONBOARDING_DEVTOOLS_SCENARIOS.md`](../runbooks/ONBOARDING_DEVTOOLS_SCENARIOS.md) (58 шт.).

**Где ещё пишем траекторию:** [`CHECKLIST.md`](../checklists/CHECKLIST.md) § «Потоки» · [`SESSION_STATE.md`](../../session/SESSION_STATE.md) · [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) (строки done/open).

---

## Волна 4 — поток 1 «Приём заказа» (следующие задачи)

**Запрос владельца (2026-06):** после §2.3 и 2A — **довести витрину** до «меню из УК = то же на витрине», потом табло.

| # | Задача | Есть / нет | Статус | Примечание |
|---|--------|------------|--------|------------|
| W1.1 | **Баг 6.1** — цена из УК/менеджера **не доходит** на витрину | **исправлено** 2026-06-06 | `[x]` **PASS** | `manager/menu#update_price` → `bust_shop_catalog_cache!`; ключ кэша с `page=nil` тоже сбрасывается |
| W1.2 | **MCP:** из УК категория + 2 товара + фото + модификаторы → **проверка на витрине** | **PASS** 2026-06-06 | `[x]` | Fly: `W12-FLY-0606` + 2 товара + фото URL → API A/B + DOM A; модификаторы на Fly — **integration test** (браузер MCP scroll); файл фото — test only |
| W1.3 | **Обязательные модификаторы** — на тестовом контенте | **PASS** 2026-06-06 | `[x]` | Fly: `W13-REQ-SIZE` is_required → alert «Выберите…»; integration test |
| W1.4 | **Сверка категорий:** ядро = витрина = barista | **PASS** 2026-06-06 | `[x]` | Fly FULL A+B; `Shop::Catalog.tenant_menu`; апрув заказчика; стоп-UI — backlog |
| W1.5 | **Боевые оплаты** — финальный MCP smoke | **есть** | `[x]` | §2.3 закрыт; `SHOP_SIMULATE_PAYMENT=0` + webhook T-Bank |

**Следом — волна 5:** **поток 2** — табло баристы ([«Блок 2»](#блок-2--обработка-заказа-табло-баристы) ниже).

---

## Поток 1 — backlog (напоминание, не блокер табло)

> Агент: **напоминать** владельцу при планировании. Не `[x]` — пока не взяли в работу.

| # | Что | Зачем | Приоритет |
|---|-----|-------|-----------|
| B1.1 | **Уведомления гостю** — экран статуса + прогресс-бар | [ТЗ](customer_tasks/B1_1_order_status_progress.md) · PDF §1.7 | **`[x]`** 2026-06-10 · FCM v1 на Fly · smoke `push_register` PASS |
| B1.2 | **Юр.** — оферта, согласия на витрине | Регистрация / оплата | средний |
| B1.3 | **Чек / ОФД на почту** | После оплаты | средний |
| B1.4 | **PWA витрины** | [ТЗ](customer_tasks/B1_4_pwa_shop.md) · manifest + SW + offline; app/kiosk отдельно | **`[x]`** апрув 2026-07-05 |
| B1.5 | **ТТК + туториал УК** | Блок 1.1 | низкий |
| B1.6 | **Стоп-лист UI barista** — серый блок «в стопе» | W1.4 backlog; сейчас sold_out скрыт | низкий |
| B1.7 | **Email verify** — checkout · **ЗАКРЫТА** | [ТЗ](customer_tasks/B1_7_checkout_order_screen.md) | **`[x]`** внутр. · Fly MCP `[x]` · заказчик `[x]` 2026-06-04 |
| B1.10 | **Витрина** — убрать «Блог» из навигации, LCP ≤ 1.5 с WebView | [ТЗ](customer_tasks/B1_10_remove_blog_nav.md) | **`[x]`** апрув 2026-06-18 |
| B1.9 | **Карточка товара** — toggle модификаторов, без обязательности | [ТЗ](customer_tasks/B1_9_product_modifier_toggle.md) | **`[x]`** апрув 2026-06-18 |
| B1.9-CC2 | **Карточка товара** — восстановить выбор модификаторов после возврата из корзины | B1.9 CC-2 · backlog | низкий |
| UserCards wipe→new | **Сохранение карты после оплаты** — чистый лист | [ТЗ](customer_tasks/Исправление%20сохранения%20карты%20в%20UserCards%20после%20успешной%20оплаты.md) | wipe [x] · код снесён · реализация [ ] |
| B1.11 | **Режим работы точки** — УК, витрина, табло | [ТЗ](customer_tasks/B1_11_tenant_operating_hours.md) | **`[x]`** апрув 2026-07-05 |
| B1.13 | **Новая навигация витрины** — эпик S1–S4 (шапка, поп-ап корзины, bottom bar) | [ТЗ](customer_tasks/B1_13_shop_nav_profile_header.md) | **rev2** `[x]` апрув 2026-07-01 · **S4-канон** docs `[x]` · **S4 код** `[ ]` |
| B1.14 | **Адрес точки + выбор точки** в шапке витрины (заказчик «задача 2») | [ТЗ](customer_tasks/B1_14_shop_tenant_address_header.md) | **клиент `[x]`** · апрув 2026-07-05 · **B1.14-4** `[ ]` |
| B1.8 | **Свой домен → своя почта для рассылки** | После домена (не `fly.dev`): `noreply@…` / `orders@…`, DNS в Brevo (SPF/DKIM/DMARC), сменить `MAIL_FROM` на Fly | **напоминание** |
| Hidden mode cards | **Витрина** — режим hidden: crop превью карточек (не ломать peek/expanded) | [ТЗ](customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md) · скрины [`artifacts/product_card_hidden_mode/`](../artifacts/product_card_hidden_mode/README.md) | **SBR REVIEW `[x]`** · код `[x]` · апрув `[ ]` |
| Bottom sheet expanded grid | **Витрина** — expanded до 1-го ряда каталога + сетка товаров 4 в ряд со скроллом | [ТЗ](customer_tasks/Bottom%20Sheet%20expanded%20mode%20и%20внутренняя%20сетка%204%20в%20ряд.md) · скрины [`artifacts/bottom_sheet_expanded_grid/`](../artifacts/bottom_sheet_expanded_grid/README.md) | **закрыта `[x]`** 2026-07-21 · UX принят как канон, код не менялся, тесты-фиксаторы · deploy `[ ]` |
| Quick Repeat Bottom Sheet | **Витрина** — быстрый повтор частых покупок: секция «повторить» (1–3 карточки) в bottom sheet, peek/expanded/hidden, «повторить в 1 клик»; **NEW:** скрывать при активном заказе (`has_active_order`); status sheet на всю ширину | [ТЗ](customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md) · скрины [`artifacts/quick_repeat_bottom_sheet/`](../artifacts/quick_repeat_bottom_sheet/README.md) | **Fly v416 MCP PASS `[x]`** 2026-07-31 · апрув заказчика `[ ]` |
| Cart sheet gesture hit area | **Витрина** — свайп шторки чувствительнее: реагирует на весь прямоугольник полосы (не только «крючок») | [ТЗ](customer_tasks/Чувствительность%20свайпа%20шторки%20hit%20area%20прямоугольник.md) · [`artifacts/cart_sheet_gesture_hit_area/`](../artifacts/cart_sheet_gesture_hit_area/README.md) | **MCP PASS `[x]`** 2026-07-23 · апрув заказчика `[ ]` |
| Expanded no catalog grid | **Витрина** — в expanded шторке убрать сетку товаров, оставить только список заказов | [ТЗ](customer_tasks/Убрать%20сетку%20товаров%20из%20expanded%20шторки.md) · [`artifacts/cart_sheet_expanded_no_grid/`](../artifacts/cart_sheet_expanded_no_grid/README.md) | **GREEN `[x]`** 2026-07-23 · redeploy/MCP `[ ]` |
| Cart sheet remove undo | **Витрина** — убрать кнопку «Отменить» (undo удаления) в шторке | [ТЗ](customer_tasks/Убрать%20кнопку%20Отменить%20в%20шторке%20корзины.md) · [`artifacts/cart_sheet_remove_undo_button/`](../artifacts/cart_sheet_remove_undo_button/README.md) | **GREEN `[x]`** 2026-07-24 · redeploy/MCP `[ ]` |
| Empty orders placeholder | **Витрина** — «тут будут твои заказы» только без истории заказов; иначе «повторить» | [ТЗ](customer_tasks/Empty%20надпись%20тут%20будут%20твои%20заказы%20только%20без%20истории.md) · [`artifacts/cart_sheet_empty_orders_placeholder/`](../artifacts/cart_sheet_empty_orders_placeholder/README.md) | **GREEN `[x]`** 2026-07-24 · redeploy/MCP `[ ]` |
| Repeat remove global pay | **Витрина** — убрать общую «повторить в 1 клик» и «+ещё»; только pay на карточке | [ТЗ](customer_tasks/Убрать%20общую%20кнопку%20повтора%20и%20ещё.md) · [`artifacts/repeat_remove_global_pay_button/`](../artifacts/repeat_remove_global_pay_button/README.md) | **GREEN `[x]`** 2026-07-24 · redeploy/MCP `[ ]` |
| Default peek empty | **Витрина** — дефолт шторки peek; без истории текст «тут будут твои заказы» | [ТЗ](customer_tasks/Дефолт%20шторки%20peek%20и%20текст%20без%20истории.md) · [`artifacts/cart_sheet_default_peek_empty/`](../artifacts/cart_sheet_default_peek_empty/README.md) | **GREEN `[x]`** 2026-07-24 · redeploy/MCP `[ ]` |
| Peek repeat plus | **Витрина** — в peek «+» на карточке «повторить» добавляет в заказ | [ТЗ](customer_tasks/Peek%20плюс%20на%20повторе%20не%20добавляет%20в%20заказ.md) · [`artifacts/peek_repeat_plus_add_to_cart/`](../artifacts/peek_repeat_plus_add_to_cart/) | **GREEN `[x]`** 2026-07-24 · redeploy/MCP `[ ]` |
| Payment status model | **Эквайринг** — анализ статусной модели платежей/заказов (Т-Банк) | [ТЗ](customer_tasks/Анализ%20статусной%20модели%20платежей%20и%20заказов%20Т-Банк.md) · [`artifacts/payment_status_model_analysis/`](../artifacts/payment_status_model_analysis/) | **анализ `[x]`** 2026-07-24 · код не менялся |
| PWA durable sessions | **Витрина / PWA** — долговечные сессии + Silent Refresh (без авто-разлогина 24ч) | [ТЗ](customer_tasks/Долговечные%20сессии%20PWA%20и%20фикс%20авто-разлогина.md) · [`artifacts/pwa_durable_sessions_silent_refresh/`](../artifacts/pwa_durable_sessions_silent_refresh/) | **MCP PASS `[x]`** 2026-07-24 · Fly v389 · апрув заказчика `[ ]` |
| Phone OTP SMS/Flash Call | **Витрина / PWA** — вход и регистрация по телефону (SMS / Flash Call) + антиспам cooldown | [ТЗ](customer_tasks/Вход%20и%20регистрация%20по%20номеру%20телефона%20SMS%20Flash%20Call.md) · [`artifacts/phone_otp_sms_flash_call/`](../artifacts/phone_otp_sms_flash_call/) | **MCP PASS `[x]`** 2026-07-24 · Fly v390 · апрув заказчика `[ ]` |
| Profile Email↔Phone merge | **Витрина / PWA** — связка профилей Email↔Phone, merge без потери заказов/карт, UI профиля | [ТЗ](customer_tasks/Связка%20профилей%20Email%20Phone%20и%20управление%20данными%20пользователя%20в%20PWA.md) · [`artifacts/profile_email_phone_merge/`](../artifacts/profile_email_phone_merge/) | **MCP PASS `[x]`** 2026-07-27 · Fly v392 · апрув заказчика `[ ]` |
| Repeat order invalid token payment sheet | **Витрина** — повторный заказ при невалидном токене: CTA «Добавить карту», BottomSheet «Способ оплаты», inline-ошибки | [ТЗ](customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) · [`artifacts/repeat_order_invalid_token_payment_sheet/`](../artifacts/repeat_order_invalid_token_payment_sheet/) | **MCP PASS `[x]`** 2026-07-27 · Fly v393 · апрув заказчика `[ ]` |
| SBP Deep Link + card tokenization | **Эквайринг / PWA** — СБП deep link (`qr.nspk.ru`) + Recurrent/Charge токенизация карт без iframe Т-Банка (CODE:BLACK) | [ТЗ](customer_tasks/Интеграция%20оплаты%20СБП%20Deep%20Link%20и%20токенизации%20карт%20Т-Касса%20v2.md) · [`artifacts/sbp_deep_link_card_tokenization/`](../artifacts/sbp_deep_link_card_tokenization/) | **MCP Charge PASS `[x]`** 2026-08-03 · апрув `[ ]` |
| CODE:BLACK T-Kassa SBP PWA lifecycle | **Эквайринг / PWA** — ревизия: `codeblack_pending_order`, visibilitychange, cold start ≤15 мин, экран WAITING_FOR_BANK | [ТЗ](customer_tasks/Интеграция%20Т-Кассы%20СБП%20и%20токенизации%20в%20PWA%20CODE%20BLACK.md) · [`artifacts/codeblack_t_kassa_sbp_tokenization/`](../artifacts/codeblack_t_kassa_sbp_tokenization/) | **MCP PASS `[x]`** 2026-07-27 · Fly v395 · апрув `[ ]` |
| Auth funnel cascade Flash→Messenger→SMS | **Витрина / PWA** — 2-экранный wizard + каскад Flash Call×2 → Messenger → SMS (без Email/радио) | [ТЗ](customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20Messenger%20SMS.md) · [`artifacts/auth_funnel_cascade_flash_messenger_sms/`](../artifacts/auth_funnel_cascade_flash_messenger_sms/) | **MCP PASS `[x]`** 2026-07-28 · Fly v397 · апрув `[ ]` |
| Auth funnel cascade Flash Call×2 → SMS | **Витрина / PWA** — 2-экрановый wizard + каскад Flash Call×2 → СМС (без Email/радиоканалов) | [ТЗ](customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20x2%20SMS.md) · [`artifacts/auth_funnel_flash_call_x2_sms_ru/`](../artifacts/auth_funnel_flash_call_x2_sms_ru/) | **интейк `[x]`** 2026-07-29 · SPEC `[ ]` ждёт go |
| Repeat recommendations missing | **Витрина** — пропал блок «повторить»/рекомендации (залипание на Fly Overnight) | [ТЗ](customer_tasks/Пропали%20рекомендации%20повторить%20на%20витрине.md) · [`artifacts/repeat_recommendations_missing/`](../artifacts/repeat_recommendations_missing/) | **MCP PASS `[x]`** 2026-07-28 · Fly v399 · апрув `[ ]` |
| Aram phone restore | **Витрина / профиль** — настоящий `+79639124847` + merge оплат Point A | [ТЗ](customer_tasks/Вернуть%20номер%20телефона%20Арама%20в%20профиле.md) · [`artifacts/aram_phone_restore/`](../artifacts/aram_phone_restore/) | **prod link PASS `[x]`** 2026-07-28 · no deploy · апрув `[ ]` |
| T-Bank inline payment button | **Эквайринг / PWA** — inline-оплата без redirect + динамические статусы кнопки (Init/Charge/GetState/Confirm + polling) | [ТЗ](customer_tasks/Интеграция%20inline-оплаты%20Т-Банка%20с%20динамическими%20статусами%20внутри%20кнопки.md) · [`artifacts/tbank_inline_payment_button_statuses/`](../artifacts/tbank_inline_payment_button_statuses/) | **MCP SUCCESS `[x]`** 2026-08-03 · апрув `[ ]` |
| T-Kassa SBP Autopay AccountToken | **Эквайринг / PWA** — автоплатежи СБП: привязка счёта (`AccountToken`), Zero-Click `ChargeQr`, fallback при decline | [ТЗ](customer_tasks/Интеграция%20Автоплатежей%20СБП%20Т-Касса%20в%20PWA.md) · [`artifacts/tbank_sbp_autopayments_account_token/`](../artifacts/tbank_sbp_autopayments_account_token/) | **MCP Setup PASS `[x]`** 2026-08-03 · Zero-Click ждёт bind в банке · апрув `[ ]` |
| Order status compact sheet + Push | **Витрина / PWA + POS** — виджет статуса только во время готовки; hide on `ready` + Push; home + product card | [ТЗ](customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md) · [`artifacts/order_status_compact_sheet_push/`](../artifacts/order_status_compact_sheet_push/) | **rev intake+SPEC `[x]`** 2026-08-05 · RED/GREEN `[ ]` · скрины обновлены |
| Active orders accordion + receipt | **Витрина / PWA** — expanded-аккордеон активных заказов + текстовый чек (без кнопок в чеке) | [ТЗ](customer_tasks/Мульти-статусная%20шторка%20активных%20заказов%20с%20просмотром%20состава%20чека.md) · [`artifacts/active_orders_accordion_receipt/`](../artifacts/active_orders_accordion_receipt/) | **MCP PASS `[x]`** 2026-07-31 · Fly v415 · апрув `[ ]` |
| Status inside cart sheet | **Витрина / PWA** — блок статуса активных заказов **внутри** шторки корзины (не fixed-слой поверх) | [ТЗ](customer_tasks/Статус%20заказа%20внутри%20шторки%20корзины%20не%20слой%20поверх.md) · [`artifacts/status_inside_cart_sheet/`](../artifacts/status_inside_cart_sheet/) | **Fly v418 MCP PASS `[x]`** 2026-07-31 · апрув `[ ]` |
| Order status OS detect + Wallet/WebPush | **Витрина / PWA** — адаптивный нижний бар: детекция ОС → Apple Wallet (iOS) / FCM Push (Android/Desktop) + «Состав заказа» | [ТЗ](customer_tasks/Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md) · [`artifacts/order_status_os_detect_wallet_webpush/`](../artifacts/order_status_os_detect_wallet_webpush/) | **Fly v419 MCP PASS** 2026-08-03 · апрув заказчика `[ ]` |
| Background FCM progress + Apple Wallet | **Витрина / PWA** — обогащённый FCM (tag/actions/прогресс) + SW actions; `.pkpass` + APNs update; UI state machine карточки (макс. 2 CTA) | [ТЗ](customer_tasks/Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md) · [`artifacts/background_notifications_fcm_apple_wallet/`](../artifacts/background_notifications_fcm_apple_wallet/) | **Fly v421** · MCP **PASS** · [`mcp/fly_v421_2026-08-03/`](../artifacts/background_notifications_fcm_apple_wallet/mcp/fly_v421_2026-08-03/) |
| Order ready cascade WS→TG→SMS (v1) | **Витрина / уведомления** — v1: WS → Telegram → SMS.ru | [ТЗ v1](customer_tasks/Оптимизированный%20каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20Telegram%20SMS.md) · [`artifacts/…telegram_sms/`](../artifacts/order_ready_cascade_ws_telegram_sms/) | **SUPERSEDED** 2026-08-04 → v2 без TG |
| Order ready cascade WS/Push/Wallet→SMS | **Витрина / уведомления** — каскад «Заказ готов»: WS + FCM/Wallet → presence → SMS.ru (≤70); без Telegram; секреты `.env` | [ТЗ v2](customer_tasks/Каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20WebPush%20Apple%20Wallet%20SMS.md) · [`artifacts/order_ready_cascade_ws_push_sms/`](../artifacts/order_ready_cascade_ws_push_sms/) | **Fly v427 MCP SMS PASS** 2026-08-04 · апрув `[ ]` |
| T-Bank auto refund on PWA cancel | **Эквайринг / PWA** — автовозврат 100% через `/v2/Cancel` при отмене гостем (`pending_payment` / `accepted`); блок `preparing+` | [ТЗ](customer_tasks/Автоматический%20возврат%20платежа%20Т-Банк%20при%20отмене%20заказа%20в%20PWA.md) · [`artifacts/tbank_auto_refund_order_cancellation_pwa/`](../artifacts/tbank_auto_refund_order_cancellation_pwa/) · MCP [`fly_v428`](../artifacts/tbank_auto_refund_order_cancellation_pwa/mcp/fly_v428_2026-08-04/) | **Fly v428** · MCP **PASS** (pending+ready+accepted modal) 2026-08-05 · ждёт «ок» |
| Order action buttons status panel | **Витрина / PWA** — динамический блок CTA справа от progress bar (Отмена / Чат / Чаевые / Push|Wallet) по матрице статусов + WS | [ТЗ](customer_tasks/Динамический%20блок%20действий%20Action%20Buttons%20в%20статусной%20панели%20заказа.md) · [`artifacts/order_action_buttons_status_panel/`](../artifacts/order_action_buttons_status_panel/) | **закрыта `[x]`** апрув «ок» 2026-08-05 · Fly **v431** MCP chat+push+cancel PASS |
| Stuck orders sheet blocks payment | **Витрина + табло + УК** — зависшие заказы в шторке блокируют оплату; нет на табло баристы; разъезд payment statuses | [ТЗ](customer_tasks/Зависшие%20заказы%20в%20статусной%20шторке%20PWA%20блокируют%20оплату.md) · [`artifacts/stuck_orders_status_sheet_blocks_payment/`](../artifacts/stuck_orders_status_sheet_blocks_payment/) | **Fly v433 MCP PASS** 2026-08-05 · апрув `[ ]` |
| Repeat hidden by stale active orders | **Витрина / PWA** — после #42 нет «повторить» / кнопок на карточках / истории частот (June accepted → has_active_order) | [ТЗ](customer_tasks/После%2042%20пропали%20повторы%20в%20шторке%20и%20история%20покупок.md) · [`artifacts/repeat_hidden_by_stale_active_orders/`](../artifacts/repeat_hidden_by_stale_active_orders/) | **Fly v434 MCP PASS** 2026-08-06 · апрув `[ ]` |
| Aram one-click pay SSL + cards | **Эквайринг / PWA** — 1 клик у Арама: SSL НУЦ Минцифры + стабильные UserCards (?email) + Charge по карте | [ТЗ](customer_tasks/Оплата%20в%201%20клик%20у%20Арама%20падает%20после%20processing.md) · [`artifacts/aram_one_click_payment_ssl_mintcifry/`](../artifacts/aram_one_click_payment_ssl_mintcifry/) | **Fly v435 MCP PASS** 2026-08-06 · апрув `[ ]` |
| Product card peek cart | **Витрина / PWA** — на карточке товара видеть набранные позиции; peek: ±1 + horizontal scroll; CTA «добавить к заказу» | [ТЗ](customer_tasks/Карточка%20товара%20отображение%20набранных%20позиций%20и%20функциональность%20в%20режиме%20peek.md) · [`artifacts/product_card_peek_cart/`](../artifacts/product_card_peek_cart/) | **reopen intake `[x]`** 2026-08-06 · код волны 2026-07-10 · SPEC/MCP `[ ]` |

> **B1.8 (не забыть):** сейчас письма с **подтверждённого личного sender** в Brevo. Когда будет **свой домен** — завести **кофейную почту** (напр. `noreply@бренд.ru`), аутентифицировать домен в Brevo, обновить `MAIL_FROM` + secrets. Код OTP/ActionMailer менять не нужно.

---

## Задачи заказчика (полные ТЗ — отдельные файлы)

Оглавление: [`customer_tasks/README.md`](customer_tasks/README.md). Тексты заказчика **не сокращаем** в CBR — только ссылки и статус.

| Порядок | ID | Задача | Статус | Файл |
|---------|-----|--------|--------|------|
| 1 | **B1.7** | Доработка экрана оформления (checkout) | **закрыта** · апрув `[x]` 2026-06-04 | [B1_7_checkout_order_screen.md](customer_tasks/B1_7_checkout_order_screen.md) |
| 2 | **B1.1** | Экран уведомления заказа + прогресс-бар | **`[x]`** 2026-06-10 · Fly + FCM | [B1_1_order_status_progress.md](customer_tasks/B1_1_order_status_progress.md) |
| 3 | **B2.1** | Табло бариста — интерактивная карточка | **закрыта** · апрув `[x]` 2026-06-18 · B2-S1 CLOSED OPS | [B2_1_barista_order_board.md](customer_tasks/B2_1_barista_order_board.md) |
| 4 | **B2.2** | Меню + Создать (бариста) | **ТЗ** · реализация `[ ]` | [B2_2_barista_menu_create_merge.md](customer_tasks/B2_2_barista_menu_create_merge.md) |
| 5 | **B1.4** | PWA витрины (install + offline) | **закрыта** · апрув `[x]` 2026-07-05 | [B1_4_pwa_shop.md](customer_tasks/B1_4_pwa_shop.md) |
| 6 | **B1.10** | Убрать «Блог» из навигации витрины | **закрыта** · апрув `[x]` 2026-06-18 | [B1_10_remove_blog_nav.md](customer_tasks/B1_10_remove_blog_nav.md) |
| 7 | **B1.9** | Toggle-модификаторы на карточке товара | **закрыта** · апрув `[x]` 2026-06-18 | [B1_9_product_modifier_toggle.md](customer_tasks/B1_9_product_modifier_toggle.md) |
| 8 | **B1.11** | Режим работы точек продаж (УК) | **закрыта** · апрув `[x]` 2026-07-05 | [B1_11_tenant_operating_hours.md](customer_tasks/B1_11_tenant_operating_hours.md) |
| 10 | **B1.13** | Новая навигация витрины — S1–S4 (шапка + поп-ап корзины) | **rev2** `[x]` апрув 2026-07-01 · **S4-канон** docs `[x]` · **S4 код** `[ ]` | [B1_13_shop_nav_profile_header.md](customer_tasks/B1_13_shop_nav_profile_header.md) |
| 11 | **B1.14** | Адрес точки + выбор точки в шапке витрины | **клиент закрыт** · апрув 2026-07-05 · Cart `[ ]` | [B1_14_shop_tenant_address_header.md](customer_tasks/B1_14_shop_tenant_address_header.md) |
| 12 | **Hidden mode cards** | Режим hidden — crop превью карточек товаров | **SBR REVIEW `[x]`** · код `[x]` · апрув `[ ]` | [Исправление режима отображения Hidden…](customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md) |
| 13 | **Bottom sheet expanded grid** | Expanded до 1-го ряда каталога + сетка товаров 4 в ряд со скроллом | **закрыта `[x]`** 2026-07-21 · UX принят как канон · deploy `[ ]` | [Bottom Sheet expanded mode и внутренняя сетка 4 в ряд.md](customer_tasks/Bottom%20Sheet%20expanded%20mode%20и%20внутренняя%20сетка%204%20в%20ряд.md) |
| 14 | **Quick Repeat Bottom Sheet** | Быстрый повтор частых покупок — секция «повторить», peek/expanded/hidden, «в 1 клик»; скрывать при активном заказе; status sheet full-width | **Fly v416 MCP PASS `[x]`** 2026-07-31 · апрув `[ ]` | [Быстрый повтор частых покупок Quick Repeat Bottom Sheet.md](customer_tasks/Быстрый%20повтор%20частых%20покупок%20Quick%20Repeat%20Bottom%20Sheet.md) |
| 15 | **Cart sheet gesture hit area** | Свайп шторки — вся полоса-прямоугольник чувствительна | **MCP PASS `[x]`** · апрув `[ ]` | [Чувствительность свайпа шторки hit area прямоугольник.md](customer_tasks/Чувствительность%20свайпа%20шторки%20hit%20area%20прямоугольник.md) |
| 16 | **Expanded no catalog grid** | Expanded шторка — без сетки каталога, только список заказов | **GREEN `[x]`** · redeploy/MCP `[ ]` | [Убрать сетку товаров из expanded шторки.md](customer_tasks/Убрать%20сетку%20товаров%20из%20expanded%20шторки.md) |
| 17 | **Cart sheet remove undo** | Убрать кнопку «Отменить» в шторке корзины | **GREEN `[x]`** · redeploy/MCP `[ ]` | [Убрать кнопку Отменить в шторке корзины.md](customer_tasks/Убрать%20кнопку%20Отменить%20в%20шторке%20корзины.md) |
| 18 | **Empty orders placeholder** | «тут будут твои заказы» только без истории | **GREEN `[x]`** · redeploy/MCP `[ ]` | [Empty надпись…](customer_tasks/Empty%20надпись%20тут%20будут%20твои%20заказы%20только%20без%20истории.md) |
| 19 | **Repeat remove global pay** | Убрать общую «повторить в 1 клик» и «+ещё» | **GREEN `[x]`** · redeploy/MCP `[ ]` | [Убрать общую кнопку повтора и ещё.md](customer_tasks/Убрать%20общую%20кнопку%20повтора%20и%20ещё.md) |
| 20 | **Default peek empty** | Дефолт peek + текст без истории | **GREEN `[x]`** · redeploy/MCP `[ ]` | [Дефолт шторки peek…](customer_tasks/Дефолт%20шторки%20peek%20и%20текст%20без%20истории.md) |
| 21 | **Peek repeat plus** | Peek: «+» на повторе → в заказ | **GREEN `[x]`** · redeploy/MCP `[ ]` | [Peek плюс на повторе…](customer_tasks/Peek%20плюс%20на%20повторе%20не%20добавляет%20в%20заказ.md) |
| 22 | **Payment status model** | Анализ статусной модели платежей/заказов (Т-Банк) | **анализ `[x]`** 2026-07-24 | [Анализ статусной модели…](customer_tasks/Анализ%20статусной%20модели%20платежей%20и%20заказов%20Т-Банк.md) |
| 23 | **PWA durable sessions** | Долговечные сессии PWA + Silent Refresh | **MCP PASS `[x]`** 2026-07-24 · Fly v389 | [Долговечные сессии PWA…](customer_tasks/Долговечные%20сессии%20PWA%20и%20фикс%20авто-разлогина.md) |
| 24 | **Phone OTP SMS/Flash Call** | Вход/регистрация по телефону (SMS / Flash Call) + cooldown | **MCP PASS `[x]`** 2026-07-24 · Fly v390 | [Вход и регистрация по номеру телефона…](customer_tasks/Вход%20и%20регистрация%20по%20номеру%20телефона%20SMS%20Flash%20Call.md) |
| 25 | **Profile Email↔Phone merge** | Связка Email↔Phone, soft-merge, UI профиля / автозаполнение checkout | **MCP PASS `[x]`** 2026-07-27 · Fly v392 | [Связка профилей Email Phone…](customer_tasks/Связка%20профилей%20Email%20Phone%20и%20управление%20данными%20пользователя%20в%20PWA.md) |
| 26 | **Repeat order invalid token payment sheet** | Peek повтор: CTA «Добавить карту» + BottomSheet способов оплаты при invalid token | **MCP PASS `[x]`** 2026-07-27 · Fly v393 | [Главный экран — повторный заказ…](customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) |
| 27 | **SBP Deep Link + card tokenization** | СБП deep link + Recurrent/Charge (Т-Касса v2), без iframe, CODE:BLACK | **MCP Charge PASS `[x]`** 2026-08-03 · апрув `[ ]` | [Интеграция оплаты СБП Deep Link…](customer_tasks/Интеграция%20оплаты%20СБП%20Deep%20Link%20и%20токенизации%20карт%20Т-Касса%20v2.md) |
| 28 | **CODE:BLACK T-Kassa SBP PWA lifecycle** | Ревизия ТЗ: pending order LS + visibilitychange + WAITING_FOR_BANK | **MCP PASS `[x]`** 2026-07-27 · Fly v395 · апрув `[ ]` | [Интеграция Т-Кассы СБП…](customer_tasks/Интеграция%20Т-Кассы%20СБП%20и%20токенизации%20в%20PWA%20CODE%20BLACK.md) |
| 29 | **Auth funnel cascade** | 2-экранный wizard авторизации: Flash Call×2 → Messenger → SMS | **MCP PASS `[x]`** 2026-07-28 · Fly v397 | [Рефакторинг воронки авторизации…](customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20Messenger%20SMS.md) |
| 30 | **Repeat recommendations missing** | Пропал блок «повторить» на витрине (Fly Overnight) | **MCP PASS `[x]`** 2026-07-28 · Fly v399 | [Пропали рекомендации…](customer_tasks/Пропали%20рекомендации%20повторить%20на%20витрине.md) |
| 31 | **Aram phone restore** | Настоящий `+79639124847` + merge donor оплат | **prod link PASS `[x]`** 2026-07-28 · no deploy | [Вернуть номер телефона Арама…](customer_tasks/Вернуть%20номер%20телефона%20Арама%20в%20профиле.md) |
| 32 | **T-Bank inline payment button** | Inline-оплата без redirect + state machine кнопки (Init/Charge/Confirm + polling) | **MCP SUCCESS `[x]`** 2026-08-03 · апрув `[ ]` | [Интеграция inline-оплаты Т-Банка…](customer_tasks/Интеграция%20inline-оплаты%20Т-Банка%20с%20динамическими%20статусами%20внутри%20кнопки.md) |
| 33 | **T-Kassa Widget One-Click + Fallback** | Виджет Т-Кассы SDK (connection_type: Widget) + One-Click + fallback СБП/карта при отказе | **MCP Charge PASS `[x]`** 2026-08-03 · апрув `[ ]` | [Интеграция виджета быстрой оплаты…](customer_tasks/Интеграция%20виджета%20быстрой%20оплаты%20Т-Кассы%20и%20One-Click%20сценария%20в%20PWA.md) |
| 34 | **T-Kassa SBP Autopay AccountToken** | Автоплатежи СБП: Setup + webhook `AccountToken` + Zero-Click `ChargeQr` + fallback | **MCP Setup PASS `[x]`** 2026-08-03 · Zero-Click ждёт банк · апрув `[ ]` | [Интеграция Автоплатежей СБП…](customer_tasks/Интеграция%20Автоплатежей%20СБП%20Т-Касса%20в%20PWA.md) |
| 35 | **Order status compact sheet + Push** | Виджет только accepted/paid/preparing; hide on ready; home + product; Push ready | **rev SPEC `[x]`** 2026-08-05 · v414 baseline · RED `[ ]` | [Интеграция статусной модели…](customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md) |
| 36 | **Active orders accordion + receipt** | Expanded-аккордеон + текстовый чек (items/mods/totals); без кнопок в чеке | **MCP PASS `[x]`** 2026-07-31 · Fly v415 | [Мульти-статусная шторка…](customer_tasks/Мульти-статусная%20шторка%20активных%20заказов%20с%20просмотром%20состава%20чека.md) |
| 37 | **Order status OS detect + Wallet/WebPush** | Нижний бар статуса: `getDeviceOS` → Wallet (iOS) / FCM Push (Android/Desktop) + чек «Состав заказа» | **Fly v419 MCP PASS** 2026-08-03 · апрув заказчика `[ ]` | [Адаптивный виджет статуса…](customer_tasks/Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md) |
| 38 | **Background FCM progress + Apple Wallet** | FCM tag/actions/прогресс + SW; `.pkpass` + APNs update; PWA UI state machine (макс. 2 CTA); без правок Barista status | **Fly v421** · MCP **PASS** (Aram) | [Фоновые уведомления прогресс-бар…](customer_tasks/Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md) |
| 39 | **Order ready cascade WS/Push/Wallet→SMS** (v2) | Каскад «Заказ готов»: WS + FCM/Wallet → presence → SMS.ru (≤70); **без Telegram**; Solid Queue; секреты `.env`. v1 TG superseded. | **Fly v427 MCP SMS PASS** 2026-08-04 · апрув `[ ]` | [Каскад уведомлений Заказ готов… SMS.md](customer_tasks/Каскад%20уведомлений%20Заказ%20готов%20PWA%20WS%20Push%20WebPush%20Apple%20Wallet%20SMS.md) |
| 40 | **T-Bank auto refund on PWA cancel** | Автовозврат 100% через Т-Банк `/v2/Cancel` при отмене гостем в PWA (`pending_payment` локально; `accepted` + `succeeded` → refund); блок `preparing`/`ready`/`issued` | **Fly v428** · MCP **PASS** (incl. accepted modal) 2026-08-05 · ждёт «ок» | [Автоматический возврат платежа Т-Банк…](customer_tasks/Автоматический%20возврат%20платежа%20Т-Банк%20при%20отмене%20заказа%20в%20PWA.md) · [MCP v428](../artifacts/tbank_auto_refund_order_cancellation_pwa/mcp/fly_v428_2026-08-04/) |
| 41 | **Order action buttons status panel** | Динамический блок CTA справа от progress bar: матрица Отмена/Чат/Чаевые/Push|Wallet; адаптеры чата и нетмонет; WS-реактивность; cancel flow | **закрыта `[x]`** апрув «ок» 2026-08-05 · Fly **v429** · MCP chat+push PASS | [Динамический блок действий Action Buttons…](customer_tasks/Динамический%20блок%20действий%20Action%20Buttons%20в%20статусной%20панели%20заказа.md) · [artifacts](../artifacts/order_action_buttons_status_panel/) · [mcp/fly_v429…](../artifacts/order_action_buttons_status_panel/mcp/fly_v429_2026-08-05/) |
| 42 | **Stuck orders sheet blocks payment** | Зависшие accepted в шторке #35 перекрывают оплату; нет на табло; payment processing vs succeeded; фильтр shift_manager пуст | **Fly v433 MCP PASS** 2026-08-05 · апрув `[ ]` | [Зависшие заказы…](customer_tasks/Зависшие%20заказы%20в%20статусной%20шторке%20PWA%20блокируют%20оплату.md) · [artifacts](../artifacts/stuck_orders_status_sheet_blocks_payment/) |
| 43 | **Repeat hidden by stale active orders** | После #42: нет повторов в шторке, нет кнопки на карточке повтора, «история покупок» не грузится | **Fly v434 MCP PASS** 2026-08-06 · апрув `[ ]` | [После 42 пропали повторы…](customer_tasks/После%2042%20пропали%20повторы%20в%20шторке%20и%20история%20покупок.md) · [artifacts](../artifacts/repeat_hidden_by_stale_active_orders/) |
| 44 | **Product card peek cart** | Карточка товара: индикатор «уже в заказе»; peek ±1 + horizontal scroll; CTA «добавить к заказу» | **reopen intake `[x]`** 2026-08-06 · код 2026-07-10 · SPEC/RED/GREEN/MCP `[ ]` | [Карточка товара отображение…](customer_tasks/Карточка%20товара%20отображение%20набранных%20позиций%20и%20функциональность%20в%20режиме%20peek.md) · [artifacts](../artifacts/product_card_peek_cart/) |
| 45 | **Aram one-click pay SSL + cards** | Оплата в 1 клик у Арама: processing → ничего; карты то есть то нет; RebillId/Charge | **Fly v435 MCP PASS** 2026-08-06 · апрув `[ ]` | [Оплата в 1 клик у Арама…](customer_tasks/Оплата%20в%201%20клик%20у%20Арама%20падает%20после%20processing.md) · [artifacts](../artifacts/aram_one_click_payment_ssl_mintcifry/) |

---

## Сводка статусов по потокам (быстрый взгляд)

| Поток | Готово | Открыто |
|-------|--------|---------|
| **2 Обработка** | 2A.1–2A.4 (УК) · **B2.1** `[x]` · **B2-S1 звук** | B2.2 · backlog B2.1 фаза 2 |
| **3 Тест-приёмка** | — | Happy path витрина→табло→уведомления; отказы на всех экранах; изоляция точек |

---

## Сводка: три направления заказчика *(legacy-таблица — см. «Три потока» выше)*

| № | Направление | Канал / UI | Статус |
|---|-------------|------------|--------|
| **1** | Приём заказа | витрина (mobile first) → app → kiosk | **§2.3 + W1.1–W1.5 `[x]`** · backlog B1.* |
| **2** | Обработка заказа | Табло баристы + УК | **2A** `[x]` **PASS** → **2** табло `[ ]` |
| **3** | Тест-приёмка | Сквозной прогон + отказы | `[ ]` |

---

## Блок 1 — приём заказа (legacy; актуальный backlog → **B1.*** выше)

| Пункт | Суть | Статус |
|-------|------|--------|
| 1.1 | ТТК, фото, модификаторы в УК + туториал | open → **B1.5** |
| 1.2 | Боевые оплаты | **done** *(§2.3, W1.5)* |
| 1.3 | Меню = витрина = касса бариста, цены по точкам | **done** *(W1.1–W1.4)* |
| 1.4–1.6 | Табло, модификаторы, терминал на кассе | open → **блок 2** |
| 1.7–1.8 | Уведомления, онбординг | B1.1 **`[x]`**; табло → **B2.1** |
| 1.9 | Оплата без полного экрана банка | **done** *(§2.3)* |

---

## §2.3 Учебная оплата — требование заказчика (2026-06)

**PDF:** §2.3–2.4, комментарии заказчика после прогонки.

| Шаг PDF | Ожидание | Комментарий заказчика |
|---------|----------|------------------------|
| 1 | «Оплатить» думает, нельзя жать 10 раз | Кнопка **неактивна** без ФИО и доп. инфо |
| 2 | Успех, заказ принят | «Поротестить во время оплаты» |
| 3 | Заказ в истории за сегодня | «Поротестить во время оплаты» |
| — | — | Нет стрелки назад на **экране банка** (UI Т-Банка) |
| — | — | **Баг:** после банка → оформление → корзина → заказ **не виден**, только после возврата на **карточку товара** |
| — | — | Перебрать экран, логику, **регистрацию один раз** |

**Код (ориентиры):** `Checkout.svelte` (`disabled={!name \|\| !phone}`), `PaymentResult.svelte`, `Shop::OrderCreator`, `TbankAdapter`, webhook `Payments::TbankCallbackJob`.

**T-Bank iframe (этап 4):** [Платежная форма в iframe](https://developer.tbank.ru/eacq/intro/developer/setup_js/setup_iframe) — `integrationjs.tbank.ru`, Init на **бэкенде**, `status.changedCallback` → наши статусы.

---

## Чеклист §2.3 — этапы 1–5 (работаем по порядку)

Статусы: `[ ]` open · `[~]` in_progress · `[x]` done + MCP JSON · `[—]` wontfix / вне scope

### Этап 1 — Проверить «уже есть» (MCP, без кода)

| # | Критерий | MCP / код | Статус | Артефакт |
|---|----------|-----------|--------|----------|
| 1.1 | Кнопка «Оплатить» **неактивна** без имени и телефона | `Checkout.svelte:139`; MCP 2026-06-04 | `[x]` **PASS** | [`mcp_section_2_3_stage1_rerun_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_3_stage1_rerun_2026-06-04.json) |
| 1.2 | После нажатия → **«Идёт оплата…»**, редирект на Т-Банк | MCP 2026-06-04 | `[x]` **PASS** | тот же + `screenshots/stage1_1_2_tbank_*.png` |
| 1.3 | **Двойной клик** — один заказ (§2.4) | UI disabled + 1 redirect | `[x]` **PASS** *(UI)* | тот же; БД — см. [`mcp_section_2_4_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_4_fly_2026-06-04.json) |
| 1.4 | **Возврат с банка без оплаты** — корзина **не пустая** | MCP 2026-06-04 | `[x]` **PASS** | `screenshots/stage1_1_4_cart_after_bank_*.png` |

> **2026-06-04 перепроверка:** deploy `deployment-01KT8ZPWJ82E8YMM8TZMK5K01V`, chrome-devtools-mcp, **код не меняли** — всё PASS. Жалоба заказчика на UX **после** банка → **этап 2**.

---

### Этап 2 — Баг: заказ не виден после банка (код + MCP)

| # | Критерий | Статус | Примечание |
|---|----------|--------|------------|
| 2.1 | После банка (fail/back) → **«Заказы»** / история — заказ **виден** (хотя бы `pending_payment` / `cancelled`) | `[x]` **PASS** | reconnect_token + `/session/reconnect` |
| 2.2 | Корзина / оформление — **согласованное** состояние после возврата | `[x]` **PASS** | корзина 179₽ после abandon |
| 2.3 | MCP полный сценарий банк → назад → корзина → заказы | `[x]` **PASS** | [`mcp_section_2_3_stage2_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_3_stage2_2026-06-04.json) |

> **2026-06-04:** deploy `01KTC026K62C7QHT6JC3VRKNRS`. Код: `GuestOrderReconnect`, `shopGuestSession.js`, правки Checkout/PaymentResult/Orders/App.

---

### Этап 3 — Экран оформления (код + MCP)

| # | Критерий | Статус |
|---|----------|--------|
| 3.1 | Один путь: **корзина → оформление → оплата → результат → история** | `[x]` **PASS** |
| 3.2 | **Назад** без потери корзины / заказа | `[x]` **PASS** |
| 3.3 | **Регистрация один раз:** имя + телефон в localStorage, второй заказ — блок «Контакты» | `[x]` **PASS** |
| 3.4 | MCP: **второй заказ** тем же гостем на Fly | `[x]` **PASS** |

> **2026-06-04:** `shopGuestProfile.js`, deploy post-7412de7. MCP: [`mcp_section_2_3_stage3_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_3_stage3_2026-06-04.json). **Не сделано:** почта; полный bank-redirect в MCP-automation.

---

### Этап 4 — Оплата как хочет заказчик (частично)

| # | Критерий | Статус | Примечание |
|---|----------|--------|------------|
| 4.1 | Наш экран: **Идёт оплата / успех / ошибка / отмена** | `[x]` **PASS** | `Payment.svelte`, `PaymentResult` |
| 4.2 | **T-Bank iframe** (`integration.js`, CSP) | `[x]` **PASS** | CoffeeOS-оболочка + маска T-Pay/SberPay; `setTheme(dark)`; скрин [`stage4_payment_shell_paying_2026-06-06.png`](artifacts/demo-feedback/screenshots/stage4_payment_shell_paying_2026-06-06.png) |
| 4.3 | **СБП** — deep link / QR | `[x]` **PASS** *(код)* | `deepLinkRedirectCallback`; ручной SBP — этап 5 |
| 4.4 | Своя кнопка **«Отмена»** | `[x]` **PASS** | `/payment` → abandon |
| 4.5 | Fail/отказ → **менеджер/УК** (журнал) | `[x]` **PASS** | `Shop::PaymentFailureJournal` → `OrderStatusLog` + `AdminAuditLog`; менеджер `/manager/incidents`; УК `/health/tenants` → `checks.failed_payments.recent_events` |

> **2026-06-06 (5.2):** `fly:stage5_2_smoke` — order `72801b25-…` в history today (`accepted`, 179₽). MCP: [`mcp_section_2_3_stage5_2_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_2_2026-06-06.json).

> **2026-06-06 (5.1):** `fly:callback_smoke` — order `05c99c7e-…` → `accepted`; интеграционный тест `qa_section_2_3_stage5_e2e_test.rb`. MCP: [`mcp_section_2_3_stage5_1_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_1_2026-06-06.json).

> **2026-06-06 (deploy апрув):** `01KTE1S9XJ4ASQND4RY885J84R` — этап 4 целиком на Fly, готовы к этапу 5.

> **2026-06-06 (4.5):** commit `1c7809e` — журнал отказов оплаты: abandon / fail URL / webhook REJECTED.

> **2026-06-06 (shell):** commit `7a0533c`, deploy `01KTE0P9PZSVF3YNJYEMC1DVXX` — оболочка CoffeeOS на `/payment`, маска жёлтых кнопок банка.

> **2026-06-06:** deploy `01KTDZYTAVDCSJNWKEFF86D2E4`, commit `5829f09`. MCP: [`mcp_section_2_3_stage4_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage4_2026-06-06.json). **4.2 PASS** — форма T-Bank в iframe на `/payment`.

> **2026-06-05:** deploy `01KTDZ0609R0DFVNCMK1AYV3N5`, commit `ebd5b31`. MCP: [`mcp_section_2_3_stage4_2026-06-05.json`](artifacts/demo-feedback/mcp_section_2_3_stage4_2026-06-05.json).

**Долг — приёмка заказчиком (этап 4, UI оплаты):** `[x]` **апрув 2026-06-06** (см. «Закрытие §2.3»)

---

### Этап 5 — Полная приёмка §2.3

| # | Критерий | Статус |
|---|----------|--------|
| 5.1 | **Тестовая/боевая оплата** до конца → webhook → `accepted` | `[x]` **PASS** |
| 5.2 | Заказ в **«Заказы за сегодня»** на витрине | `[x]` **PASS** |
| 5.3 | MCP + JSON → сводка §2.3, sync [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) | `[x]` **PASS** |

> **2026-06-06 (5.3 закрыт):** апрув заказчика; MCP inventory [`mcp_section_2_3_stage5_3_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json); retest Fly smoke PASS.

> **2026-06-06 (5.3 сводка):** [`mcp_section_2_3_summary_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_summary_2026-06-06.json).

**После этапа 5:** контент (фото, модификаторы в УК), ОФД/чек на почту, rebill карты — **отдельные пункты**, не блокируют закрытие §2.3.

---

## Итог §2.3 — **закрыто** (апрув заказчика 2026-06-06)

**Апрув:** «всё норм, если что позже вернётся». **Deploy:** `deployment-01KTE3QZ9XNPXM62HZD5C01JB6`

### Что работает (техпрогон PASS)

| PDF / жалоба | Результат |
|--------------|-----------|
| Кнопка «Оплатить» без ФИО/телефона | Неактивна |
| Двойной клик «Оплатить» | Один заказ, кнопка disabled |
| Возврат с банка без оплаты | Корзина сохранена |
| **Баг:** заказ не виден после банка | Исправлен: `reconnect_token` + «Заказы» |
| Путь корзина → оформление → оплата → результат → история | Единый UX, localStorage контактов |
| T-Bank **iframe** на нашей странице `/payment` | Оболочка CoffeeOS, маска T-Pay/SberPay, тёмная тема |
| Отмена / fail / abandon | Журнал у менеджера и УК |
| **Шаг 2 PDF:** успех оплаты → `accepted` | Webhook CONFIRMED → заказ принят (smoke + тест) |
| **Шаг 3 PDF:** заказ в «Заказы за сегодня» | API + smoke: `accepted`, 179₽ |

### Осознанные ограничения (не баг)

| Тема | Факт |
|------|------|
| Логотип/поля внутри iframe | UI Т-Банка (PCI); 100% свой экран — без iframe, отдельная задача |
| Стрелка «назад» на экране банка | UI Т-Банка, не контролируем |
| Тестовая карта на prod-терминале | `ACTIVATION_ERROR`; цепочку подтвердили signed webhook |
| SBP QR / deep link | Код есть; ручной прогон на Fly — не делали |
| Чек на почту / ОФД | Вне §2.3 |

### Апрув

- **2026-06-06:** заказчик — ок по итогу §2.3 (UI оплаты + цепочка).
- Правки возможны позже — отдельными задачами, §2.3 **не переоткрываем** без явного запроса.

**Артефакты:** [`mcp_section_2_3_summary_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_summary_2026-06-06.json) · [`mcp_section_2_3_stage5_3_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json)

---

## Закрытие §2.3

| Поле | Значение |
|------|----------|
| **Статус** | `[x]` **закрыто** — апрув заказчика 2026-06-06 |
| Этапы 1–5 | PASS (MCP + smoke + тест) |
| Этап 5.3 | [`mcp_section_2_3_stage5_3_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json) |
| **Следующий блок** | **Блок 2** — табло баристы (2A закрыт 2026-06-06) |

---

## Блок 2A — УК / platform: мониторинг и разбор инцидентов

**Зачем:** перед табло баристы — чтобы УК **видела** что происходит на точках и могла **воспроизвести** проблему по пользователю/оплате.

| # | Пункт | Что делаем простыми словами | Статус |
|---|-------|----------------------------|--------|
| 2A.1 | **Мониторинг точек** | UI `/admin/monitoring` — сводка всех точек + drill-down; JSON `/health/tenants`. Checks: касса, заказы, очередь, **pending_payment**, **витрина**, оплаты, отказы | `[x]` **PASS** 2026-06-06 |
| 2A.2 | **Журнал событий** | Детали под каждой проверкой + **единая лента** 24ч; JSON events для ИИ-агента | `[x]` **PASS** 2026-06-06 |
| 2A.3 | **Логин / user ID / сессии точки** | user id в nav; audit login/logout; `/admin/session` (своя); **`/admin/monitoring/:id/sessions`** — кто онлайн, все пользователи + последний вход, сводка ролей, чужие сессии с ▸ JSON; `Auth::SessionTracker` → таблица `sessions` | `[x]` **PASS** 2026-06-06 |
| 2A.4 | **Транзакции** | **`/admin/monitoring/:id/transactions`** — список платежей 24ч: сумма, статус, заказ, T-Bank PaymentId, фильтры, ▸ JSON; JSON `/health/tenants/:id/transactions` | `[x]` **PASS** 2026-06-06 |

> **Порядок:** 2A.1 → 2A.2 → 2A.3 → 2A.4 → **Блок 2** (табло баристы).

---

## Блок 2 — обработка заказа (табло баристы)

- **Web** `/barista` (Rails + Hotwire) — MVP; Flutter/TV — позже.
- **ТЗ:** [B2_1_barista_order_board.md](customer_tasks/B2_1_barista_order_board.md) · [B2_2](customer_tasks/B2_2_barista_menu_create_merge.md).
- **B2-S1 (звук):** **CLOSED OPS** 2026-06-17 — § B2-S1 в B2_1 · MCP 9/9 · без изменений бэкенда заказов.
- Цепочка MVP: **витрина (карта)** → табло → WS/push гостю (B1.1).
- Кухня / prep_kitchen / PWA / брак-переделка — **фаза 2 (конец) или фаза 3**.
- **Статус:** B2.1 **закрыта** апрув 2026-06-18 · B2-S1 **done** ops · B2.2 ТЗ `[x]` · код B2.2 `[ ]`.

### Блок 2 — backlog (вне апрува B2.1, 2026-06-18)

| # | Пункт | Приоритет |
|---|-------|-----------|
| B2.1-b1 | Брак / переделка / возврат на карточке | средний |
| B2.1-b2 | `defect_reasons` — справочник причин | средний |
| B2.1-b3 | Звук при отмене заказа | низкий |
| B2.1-b4 | Черновик акта списания при подтверждении отмены | средний |
| B2.1-b5 | Отдельные планшеты кухни / `prep_kitchen` | низкий |
| B2.1-b6 | Эскалация неподтверждённой отмены (5 мин → менеджер) | низкий |

ТЗ-якорь: [B2_1_barista_order_board.md](customer_tasks/B2_1_barista_order_board.md) § Бэклог.

---

## Блок 3 — уведомления и обратная связь гостю *(часть потока 1, не поток 3)*

- Статусная модель витрина + TV; push; чек на почту (ОФД).
- **Статус:** `[ ]` не начато.
- **Сквозная приёмка** — см. [«Три потока»](#три-потока-продукта-канон--общими-мазками) поток **3**.

---

## PDF «Прогонка» — карта разделов

| PDF | Тема | Где в работе |
|-----|------|----------------|
| §1 | Сеть, смена, склад | DEMO_FEEDBACK done; §1.4 сценарий «цех» — продуктово misleading |
| §2 | Витрина | **§2.3 done** — блок 2 (табло) |
| §3 | УК | 3.5 done (handoff); журнал оплат — open |
| §4–§8 | Менеджер, бариста, цех | prog10 ops; не в DEMO_FEEDBACK построчно |

---

## Известные расхождения (честно)

| Тема | Факт |
|------|------|
| **§2.3 закрытие** | **Done** 2026-06-06 — апрув заказчика, MCP [`mcp_section_2_3_stage5_3_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json) |
| `DEMO_FEEDBACK` «всё done» | Закрыты **выборочные** строки §1–3; §2.3 — отдельный чеклист в CBR |
| Баг «удаление заказа с экранов» (витрина B, PDF) | **Не в DEMO_FEEDBACK** — завести при воспроизведении |
| Баг после банка (заказ не виден) | **Исправлен** — этап 2, reconnect |

---

## Статус документа

| Поле | Значение |
|------|----------|
| Версия | 2026-06-06, **§2.3 + 2A + волна 4 W1.1–W1.4 закрыты** |
| **Следующий шаг** | **Блок 2** — табло баристы |
| Закрытие §2.3 | `[x]` апрув 2026-06-06 |
| Этап 5.3 | [`mcp_section_2_3_stage5_3_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json) |
| Точка входа ops | этот файл → [`SESSION_STATE.md`](../../session/SESSION_STATE.md) |
