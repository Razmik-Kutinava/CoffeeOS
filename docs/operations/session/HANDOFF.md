# HANDOFF — Веха 2 (Веха 1 **закрыта** 2026-06-19)

**Дата:** 2026-06-30 (B1.13 docs S2-канон)  
**Ветка:** `develop`  
**Прод:** https://coffeeos.fly.dev

### B1.14 — адрес точки + выбор точки в шапке витрины

| Что | Статус |
|-----|--------|
| ТЗ этап 0 | `[x]` 2026-06-23 — текст заказчика дословно + ответы владельца Q1–Q10 |
| Этап 0 JSON | [`b114_stage0_scope_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_stage0_scope_2026-06-23.json) · [`b114_screenshot_baseline_2026-06-23.json`](../milestones/veha_2/artifacts/demo-feedback/b114_screenshot_baseline_2026-06-23.json) |
| Скрины «до» | [`b114_shop_header_coffeeos_before_2026-06-23.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b114_shop_header_coffeeos_before_2026-06-23.png) · [`b114_uk_tenants_card_before_2026-06-23.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/b114_uk_tenants_card_before_2026-06-23.png) |
| Код | **B1.14-3d index map** `[x]` 2026-06-23 · **B1.14-4** cart `[ ]` |
| **Deploy** | `bin/fly_deploy.sh` — WSL fix (`--remote-only`, staging `/mnt/c/`) · повторить деплой |
| **Следующий шаг** | **`go` B1.14-4** cart |
| **Агент** | **стоп** — deploy владельца |

ТЗ: [`B1_14_shop_tenant_address_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_14_shop_tenant_address_header.md)

### B1.13 — новая навигация витрины (эпик S1–S4 + rev2)

| Что | Статус |
|-----|--------|
| **rev1** | S1 MCP `[x]` · S2 MCP 9/9 `[x]` · S3 код `[x]` |
| **rev2 docs** | 4 текста дословно: **S1-R1, S2a, S2b, S3-rev2** `[x]` 2026-06-25 |
| **S3-rev2** | код `[x]` · **Fly MCP 12/12** post-redeploy 2026-06-26 (bump-queue на стенде) |
| **Q-rev1** | 2 вкладки + профиль в шапке — **ЗАКРЫТО** |
| **Q-rev5** | minus @1 disabled — **ЗАКРЫТО** (S3-rev2) |
| **Q-rev2** | пустая корзина — **ОТКРЫТО** |
| **Q-rev3,4** | **ЗАКРЫТО** 2026-06-26 |
| **S2b прогон 1** | скролл 100/200 px — **код `[x]`** |
| **S2b прогон 2** | localStorage режима — **код `[x]`** |
| **S2a прогон 3** | приёмка с товаром — **код `[x]`** |
| **S2a/S2b** | канон § **S2-канон** в B1_13 · код prog11 | re-MCP · апрув · Q-rev2 |
| **S4** | после апрува S2 |
| **Агент** | **стоп** |

ТЗ: [`B1_13_shop_nav_profile_header.md`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md)

### B1.13 rev1-S3 (архив)

Код `6fcc9d8` — приёмка перенесена в § **S3-rev2** в [`B1_13`](../milestones/veha_2/requirements/customer_tasks/B1_13_shop_nav_profile_header.md).

### B1.12 — рекуррент + оплата в 1 клик (Т-Банк, **rev2 nonPCI**)

| Что | Статус |
|-----|--------|
| **ТЗ rev2** | **этап 0 docs** `[x]` 2026-06-24 — дословные 3 задачи заказчика |
| **JSON этап 0** | [`b112_revision2_stage0_scope_2026-06-24.json`](../milestones/veha_2/artifacts/demo-feedback/b112_revision2_stage0_scope_2026-06-24.json) |
| **Сверка Т-Банк** | [`b112_tbank_nonpci_review_2026-06-24.json`](../milestones/veha_2/artifacts/demo-feedback/b112_tbank_nonpci_review_2026-06-24.json) |
| **Макеты** | [`1000008924.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/1000008924.png) R3 · [`1000008925.png`](../milestones/veha_2/artifacts/demo-feedback/screenshots/1000008925.png) R2 |
| **Workflow** | **Документ 1→R1→стоп → документ 2→R2→стоп → документ 3→R3** · один `go` на R |
| **Конфликты** | Q-R2-1..3 **`[x]`** зафиксированы 2026-06-24 (фаза 0 gate R3) |
| **Код rev2** | R1+R2+R3 `[x]` OPS_PASS |
| **Коммит** | `c27eb7c` — фаза 3 MCP + хвосты R2 |
| **Fly MCP** | [`b112_r3_fsm_ops_pass_2026-06-25.json`](../milestones/veha_2/artifacts/demo-feedback/b112_r3_fsm_ops_pass_2026-06-25.json) — **10/10** |
| **RSA Fly** | `[x]` `TBANK_RSA_PUBLIC_KEY` · `card_data_ready: true` |
| **Хвост** | — |
| **Следующий шаг** | **апрув заказчика** на эпик B1.12 rev2 |
| **Агент** | **стоп** |

ТЗ: [`B1_12_recurrent_payments.md`](../milestones/veha_2/requirements/customer_tasks/B1_12_recurrent_payments.md) · runbook: [`TBANK_RECURRENT.md`](../milestones/veha_2/runbooks/TBANK_RECURRENT.md)

### B1.11 — режим работы точки

| Что | Статус |
|-----|--------|
| ТЗ этап 0 | `[x]` 2026-06-18 |
| Ответы Q1–Q10 + раунд 2 | `[x]` 2026-06-19 · [`b111_customer_answers_round2_2026-06-19.json`](../milestones/veha_2/artifacts/demo-feedback/b111_customer_answers_round2_2026-06-19.json) |
| **Статус** | **+ шапка витрины** `schedule_display` · demo A/B разное расписание · тесты 13/13 шага |
| **Fly MCP** | `[x]` header A/B 2026-06-21 — [`b111_header_schedule_post_deploy_2026-06-21.json`](../milestones/veha_2/artifacts/demo-feedback/b111_header_schedule_post_deploy_2026-06-21.json) |
| **Следующий шаг** | **апрув заказчика** · «ок» или правки |
| **Агент** | **стоп** |

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
