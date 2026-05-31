# Веха 2 — Scale & Stability («Рост сети»)

**Старт:** 2026-05-25. **В1:** код на `develop`, официальное закрытие — по [`../veha_1/CHECKLIST.md`](../veha_1/CHECKLIST.md) § H.3 / § I (параллельно с В2).

**Fly demo-стенд:** [`../FLY_DEMO_STAND.md`](../FLY_DEMO_STAND.md), [`../CUSTOMER_HANDOFF.md`](../CUSTOMER_HANDOFF.md) — автосид; URL: [`../SHOP_URL_MODES.md`](../SHOP_URL_MODES.md). **Локально (WSL):** [`../LOCAL_DEV.md`](../LOCAL_DEV.md).

**Цель вехи:** новая организация и точки **из коробки** (боевые входы, RLS, каталог), связанные админки; **реальная оплата** на витрине (QR на столах); киоск на точку; далее offline и прочее из roadmap.

**Продукт (канон scope):** `docs/product/development_roadmap.md` § ВЕХА 2; детали — `01_Vision`, `02_functional`, `03_Business_Logic`, `ARCHITECTURE` (обновлено 2026-05-30). **Handoff:** `docs/operations/HANDOFF.md`.

---

## Карта документов

| Файл | Статус | Назначение |
|------|--------|------------|
| [CHECKLIST.md](CHECKLIST.md) | **заполнен** | Главный чеклист закрытия В2 (блоки A–I) |
| [ONBOARDING_CHECKLIST.md](ONBOARDING_CHECKLIST.md) | **заполнен** | Детальный чеклист онбординга УК / «коробки» |
| [ONBOARDING.md](ONBOARDING.md) | **заполнен** | Модель: org → точки → модули → входы → staff |
| [PRACTICES.md](PRACTICES.md) | **заполнен** | Журнал решений, приоритеты, техдолг В1→В2 |
| [ORDER_ENTRY_AUDIT.md](ORDER_ENTRY_AUDIT.md) | **заполнен** | Реестр каналов заказа + смена (В1 → В2) |
| [PAYMENT.md](PAYMENT.md) | **заполнен** | Реальная оплата, env, callbacks |
| [KIOSK.md](KIOSK.md) | **заполнен** | Киоск на точку, устройства, URL |
| [STAFF_ACCESS.md](STAFF_ACCESS.md) | **заполнен** | Кто как заводится на точку |
| [INFRA_URLS.md](INFRA_URLS.md) | **заполнен** | Поддомены, DNS, `SHOP_BASE_DOMAIN` |
| [../LOCAL_DEV.md](../LOCAL_DEV.md) | **заполнен** | Подъём на WSL: migrate, seed, `bin/dev`, витрина |
| [ONBOARDING_DEVTOOLS_SCENARIOS.md](ONBOARDING_DEVTOOLS_SCENARIOS.md) | **заполнен** | 58 сценариев MCP (онбординг) |
| [ONBOARDING_DEVTOOLS_RUN.md](ONBOARDING_DEVTOOLS_RUN.md) | **заполнен** | Журнал прогона 2026-05-27 |
| [`../SHOP_URL_MODES.md`](../SHOP_URL_MODES.md) | **заполнен** | Режим A (поддомен) vs B (Fly `?tenant_id=`) |
| [DEMO_FEEDBACK.md](DEMO_FEEDBACK.md) | **шаблон** | Очередь правок заказчика после демо В1 |
| [QA_ACCEPTANCE_RUN.md](QA_ACCEPTANCE_RUN.md) | **каркас** | Протокол приёмки В2 (заполнять при прогоне) |
| [CODE_REVIEW.md](CODE_REVIEW.md) | **каркас** | CR перед релизом/демо В2 |
| [DEMO_LOGINS.md](DEMO_LOGINS.md) | **каркас** | Логины стенда новых org (после `demo:seed` / ручного онбординга) |
| [OFFLINE_SYNC.md](OFFLINE_SYNC.md) | **заготовка** | Offline POS, sync, idempotency — этап позже |
| [FLUTTER.md](FLUTTER.md) | **заготовка** | Мобилка/киоск Flutter — если войдёт в веху |
| [LIVE_DEMO_SCENARIOS.md](LIVE_DEMO_SCENARIOS.md) | **заготовка** | Ручные сценарии приёмки В2 (тех) |
| [LIVE_DEMO_SCENARIOS_PLAIN.md](LIVE_DEMO_SCENARIOS_PLAIN.md) | **заготовка** | То же для заказчика |

**Вне папки:** `docs/agents/AGENTS/qa_scenarios.md` (секция [ВЕХА 2]), `docs/operations/CHANGELOG.md`, `SESSION_STATE.md`, `HANDOFF.md`, `ISSUES.md`.

---

## Порядок работ (зафиксировано 2026-05-25)

1. **Онбординг + коробка** — [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md)  
2. **Оплата** (витрина / QR; киоск — та же цепочка) — [`PAYMENT.md`](PAYMENT.md)  
3. **Киоск** — [`KIOSK.md`](KIOSK.md)  
4. **Полировка** параллельно — [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md)  
5. **Offline, единая смена, Outbox** — позже, [`OFFLINE_SYNC.md`](OFFLINE_SYNC.md)

---

## Задача в трекере

**«4 / веха-2 чеклист + практики»** = этот комплект + поддержка в актуальном состоянии по мере разработки.
