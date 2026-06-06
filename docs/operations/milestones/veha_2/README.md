# Веха 2 — Scale & Stability («Рост сети»)

**Старт:** 2026-05-25. **В1:** код на `develop`, официальное закрытие — по [`../veha_1/checklists/CHECKLIST.md`](../veha_1/checklists/CHECKLIST.md) § H.3 / § I (параллельно с В2).

**Fly demo-стенд:** [`../demo/FLY_DEMO_STAND.md`](../demo/FLY_DEMO_STAND.md), [`../demo/CUSTOMER_HANDOFF.md`](../demo/CUSTOMER_HANDOFF.md) — автосид; URL: [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md). **Локально (WSL):** [`../dev/LOCAL_DEV.md`](../dev/LOCAL_DEV.md).

**Цель вехи:** новая организация и точки **из коробки** (боевые входы, RLS, каталог), связанные админки; **реальная оплата** на витрине (QR на столах); киоск на точку; далее offline и прочее из roadmap.

**Продукт (канон scope):** `docs/product/development_roadmap.md` § ВЕХА 2; детали — `01_Vision`, `02_functional`, `03_Business_Logic`, `ARCHITECTURE` (обновлено 2026-05-30). **Handoff:** `docs/operations/session/HANDOFF.md`.

---

## Структура папок

| Папка | Содержимое |
|-------|------------|
| [requirements/](requirements/) | CBR, DEMO_FEEDBACK |
| [checklists/](checklists/) | CHECKLIST, ONBOARDING_CHECKLIST |
| [runbooks/](runbooks/) | ONBOARDING, PAYMENT, STAFF, INFRA… |
| [qa/](qa/) | приёмка, live-demo, postmortem |
| [reference/](reference/) | PRACTICES, DEMO_LOGINS |
| [artifacts/](artifacts/) | MCP JSON, скрины, prog10 |

Старые пути (до реорганизации): [`../PATH_MAP.md`](../PATH_MAP.md).

## Карта документов

| Файл | Статус | Назначение |
|------|--------|------------|
| [checklists/CHECKLIST.md](checklists/CHECKLIST.md) | **заполнен** | Главный чеклист закрытия В2 (блоки A–I) |
| [checklists/ONBOARDING_CHECKLIST.md](checklists/ONBOARDING_CHECKLIST.md) | **заполнен** | Детальный чеклист онбординга УК / «коробки» |
| [runbooks/ONBOARDING.md](runbooks/ONBOARDING.md) | **заполнен** | Модель: org → точки → модули → входы → staff |
| [reference/PRACTICES.md](reference/PRACTICES.md) | **заполнен** | Журнал решений, приоритеты, техдолг В1→В2 |
| [runbooks/ORDER_ENTRY_AUDIT.md](runbooks/ORDER_ENTRY_AUDIT.md) | **заполнен** | Реестр каналов заказа + смена (В1 → В2) |
| [runbooks/PAYMENT.md](runbooks/PAYMENT.md) | **заполнен** | Реальная оплата, env, callbacks |
| [runbooks/STAFF_ACCESS.md](runbooks/STAFF_ACCESS.md) | **заполнен** | Кто как заводится на точку |
| [runbooks/INFRA_URLS.md](runbooks/INFRA_URLS.md) | **заполнен** | Поддомены, DNS, `SHOP_BASE_DOMAIN` |
| [../dev/LOCAL_DEV.md](../dev/LOCAL_DEV.md) | **заполнен** | Подъём на WSL: migrate, seed, `bin/dev`, витрина |
| [runbooks/ONBOARDING_DEVTOOLS_SCENARIOS.md](runbooks/ONBOARDING_DEVTOOLS_SCENARIOS.md) | **заполнен** | 58 сценариев MCP (онбординг) |
| [runbooks/ONBOARDING_DEVTOOLS_RUN.md](runbooks/ONBOARDING_DEVTOOLS_RUN.md) | **заполнен** | Журнал прогона 2026-05-27 |
| [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md) | **заполнен** | Режим A (поддомен) vs B (Fly `?tenant_id=`) |
| [requirements/DEMO_FEEDBACK.md](requirements/DEMO_FEEDBACK.md) | **шаблон** | Очередь правок заказчика после демо В1 |
| [requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md](requirements/CUSTOMER_BUSINESS_REQUIREMENTS.md) | **активен** | CBR — требования бизнеса |
| [qa/QA_ACCEPTANCE_RUN.md](qa/QA_ACCEPTANCE_RUN.md) | **каркас** | Протокол приёмки В2 (заполнять при прогоне) |
| [qa/CODE_REVIEW.md](qa/CODE_REVIEW.md) | **каркас** | CR перед релизом/демо В2 |
| [reference/DEMO_LOGINS.md](reference/DEMO_LOGINS.md) | **каркас** | Логины стенда новых org (после `demo:seed` / ручного онбординга) |
| [runbooks/OFFLINE_SYNC.md](runbooks/OFFLINE_SYNC.md) | **заготовка** | Offline POS, sync, idempotency — этап позже |
| [qa/LIVE_DEMO_SCENARIOS.md](qa/LIVE_DEMO_SCENARIOS.md) | **заготовка** | Ручные сценарии приёмки В2 (tech) |
| [qa/LIVE_DEMO_SCENARIOS_PLAIN.md](qa/LIVE_DEMO_SCENARIOS_PLAIN.md) | **заготовка** | То же для заказчика |

**Вне папки:** `docs/agents/AGENTS/qa_scenarios.md`, [journal/CHANGELOG.md](../journal/CHANGELOG.md), [session/SESSION_STATE.md](../session/SESSION_STATE.md), [session/HANDOFF.md](../session/HANDOFF.md), [ISSUES.md](../ISSUES.md).

---

## Порядок работ (зафиксировано 2026-05-25)

1. **Онбординг + коробка** — [`checklists/ONBOARDING_CHECKLIST.md`](checklists/ONBOARDING_CHECKLIST.md)  
2. **Оплата** (витрина / QR; киоск — та же цепочка) — [`runbooks/PAYMENT.md`](runbooks/PAYMENT.md)  
3. **Киоск** — см. runbooks / product roadmap  
4. **Полировка** параллельно — [`requirements/DEMO_FEEDBACK.md`](requirements/DEMO_FEEDBACK.md)  
5. **Offline, единая смена, Outbox** — позже, [`runbooks/OFFLINE_SYNC.md`](runbooks/OFFLINE_SYNC.md)

---

## Задача в трекере

**«4 / веха-2 чеклист + практики»** = этот комплект + поддержка в актуальном состоянии по мере разработки.
