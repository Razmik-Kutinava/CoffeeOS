# HANDOFF — старт Вехи 2 (Веха 1 **не закрыта официально**)

**Дата:** 2026-06-18 (B1.11 этап 0 · ТЗ режим работы)  
**Ветка:** `develop`  
**Прод:** https://coffeeos.fly.dev

### B1.11 — режим работы точки

| Что | Статус |
|-----|--------|
| ТЗ этап 0 | `[x]` 2026-06-18 |
| Ответы заказчика Q1–Q10 | `[ ]` |
| Апрув на код + `go` | `[ ]` |

ТЗ: [`B1_11_tenant_operating_hours.md`](../milestones/veha_2/requirements/customer_tasks/B1_11_tenant_operating_hours.md)

### B1.10 — убрать «Блог»

| Что | Статус |
|-----|--------|
| «Блог» убран из шапки | `[x]` |
| Апрув заказчика | `[x]` 2026-06-18 — [`b110_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b110_customer_approval_2026-06-18.json) |

ТЗ: [`B1_10_remove_blog_nav.md`](../milestones/veha_2/requirements/customer_tasks/B1_10_remove_blog_nav.md)

### B1.7 — checkout (в т.ч. BR-5)

| Что | Статус |
|-----|--------|
| BR-5 второй товар в корзину | **закрыт** · апрув `[x]` 2026-06-18 — [`b17_br5_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b17_br5_customer_approval_2026-06-18.json) |
| BR-6 отмена на `#/payment` | **закрыт** · апрув `[x]` 2026-06-18 — [`b17_br6_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b17_br6_customer_approval_2026-06-18.json) |
| B1.9 toggle-модификаторы | **закрыта** · апрув `[x]` 2026-06-18 — [`b19_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b19_customer_approval_2026-06-18.json) · CC-2 в backlog |
| B1.7 целиком | **закрыта** · апрув `[x]` 2026-06-04 |

ТЗ: [`B1_7_checkout_order_screen.md`](../milestones/veha_2/requirements/customer_tasks/B1_7_checkout_order_screen.md)

### B2.1 — табло бариста

| Что | Статус |
|-----|--------|
| MVP этапы 0–5 + ревизия R0–R4 | `[x]` OPS_PASS |
| Апрув заказчика | `[x]` 2026-06-18 — [`b21_customer_approval_2026-06-18.json`](../milestones/veha_2/artifacts/demo-feedback/b21_customer_approval_2026-06-18.json) |
| Backlog фаза 2 | CBR «Блок 2 — backlog» (брак, defect_reasons, звук отмены, списание, prep_kitchen, эскалация) |
| **Следующий шаг** | **B2.2** этап 1 |

ТЗ: [`B2_1_barista_order_board.md`](../milestones/veha_2/requirements/customer_tasks/B2_1_barista_order_board.md)

### B1.1 — экран статуса заказа

