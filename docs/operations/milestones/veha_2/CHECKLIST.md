# Веха 2 — чеклист закрытия «Scale & Stability»

**Цель:** сеть точек **из коробки**, реальная оплата на клиентских каналах, киоск, связные админки.

**Статус вехи:** **в работе** (доки и разработка с 2026-05-25). В1 официально может быть ещё открыта — не писать «В2 закрыта», пока § I ниже не `[x]`.

**Не входит в В2:** полный Event Sourcing склада, Z-отчёт, supply chain, анти-фрод алерты — **Веха 3** (`development_roadmap.md`).

**Как пользоваться:** `[x]` по мере готовности; ⭐ = критично для «веха закрыта». Детали онбординга — [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md). Правки UI — [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md).

**Связанные:** [`README.md`](README.md), [`PRACTICES.md`](PRACTICES.md), `docs/product/development_roadmap.md`.

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
- [x] `INFRA_URLS.md` + [`../../SHOP_URL_MODES.md`](../../SHOP_URL_MODES.md): на Fly — режим B (`?tenant_id=`); slug точек сохранены *(§7 ONBOARDING 2026-05-26)*

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
- [x] ⭐ Меню УК → PTS на все точки org → витрина `{slug}/shop` показывает актуальное меню *(§6: PublishProduct + shop API)*
- [x] ⭐ Barista / prep_kitchen — только данные **своего** `tenant_id` (RLS + session) *(§6 prep_kitchen movement; §2 RLS orders)*
- [x] ⭐ **shift_manager** (`shift-a@demo.coffeeos.local`) → `/manager` *(2026-05-28: прогон 5, AUTH-06 PASS)*
- [x] ⭐ **franchise_manager** (`franchise@demo.coffeeos.local`) → `/manager` *(2026-05-28: AUTH-02 PASS, switcher A/B)*
- [x] ⭐ **prep_kitchen_worker** (`pk-worker@demo.coffeeos.local`) → `/prep_kitchen` *(2026-05-28: AUTH-08 PASS)*
- [x] ⭐ Feature flags (модули) отключают недоступные разделы или явный «модуль выключен» *(2026-05-27: barista/prep_kitchen base_controller + `feature_flags_test.rb`)*
- [x] Health `/health/tenants` отражает новые точки (опционально в демо) *(2026-05-27: `health/tenants_controller_test.rb` 3 tests)*

---

## C. Реальная оплата (приоритет 2)

См. [`PAYMENT.md`](PAYMENT.md).

- [ ] ⭐ `SHOP_SIMULATE_PAYMENT=0` на стенде приёмки: card/sbp → `pending_payment`
- [x] ⭐ Интеграция шлюза Т-Банк: `TbankAdapter` + `OrderCreator` → `payment_url` *(2026-05-28)*
- [x] ⭐ Callback `POST /callbacks/tbank` → `TbankController` → `PaymentStatusUpdater` → order `accepted`, списание склада *(2026-05-28)*
- [x] ⭐ Витрина: выбор метода оплаты (card/sbp/cash), редирект на `payment_url`, без double-submit *(2026-05-28)*
- [ ] ⭐ QR на столах: стабильный URL витрины точки (`{slug}.домен/shop`)
- [ ] Manager: pending payments при закрытии смены (уже частично в UI — проверить на реальных платежах)
- [x] Тесты: `TbankAdapter` (11) + `TbankController` (8) — 539 runs, 0 failures *(2026-05-28)*

---

## D. Киоск (приоритет 3, с оплатой как shop)

См. [`KIOSK.md`](KIOSK.md).

- [ ] ⭐ Маршруты/UI киоска (не только `FeatureFlag` + `devices`)
- [ ] ⭐ URL киоска на точку (`{slug}.домен/...` — зафиксировать путь в KIOSK.md)
- [ ] ⭐ Заказ через тот же pipeline, что shop (без смены, как В1 гибрид)
- [ ] ⭐ Оплата киоска = та же цепочка, что § C (не отдельный «второй шлюз» без нужды)
- [ ] Регистрация устройства `device_type: kiosk` на точку
- [ ] Запись в [`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md)

---

## E. Полировка по демо (параллельно)

См. [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md) — **не блокирует** A–C, кроме явных блокеров.

- [ ] Процесс: каждая правка заказчика → строка в DEMO_FEEDBACK → PR → `[x]`
- [ ] Критичные блокеры демо (если есть) закрыты до «веха принята»

---

## F. Кассовая дисциплина (расширение, после C/D или по продукту)

- [ ] Решение продукта: единая смена на **всех** каналах? (сейчас В1: shop/киоск без смены)
- [ ] Если да — код + [`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md) + `qa_scenarios` 3.V2-1
- [ ] Z-отчёт — **не В2** (В3)

---

## G. Offline-first (позже в В2)

См. [`OFFLINE_SYNC.md`](OFFLINE_SYNC.md).

- [ ] IndexedDB буфер barista POS
- [ ] Индикатор Online/Offline/Syncing
- [ ] Sync queue + `client_uuid` / idempotency на create order
- [ ] `drift_offset` по ARCHITECTURE.md
- [ ] Сценарии O-1…O-3 в `qa_scenarios.md`

---

## H. Надёжность (хвост В2)

- [ ] Outbox-паттерн на Solid Queue (критичные side-effects)
- [ ] Circuit Breaker для внешних API (платёж, ОФД)
- [ ] UX таймаут БД >5 с (qa 6.2)

---

## I. Приёмка и закрытие вехи

- [ ] [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md) — этапы 1–3
- [ ] [`CODE_REVIEW.md`](CODE_REVIEW.md) — вердикт перед прод-включением оплаты
- [ ] Живое демо В2 (когда появятся [`LIVE_DEMO_SCENARIOS_PLAIN.md`](LIVE_DEMO_SCENARIOS_PLAIN.md))
- [ ] `bin/rails test` — зафиксировать runs/0 failures в `PRACTICES.md`
- [ ] `docs/operations/SESSION_STATE.md` — «Веха 2 закрыта» или список хвостов
- [ ] `docs/operations/CHANGELOG.md` — запись о закрытии В2
- [ ] Техдолг В2→В3 только здесь / `PRACTICES.md`, не в `development_roadmap`

---

## Критерий «Веха 2 закрыта»

1. Блоки **A, B, C** (⭐) — `[x]`.
2. **D** — киоск с заказом и оплатой на тестовой org, или явный перенос в § I с датой.
3. Новая org из УК: **3+ точки**, карточка входов, витрина с **реальной** оплатой на стенде.
4. § I заполнен в operations.

**Дата закрытия:** ____________  
**Кто принял:** ____________  
**Хвосты в В3:** ____________
