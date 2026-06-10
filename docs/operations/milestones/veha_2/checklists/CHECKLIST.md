# Веха 2 — чеклист закрытия «Scale & Stability»

**Цель:** сеть точек **из коробки**, реальная оплата на клиентских каналах, киоск, связные админки.

**Статус вехи:** **в работе** (доки и разработка с 2026-05-25). В1 официально может быть ещё открыта — не писать «В2 закрыта», пока § I ниже не `[x]`.

**Не входит в В2:** полный Event Sourcing склада, Z-отчёт, supply chain, анти-фрод алерты — **Веха 3** (`development_roadmap.md`).

**Как пользоваться:** `[x]` по мере готовности; ⭐ = критично для «веха закрыта». Детали онбординга — [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md). Правки UI — [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md).

**Связанные:** [`README.md`](README.md), [`PRACTICES.md`](PRACTICES.md), [`artifacts/README.md`](artifacts/README.md) (прогон 10 → `artifacts/prog10/`), `docs/product/development_roadmap.md`.

**Три потока + траектория:** [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](../requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md) — канон потоков 1–3, волны 0–5, **северная звезда = PDF 56 стр.**

### Gate: чеклист ↔ таск-трекер

- **Новый канал заказа** → сначала [`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md), потом код.
- **Done в трекере** не раньше `[x]` здесь (или явный перенос в § I с датой).

---

## A. Онбординг «из коробки» (приоритет 1)

См. детальный список: [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md).

- [x] ⭐ УК: org + N точек (slug, **address**, city, модули) — транзакция + `TenantOnboarding::Provision` *(§1–§3 ONBOARDING_CHECKLIST — [x])*
- [x] ⭐ Карточка точки в УК: **все входы** (витрина/киоск URL, панели, кого создать) — см. [`ONBOARDING.md`](ONBOARDING.md) *(2026-05-26)*
- [x] ⭐ Поле `address` в форме точки (`tenants.address` уже в БД) *(2026-05-26)*
- [x] ⭐ После создания — каталог PTS без ручного `demo:seed` (кроме демо-стенда) — `tenants_controller_test.rb#create provisions PTS`
- [x] ⭐ Staff на точку: документированный путь — [`STAFF_ACCESS.md`](STAFF_ACCESS.md); код/UX по чеклисту онбординга *(§5 ONBOARDING 2026-05-26)*
- [x] QA: негативный откат онбординга при ошибке Provision — `tenants_controller_test.rb#create rolls back tenant`
- [x] `INFRA_URLS.md` + [`../../dev/SHOP_URL_MODES.md`](../../dev/SHOP_URL_MODES.md): на Fly — режим B (`?tenant_id=`); slug точек сохранены *(§7 ONBOARDING 2026-05-26)*

### A-inf. Свой домен → поддомены `{slug}.shop.бренд.ru` (режим A)

Пока домена нет — **не блокер** В2; на Fly тестируем режим B. Канон поддоменов не снимаем.

- [ ] Домен + DNS `*.shop…` CNAME → `coffeeos.fly.dev` *(прод — когда будет домен)*
- [ ] `fly certs add "*.shop…" -a coffeeos` → Ready
- [ ] `SHOP_BASE_DOMAIN=shop.…` на стенде + `config.hosts` при необходимости
- [ ] Smoke: 3 slug → 3 HTTPS-витрины, разное меню
- [x] Карточка УК после create → URL витрины *(режим A: subdomain; B: `?tenant_id=`)*

**Код готов:** reserved slug, Host→tenant, UrlBuilder — §7 ONBOARDING.

---

## B. Связность админок (приоритет 1)

- [x] ⭐ УК → точка → `open_as_manager` → manager видит **ту же** точку и каталог *(§5–§6 ONBOARDING 2026-05-26)*
- [x] ⭐ Меню УК → PTS на все точки org → витрина показывает меню; **без F5** polling ~8 s *(2026-06-04: `589e397`+`e398981`+`1861f4f`, handoff `HANDOFF_UK_MENU_VITRINA.md`)*
- [x] ⭐ Barista / prep_kitchen — только данные **своего** `tenant_id` (RLS + session) *(§6 prep_kitchen movement; §2 RLS orders)*
- [x] ⭐ **shift_manager** (`shift-a@demo.coffeeos.local`) → `/manager` *(2026-05-28: прогон 5, AUTH-06 PASS)*
- [x] ⭐ **franchise_manager** (`franchise@demo.coffeeos.local`) → `/manager` *(2026-05-28: AUTH-02 PASS, switcher A/B)*
- [x] ⭐ **prep_kitchen_worker** (`pk-worker@demo.coffeeos.local`) → `/prep_kitchen` *(2026-05-28: AUTH-08 PASS)*
- [x] ⭐ Feature flags (модули) отключают недоступные разделы или явный «модуль выключен» *(2026-05-27: barista/prep_kitchen base_controller + `feature_flags_test.rb`)*
- [x] Health `/health/tenants` отражает новые точки (опционально в демо) *(2026-05-27: `health/tenants_controller_test.rb` 3 tests)*

---

## B2A. УК — мониторинг (перед табло баристы)

См. [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](CUSTOMER_BUSINESS_REQUIREMENTS.md) «Блок 2A».

- [x] ⭐ **2A.1** Мониторинг точек — UI + JSON — **PASS** 2026-06-06
- [x] ⭐ **2A.2** Журнал событий — детали + unified feed + Events JSON — **PASS** 2026-06-06
- [x] ⭐ **2A.3** Логин / user ID / **сессии точки** — **PASS** 2026-06-06
- [x] ⭐ **2A.4** Транзакции (payments) — список по точке для УК — **PASS** 2026-06-06

---

## B2B. Поток 1 — витрина (волна 4, после §2.3 и 2A)

См. CBR «[Волна 4](#волна-4--поток-1-приём-заказа-следующие-задачи)». **W1.1–W1.4 закрыты** — можно **блок 2** (табло).

- [x] ⭐ **W1.1** Баг 6.1 — цена из менеджера/УК на витрине (cache bust) — **PASS** 2026-06-06
- [x] ⭐ **W1.2** MCP: УК → категория + 2 товара + фото + модификаторы → витрина — **PASS** 2026-06-06 ([`mcp_w12_uk_menu_vitrina_2026-06-06.json`](../artifacts/demo-feedback/mcp_w12_uk_menu_vitrina_2026-06-06.json); модификаторы на Fly — integration test)
- [x] **W1.3** Обязательные модификаторы — MCP на Fly — **PASS** 2026-06-06 ([`mcp_w13_required_modifiers_fly_2026-06-06.json`](../artifacts/demo-feedback/mcp_w13_required_modifiers_fly_2026-06-06.json))
- [x] **W1.4** Сверка категорий: витрина = barista — **PASS** 2026-06-06 ([`mcp_w14_category_sync_fly_2026-06-06.json`](../artifacts/demo-feedback/mcp_w14_category_sync_fly_2026-06-06.json) — FULL A+B; апрув заказчика)
- [x] **W1.5** Боевые оплаты — §2.3 PASS 2026-06-06
- [x] **B1.1** Уведомления гостю — экран статуса + push FCM v1 — **PASS** 2026-06-10 ([`b11_acceptance_2026-06-10.json`](../artifacts/demo-feedback/b11_acceptance_2026-06-10.json); smoke + MCP Fly)

## B2. Поток 2 — табло баристы

См. [B2_1_barista_order_board.md](../requirements/customer_tasks/B2_1_barista_order_board.md).

- [ ] **B2.1** Интерактивная карточка + FIFO + модификаторы + связка с B1.1
- [ ] **B2.2** Объединить «Меню» + «Создать», убрать наличные на точке

---

## C. Оплата (приоритет 1 — §2.3 закрыт)

- [x] ⭐ `SHOP_SIMULATE_PAYMENT=0` на стенде приёмки: card/sbp → `pending_payment` *(fly secrets set 2026-05-28)*
- [x] ⭐ Интеграция шлюза Т-Банк: `TbankAdapter` + `OrderCreator` → `payment_url` *(2026-05-28)*
- [x] ⭐ Callback `POST /callbacks/tbank` → `TbankController` → `PaymentStatusUpdater` → order `accepted`, списание склада *(2026-05-28)*
- [x] ⭐ Витрина: выбор метода оплаты (card/sbp/cash), редирект на `payment_url`, без double-submit *(2026-05-28)*
- [x] ⭐ QR на столах: стабильный URL витрины точки — режим B `?tenant_id=` работает сейчас *(2026-05-28)*; режим A (`{slug}.домен/shop`) — в §I, ждёт собственный домен
- [x] Manager: pending payments при закрытии смены — добавлен блок «Онлайн-платежи (витрина, за 24ч)» в CloseWizard; онлайн-заказы не блокируют, показываются информационно *(2026-05-28)*
- [x] Тесты: `TbankAdapter` (11) + `TbankController` (8) — 539 runs, 0 failures *(2026-05-28)*

---

## D. Киоск (приоритет 3, с оплатой как shop)

> **В2:** backend + **витрина** + curl smoke — достаточно.  
> **В3:** Flutter UI (планшет + мобилка) — [`FLUTTER_API.md`](FLUTTER_API.md).  
> Приёмка §I **не закрыта** без апрува и §E.

| Слой | Статус |
|------|--------|
| Rails: auth, shop API, оплата § C | ✅ |
| Витрина + curl smoke (имитация киоска) | ✅ prog 7–9 |
| Flutter UI | → **В3** |
| Curl smoke | ✅ prog 7 PASS (`QA_ACCEPTANCE_RUN.md`) |

- [x] ⭐ Заказ / оплата через API — curl + витрина PASS; см. [`FLUTTER_API.md`](FLUTTER_API.md) *(prog 7–9)*
- [x] Регистрация устройства `device_type: kiosk` на точку — форма в manager/devices, токен выдаётся *(2026-05-28)*
- [x] Запись в [`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md) *(2026-05-28)*
- [ ] ⭐ UI киоска (Flutter) — **В3**, дата: ____________
- [ ] ⭐ URL киоска на точку — **В3** (домен + Flutter)

---

## E. Полировка по демо (блокер §I)

См. [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) — очередь **§1–3 done** *(2026-06-04)*.  
**Активная работа заказчика (§2.3 UX):** **done** 2026-06-06 — [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](CUSTOMER_BUSINESS_REQUIREMENTS.md). **Следующее:** блок 2 (табло баристы).

- [x] Процесс: правки PDF → DEMO_FEEDBACK → код/MCP → `done` *(2026-06-04)*
- [x] Критичные блокеры демо из PDF прогонки — закрыты *(MCP Fly)*

---

## F. Кассовая дисциплина (расширение, после C/D или по продукту)

- [x] Решение продукта: **смена — barista/manager да; shop/киоск — нет** (как сейчас) *(2026-05-30)*
- [ ] Единая смена на **всех** каналах (код + audit + qa 3.V2-1) — **В3**
- [ ] Z-отчёт — **В3**

---

## G. Offline-first — **В3**

> Перенос из В2. См. [`OFFLINE_SYNC.md`](OFFLINE_SYNC.md).

- [ ] IndexedDB буфер barista POS — **В3**
- [ ] Индикатор Online/Offline/Syncing — **В3**
- [ ] Sync queue + `client_uuid` / idempotency на create order — **В3**
- [ ] `drift_offset` по ARCHITECTURE.md — **В3**
- [ ] Сценарии O-1…O-3 в `qa_scenarios.md` — **В3**

---

## H. Надёжность (хвост В2)

> ⚠️ **Весь блок H обязателен ДО переключения на боевой терминал Т-Банка.**  
> Детали и шаги — [`PRACTICES.md`](PRACTICES.md) § «7 практик Dodo».
>
> **Что значит каждый пункт простыми словами:**  
> — Outbox: если сервер упал в момент callback от Т-Банка — заказ не потеряется, обработка повторится  
> — Circuit Breaker: если Т-Банк недоступен — сайт не ломается, клиент видит «попробуйте позже»  
> — Idempotency callback: если Т-Банк прислал webhook дважды — заказ не задвоится  
> — Мониторинг: если callback вообще не пришёл — мы узнаем и разберёмся вручную  
> — Боевой терминал: только когда всё выше готово — включаем реальные деньги

- [x] ⭐ **Outbox** — `Payments::TbankCallbackJob` на Solid Queue: retry x5 + discard на InvalidStatus *(2026-05-28)*
- [x] ⭐ **Circuit Breaker** — `TbankAdapter#post_json_with_circuit_breaker`: 5 ошибок → circuit open 60с → fallback *(2026-05-28)*
- [x] ⭐ **Idempotency в `/callbacks/tbank`** — Redis-ключ `tbank:callback:{PaymentId}:{Status}` TTL 24ч *(2026-05-28)*
- [x] **Мониторинг зависших платежей** — `Payments::StuckPaymentsCheckJob`: pending_payment > 30 мин → TelegramAlertJob *(2026-05-28)*
- [x] Переключить на боевой терминал Т-Банка (`fly secrets set TBANK_TERMINAL_KEY=1719235292309`) — *(2026-05-28, prod smoke PASS)*
- [x] **Solid Queue + Solid Cable на Fly** — worker `bin/jobs`; live-табло без F5; signed callback через worker *(прогон 4 PASS + `DB_POOL=8`, order `85bef120`, 2026-05-28)*
- [x] UX таймаут БД >5 с (qa 6.2) — overlay skeleton при fetch >5 с; тест `slow_request_ux_test.rb` *(прогон 8, 2026-05-30)*
- [x] V2-T8: flaky `events_controller_test` (callback timestamp) — 200 с + `travel_to` *(2026-05-30, 23/0 + ×5)*
- [x] Blameless Postmortem — [`POSTMORTEM_2026-05-28.md`](POSTMORTEM_2026-05-28.md) § Fly/T-Bank + § Прогон 10 *(блок 14, 2026-06-02)*
- [ ] Возврат (refund) через Т-Банк API — **В3**, не блокирует В2

---

## I. Приёмка и закрытие вехи

> **Блокеры §I:** §E (DEMO_FEEDBACK открыт) + живое демо + апрув заказчика.  
> **Хвосты → В3:** Flutter (киоск/мобилка), offline (§G), касса на всех каналах (§F п.2), refund (§H).

- [x] [`CODE_REVIEW.md`](CODE_REVIEW.md) — вердикт **2026-05-30** (к прогону 10; 554/0)
- [x] [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md) — **прогон 10 PASS** (блоки 0–14 — детали там же, § «Прогон 10 — блоки 0–14»)
- [ ] **§E** [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) — фидбек и блокеры закрыты
- [ ] Живое демо В2 — [`LIVE_DEMO_SCENARIOS_PLAIN.md`](LIVE_DEMO_SCENARIOS_PLAIN.md)
- [x] `bin/rails test` — **554/0** в `PRACTICES.md` *(2026-05-30, prog 8b)*
- [x] Postmortem (прогон 10) — [`POSTMORTEM_2026-05-28.md`](POSTMORTEM_2026-05-28.md); §I веха — после §E + живого демо
- [ ] `docs/operations/session/SESSION_STATE.md` — «Веха 2 закрыта» или список хвостов
- [ ] `docs/operations/journal/CHANGELOG.md` — запись о закрытии В2
- [x] **§D В2:** витрина + curl smoke — см. [`FLUTTER_API.md`](FLUTTER_API.md), prog 7–9
- [x] **§F решение** — смена barista/manager; shop/киоск без смены *(см. §F)*
- [ ] **§D Flutter** — **В3**, дата: ____________

---

## Критерий «Веха 2 закрыта»

1. Блоки **A, B, C** (⭐) — `[x]`.
2. **D** — для В2: витрина + curl smoke ✅; Flutter UI → **В3** (дата в §I).
3. **H** — Outbox + Circuit Breaker `[x]` до переключения на боевой терминал.
4. Новая org из УК: **3+ точки**, карточка входов, витрина с **реальной** оплатой на стенде.
5. **§E** закрыт + § I заполнен + апрув заказчика.

**Дата закрытия:** ____________  
**Кто принял:** ____________  
**Хвосты в В3:** Flutter (киоск/мобилка), offline (§G), касса на всех каналах (§F), refund (§H), Z-отчёт

**Прогон 10 (блоки 0–14):** [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md) § «Прогон 10 — блоки 0–14». Прогона 11 нет. Вход агента: [`SESSION_STATE.md`](../../session/SESSION_STATE.md).