| Этап | Статус |
|------|--------|
| 0 Маппинг + макеты | `[x]` — [`b11_stage0_mapping_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage0_mapping_2026-06-09.json) |
| 1 Статический UI `/order/:id` | `[x]` — [`b11_stage1_static_ui_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage1_static_ui_2026-06-09.json) |
| 2 WebSocket | `[x]` — [`b11_stage2_websocket_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage2_websocket_2026-06-09.json) |
| 3 Отмена | `[x]` — [`b11_stage3_cancel_2026-06-09.json`](../milestones/veha_2/artifacts/demo-feedback/b11_stage3_cancel_2026-06-09.json) |
| 4 Тесты + MCP | `[x]` — [`b11_acceptance_2026-06-10.json`](../milestones/veha_2/artifacts/demo-feedback/b11_acceptance_2026-06-10.json) · **deploy Fly** → прогон заказчика |

ТЗ: [`B1_1_order_status_progress.md`](../milestones/veha_2/requirements/customer_tasks/B1_1_order_status_progress.md)

### Сессия 2026-06-08 — правила Cursor (синхронизировано)

**Карта:** `docs/operations/RULES_INDEX.md` · индекс `.cursor/rules/coffeeos-index.mdc`

| Что | Где |
|-----|-----|
| **Коммит + ops (канон)** | `workflow/coffeeos-commit-ops.mdc` |
| **Задачи, go, отчёт** | `workflow/coffeeos-task-workflow.mdc` |
| Workflow + project | `.cursor/rules/workflow/`, `.cursor/rules/project/` |
| Symlinks | `.cursor/rules/coffeeos-*.mdc` → `project/` (совместимость) |

**Коммит:** всегда после шага с правками, **до отчёта**, без вопроса. **Push:** только по явной просьбе. **Отчёт:** таблица Сделано | Не сделано + `Коммит: <хеш>`. **Scratch:** `scripts/scratch/`.

### Статус вех (важно для агента)

| Веха | Официально | По факту |
|------|------------|----------|
| **Веха 1** | **Не закрыта** — нет § I, H.3 живого демо, даты/подписи в чеклисте | Код A–G на `develop`, тесты зелёные, деплой Fly после v1.53 |
| **Веха 2** | **Старт работ** — основной фокус нового окна/агента | Roadmap § «Scale & Stability» |

**Режим:** разработка **В2 идёт параллельно**. Закрытие В1 — **заочно**, когда владелец пройдёт H.3 и кто-то отметит § I в `milestones/veha_1/checklists/CHECKLIST.md`. **Не писать** в ops «Веха 1 закрыта», пока § I не `[x]`.

---

## Что сделано в этой сессии (операционка + код)

### Код (уже на `develop`)

| Область | Что |
|---------|-----|
| **A** | Service Objects: `OrderCancellationService`, `OrderStatusUpdateService`, `PaymentStatusUpdater`, `MovementCreator` fix, рефактор контроллеров |
| **B** | MVP-модели, `Demo::EnvironmentSetup`, `demo:seed`, shop API, RLS-тесты, онбординг УК |
| **C** | RBAC integration-тесты всех 7 ролей панелей |
| **D** | MCP-обход панелей (журнал в `PRACTICES.md` § Block D) |
| **E** | Svelte `/shop`: каталог, корзина, модификаторы, mock-оплата, история |
| **F** | `Inventory::OrderRecipeDeduction`, миграция block F, prep_kitchen movements |
| **G** | Гибрид смены: shop без смены, barista только с open shift; отмена с reason + audit |
| **Инфра** | `bin/ensure-server`, `lib/port_killer.rb`, `lib/dev_server.rb` |
| **Тесты** | **479 runs, 0 failures** (2026-05-25) |
| **Review** | N+1 в `app/services/shop/order_creator.rb` — preload products |
| **Деплой** | Убраны win32 npm bindings из `package.json`; `Dockerfile`: `npm ci` (коммит `4a25187`) |

### Git (пуши на develop)

1. **15 коммитов** — полный объём В1 (db, services, frontend shop, tests, product docs, ops milestones в git, agents).
2. **1 коммит** — fix Fly build (`fix(deploy): remove Windows-only npm bindings…`).

Деплой: `.github/workflows/deploy.yml` → `flyctl deploy` при push в `develop`. Не ждать автодеплой от одного git без CI.

### Документация операционная

| Файл | Статус |
|------|--------|
| `milestones/veha_1/checklists/CHECKLIST.md` | A–G, H.2 — `[x]`; H.3 демо — `[ ]`; § I — `[ ]` |
| `milestones/veha_1/reference/PRACTICES.md` | Журнал блоков, техдолг В1, QA H.2, code review |
| `milestones/veha_1/qa/QA_ACCEPTANCE_RUN.md` | Протокол сухой + MCP |
| `milestones/veha_1/qa/CODE_REVIEW.md` | CR-1 исправлен |
| `milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md` | Гибрид A/B, реестр 8 входов |
| `milestones/veha_1/reference/DEMO_LOGINS.md` | 9 пользователей, пароль `demo123456` |
| `milestones/veha_1/qa/LIVE_DEMO_SCENARIOS.md` | Технические ручные сценарии (**файл есть локально, в git может не быть**) |
| `milestones/veha_1/qa/LIVE_DEMO_SCENARIOS_PLAIN.md` | Простой язык для заказчика + URL витрин (**то же**) |
| `docs/operations/journal/CHANGELOG.md` | v1.50–v1.54 |
| `docs/operations/session/SESSION_STATE.md` | Обновлён под handoff |
| `.gitignore` | Разрешён `docs/operations/milestones/**/*.md` |

### Продуктовые доки (синхрон с В1)

`01_Vision.md`, `02_functional.md`, `03_Business_Logic.md`, `ARCHITECTURE.md`, `development_roadmap.md` — **код В1** в roadmap «реализован»; **ops-закрытие В1** — отдельно, см. чеклист § I.

---

## Что **не** закрыто (остаток В1)

1. **H.3** — живое демо заказчиком по `LIVE_DEMO_SCENARIOS_PLAIN.md` (минимум 4 истории § 10).
2. **§ I** чеклиста — `SESSION_STATE` «Веха 1 закрыта», запись в CHANGELOG о закрытии, финальный список хвостов в `PRACTICES.md`.
3. **Коммит** файлов `LIVE_DEMO_SCENARIOS*.md` + актуальный `CHECKLIST`/`README` если ещё не в репозитории.
4. Чеклист **B** п. QA 5.1 (откат онбординга при ошибке) — `[ ]`, ручной негативный тест.

---

## Для агента Вехи 2 — с чего начать

**Фокус:** В2. В1 не доделывать в этом окне, кроме явной просьбы (демо H.3, § I).

1. Прочитать **`docs/product/development_roadmap.md`** § «ВЕХА 2 (Scale & Stability)».
2. Создать/наполнить **`docs/operations/milestones/veha_2/`** (сейчас только `README.md`-заготовка).
3. **Не ломать** гибрид смены В1 без явного продукта — в В2 планируется ужесточение (единая смена на всех каналах), см. `ORDER_ENTRY_AUDIT.md`.
4. Техдолг В1 — только в **`milestones/veha_1/reference/PRACTICES.md`** § «Техдолг В1», не размазывать по Vision/Architecture.
5. Правила кода: `.cursor/rules/project/coffeeos-core.mdc`, `coffeeos-performance.mdc`, `coffeeos-services.mdc`; карта — `RULES_INDEX.md`.

### Приоритеты В2 (из roadmap, не начато)

- Реальная оплата (`SHOP_SIMULATE_PAYMENT=0`, шлюз, callbacks).
- Offline-first / sync для POS.
- Flutter + киоск (заказы без смены как shop).
- Outbox (Solid Queue), Circuit Breaker (конец В2).
- Расширение кассовой дисциплины на сеть точек.

### Демо-стенд (develop → Fly)

**URL витрины:** два режима — [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md). Сейчас **режим B** (Fly): `?tenant_id=`. **Режим A** (прод): `{slug}.shop.домен` после своего DNS/TLS.

**После деплоя** (H.3): `fly.toml` — `demo:seed` в release; **без** `SHOP_BASE_DOMAIN`.  
`fly ssh console -a coffeeos -C 'bin/rails demo:shop_urls'` — URL точек A/B.

- Инструкция: `FLY_DEMO_STAND.md`, чеклист § H.0 `veha_1/checklists/CHECKLIST.md`
- Логины: `milestones/veha_1/reference/DEMO_LOGINS.md` (`demo123456`)
- **Передать заказчику:** [`../demo/CUSTOMER_HANDOFF.md`](../demo/CUSTOMER_HANDOFF.md) + `LIVE_DEMO_SCENARIOS_PLAIN.md`
- Свой домен: `veha_2/checklists/CHECKLIST.md` § **A-inf**

---

## Блокеры

Нет для старта В2. Деплой Fly после v1.53 должен собираться; при падении — смотреть GitHub Actions → Build Image → `npm ci`.

---

## Открытые вопросы (на продукт/владельца)

- Подтверждение живого демо H.3 и дата закрытия В1.
- Приоритет внутри В2: оплата vs offline vs Flutter.

---

**Предыдущий контекст (schema):** батчи B1–B5, `GAP_LIST_CORE_SCHEMA.md` — done; не смешивать с чеклистом В1 без необходимости.
