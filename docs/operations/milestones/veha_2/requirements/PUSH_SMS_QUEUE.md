# Очередь Push + SMS — строгий порядок задач заказчика

**Создано:** 2026-10-28 · **Порядок заказчика (дословно):** [`customer_order.md`](../artifacts/push_sms_task_order/customer_order.md) · **Ответы заказчика 2026-10-28:** [`customer_answers_2026-10-28.md`](../artifacts/push_sms_task_order/customer_answers_2026-10-28.md) · **Папка Drive:** [Push + sms](https://drive.google.com/drive/folders/15tsiobSfJsv-JpU4255r52m1XK7qTm_n)

Канон очереди — эта таблица. Порядок не менять без решения заказчика.

## Как работать (агент читает этот раздел на `/start`)

1. **Один шаг = один новый чат.** Пользователь пишет `/start`. Агент берёт **первый сверху** шаг со статусом `todo`, у которого все «Зависит от» = `done`. Шаг с 👤 — ручная часть владельца: агент пишет, что сделать, и стоп.
2. **Текст задачи — через Google Docs MCP** (`user-google-docs` → `docs_read_document`, id из колонки «Документ»). Пользователя текст не просить. MCP недоступен → стоп, попросить текст.
3. **Intake (PHASE 0, `coffeeos-customer-intake.mdc`):**
   - доп. задача → новый файл `customer_tasks/TASK-<N>-<Название-через-дефис>.md`, текст 1:1 + строка в `CUSTOMER_BUSINESS_REQUIREMENTS.md`;
   - патч → секция дословно в конец существующего TASK (после предыдущего патча); новый файл не создавать.
   - Свои заметки — только в `## Заметки агента` внизу.
4. **Перед `/spec`:** сверить шапку документа («Зависит от», «Порядок сборки», «Статус» в конце) со строкой очереди. Расхождение → `blocked` + вопрос в «Открытые вопросы».
5. **На `/spec`:** сверить факты документа (файл:строка, «Текущее поведение») с кодом. Сдвиг номеров строк — норма, новые номера в «Заметки агента». Поведение кода другое → шаг `blocked`, вопрос в «Открытые вопросы», стоп. Текст заказчика не править.
6. **Реверс** (в шапке «реверс …») → найти защитные тесты и переписать их явно на RED (`docs/operations/dev/TASK_PATCH.md`). **Миграция** → Migration Gate (`coffeeos-dev-gates.mdc`).
7. **Цепочка в чате:** `/start` → `/spec` → `/sbr` → `/regress` → `/review`. Docs-only шаг: intake/правка → коммит + ops, без SBR.
8. **Коммиты только явными путями** (`git add <path>`), без `git add -A` / `git add .`. Перед коммитом — `git status`: чужое в коммит задачи не брать.
9. **Закрытие шага** (последнее действие чата):
   - в таблице: статус `done`, коммит(ы), дата;
   - шапка `HANDOFF.md` → «Следующий шаг»;
   - `COMPONENT_MAP` — решение по `TASK_PATCH.md` шаг 6 (да/нет + причина);
   - напечатать в конце ответа:
     - если после шага стоит 🚀 — `Next: 🚀 деплой N — по апруву владельца` + что проверить после;
     - всегда последней строкой — `Next (новый чат): /start → шаг <№> — <ID> <название>`.
10. **Push** — на `/review` (PHASE 3). **Deploy** — только по апруву, в строках 🚀.

Статусы: `todo` · `in_progress` · `blocked` · `done`.

## Очередь

| № | ID заказчика | Что | Тип | Документ | Зависит от | Статус | Итог |
|---|---|---|---|---|---|---|---|
| 0.1 | Шаг 0 + TASK_99 | Intake TASK_99 (новый файл + строка CBR) и все строки «Уточнение 2026-10-18» в TASK_90, TASK_92, TASK_94, TASK_99, «Интеграция статусной модели в компактную шторку PWA и Push» — по [ответам](../artifacts/push_sms_task_order/customer_answers_2026-10-28.md) п. 1–2; место — по содержимому строк | docs | [TASK_99](https://docs.google.com/document/d/1RFadqCs70QvUX2dFZmL98SEtPd1N5sGSEy-hNNrlVwU/edit) | — | done | `85c4b66c` 2026-10-28 · [TASK-99-…](customer_tasks/TASK-99-iOS-восстановление-системного-диалога-разрешения-WebPush.md) (код был сделан 2026-09-29, G4 iPhone — после 🚀 4) · 10 строк уточнений вставлены · COMPONENT_MAP: не требуется — только docs |
| 0.2 | TASK_114 Subtask 1 | Intake TASK_114 + Subtask 1 (3 строки в документах). Код Subtask 2–6 **не делать** до подтверждённого сбоя | docs | [TASK_114](https://docs.google.com/document/d/13Hll7Y_DAdmo-pHBUAL0onJj8IcvloT9LUV-vmSN4wQ/edit) | — | done | `a698be2d` 2026-10-28 · [TASK-114-…](customer_tasks/TASK-114-Запасное-хранилище-и-защита-обращений-к-storage-в-WebView.md) + CBR #114 · строка-уточнение вставлена в `shop-api.md`, ТЗ Mobile UI (#67), ТЗ UX/Perf (#68) · Subtask 2–6 отложены (Q2) · COMPONENT_MAP: не требуется — только docs |
| 0.3 | TASK_118 Subtask 9 | Intake TASK_118 + только Subtask 9: тест длины SMS с реальным хостом, строки-уточнения в ТЗ #39 и #82 | тест + docs | [TASK_118](https://docs.google.com/document/d/1DVbALzcHHRccOAMk3SMJUU1gA7StyB_pxmNA_RhScII/edit) | — | done | `84192185` `4a02b83d` `0344d954` `cccd0187` 2026-10-28 · [TASK-118-…](customer_tasks/TASK-118-SMS-Заказ-готов-история-заказов-CODE-BLACK.md) + CBR #118 · охранный тест: SMS с хостом из `fly.toml` (codeblack.coffee) = 65 ≤ 70 · строка «Уточнение 2026-10-24» в ТЗ #39 и #82 · CI green на `b02e14ba` (по пути починен CI: раннер `ubuntu-24.04`, обновлены гемы по bundler-audit) · COMPONENT_MAP: не требуется — только тест и docs, витрина не тронута |
| 0.4 | TASK_119 этап 1 | Intake TASK_119. Cursor: перечень мест кода с обходом RLS (только чтение). 👤 Владелец: 4 запроса из документа на prod read-only (ответы п. 4) → текст без секретов в `artifacts/` | аудит, без кода | [TASK_119](https://docs.google.com/document/d/1-YuCzTQCuGP_Mvioctw0lCQT1IOtzf1_0lsnZGVXXaA/edit) | 👤 доступ Fly | done | `6e078475` + закрытие 2026-10-28 · [TASK-119-…](customer_tasks/TASK-119-Проверка-безопасности-межточечной-истории-CODE-BLACK-в-production.md) + CBR #119 · [перечень обхода RLS](../artifacts/production_rls_verify/CODE_BYPASS_INVENTORY.md) · [prod read-only](../artifacts/production_rls_verify/PROD_QUERIES_RESULT.md): роль `neondb_owner` с `BYPASSRLS` и владелец всех таблиц → **RLS не действует**; RLS включён на 8 из 98 таблиц, на `orders`/`payments`/`users` выключен · COMPONENT_MAP: не требуется — только docs |
| 1 | TASK_112 | Снимок окружения при открытии витрины (Д9): `pushEnvironment.js`, `event_kind`, таблица событий, endpoint | доп. задача · миграция | [TASK_112](https://docs.google.com/document/d/1zj0HL_Ws1FbqJFQPC3wSuKmo9msLYN8qrjLqV63afEI/edit) | — | done | `ad527706` `aea57923` `01753c2c` `277fcf5c` `ed9d6562` `aa525f50` 2026-10-28 · [TASK-112-…](customer_tasks/TASK-112-Снимок-окружения-при-открытии-витрины.md) + CBR #112 · витрина один раз за вкладку шлёт снимок окружения в `POST /shop/api/environment_events` → таблица `shop_environment_events` + view `v_shop_environment_events` (Metabase — Q4) · на review закрыто: в prod эндпоинт был бы под CSRF/API key (sendBeacon без заголовков → 401), тело ограничено до Rails · CI green [40662246296](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40662246296) на `61e53c83` · события в базе — после 🚀 1 · COMPONENT_MAP: не требуется — `App.svelte`/`shopTenantHeader.js` вне зоны карты (CartSheet/OrderStatus*/GuestOrder* не тронуты) |
| 2 | TASK_92 Патч 1 | Ready-пуш не теряется при сбое доставки (Д1) | патч → конец `TASK-92-…md` | [TASK_92](https://docs.google.com/document/d/1GlRrdNGaXuSTTCYEKBN1dem8hB0A0WPnC2w9O_gi-mc/edit) | — | done | `e3915c6d` `0758b973` `799fd4a9` `4acc0f9f` `d687c6e8` `401b8927` `95889e7c` 2026-10-28 · тело TASK_92 (Subtask 1–16) и Патч 1 дословно в [TASK-92-…](customer_tasks/TASK-92-Production-background-FCM-и-синхронизация-статусов-заказа.md) + CBR #92 · временная ошибка FCM (5xx/429, сеть, таймаут, OAuth) → claim снимается, повтор до 5 раз (10 с / 30 с / 2 мин / 5 мин) с исходным временем claim; недействительный токен — без повтора; Wallet/APNs не блокирует FCM; записи push не остаются `pending` · crit-audit CLEAN · CI green [40672687152](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40672687152) на `95889e7c` · Android E2E — после 🚀 1 · COMPONENT_MAP: да — строка `FcmClient` (новая граница `TransientError` ↔ повтор `ReadyPushJob`) |
| 3 | TASK_92 Патч 2 | Push при отмене заказа: tag, текст по инициатору (Д5) | патч → после Патча 1 | [TASK_92](https://docs.google.com/document/d/1GlRrdNGaXuSTTCYEKBN1dem8hB0A0WPnC2w9O_gi-mc/edit) | 2 | done | `0709834d` `47eed912` `5ec173a4` `6d95763e` `02bd5cd6` `1c03aa69` `c0fed5af` `5a5619aa` `3dc5f126` 2026-10-28 · Патч 2 дословно в конец [TASK-92-…](customer_tasks/TASK-92-Production-background-FCM-и-синхронизация-статусов-заказа.md) + CBR #92 · push `cancelled` из accepted/preparing/ready → только `tag: order-<id>` (без actions/progress), заменяет прежнее уведомление; из `pending_payment` push нет; гостю «Вы отменили заказ», бариста — прежний текст; `OrderCancellationPresenter` (API/Cable) не тронут · crit-audit CLEAN · Entire `01M6130ZX1S5EKZZHHR9PCT2X5` · CI green [40677574862](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40677574862) на `3dc5f126` · Android E2E — после 🚀 1 · COMPONENT_MAP: да — строка `OrderStatusPushNotifier + OrderStatusPushPayload` (cancelled tag-only, без push из pending_payment) |
| 4 | TASK_115 | CODE:BLACK — явное членство точек в сети (A v4): миграция, форма, журнал. Чтение признака из клиентского контекста — после 0.4 | доп. задача · миграция | [TASK_115](https://docs.google.com/document/d/1cEfAVfO7mL39eBpWtRMTwYPvQIkHGHC_-vaAzCmOf8c/edit) | — (часть — 0.4) | in_progress | intake 2026-10-28 · [TASK-115-…](customer_tasks/TASK-115-CODE-BLACK-явное-членство-точек-в-сети.md) + CBR #115 · шапка документа = строка очереди |
| 5 | TASK_120 | Корзина при переходе в другую точку (F v3) | доп. задача | [TASK_120](https://docs.google.com/document/d/1Uz11weI_haC7SRlIdKt1teEloqz3QID_iWknF4609dM/edit) | — | todo | |
| 🚀 1 | Деплой 1 | Шаги 1–5. После: 👤 Android E2E TASK_92 (Subtask 16, дубль схлопывается по tag); события TASK_112 видны в базе | deploy | — | 1–5 | todo | |
| 6 | TASK_90 Патч 2 | default ≠ denied (Д2) | патч → конец `TASK-90-…md` | [TASK_90](https://docs.google.com/document/d/1YtZzj-Lf2HHrM4azejIuZISTKsWdu8q6y-kPHvm_d44/edit) | 1 | todo | |
| 7 | TASK_108 | Диагностика push только по флагу (Д3) | доп. задача | [TASK_108](https://docs.google.com/document/d/1-R9rUy4zy0sLdo9hM3r1xhqy4hvP00kxqLNqwFhWd2I/edit) | 6 | todo | |
| 8 | TASK_113 | Push-код устойчив к недоступному хранилищу (Д10) | доп. задача | [TASK_113](https://docs.google.com/document/d/1rWjRNPguPkcFr3lZ4v9xvjDlW1FwtlLnKcwEws7qOyc/edit) | 6, 7 | todo | |
| 🚀 2 | Деплой 2 | Шаги 6–8. **До деплоя:** 👤 ручной тест на iPhone, пока диагностика ещё видна (условие TASK_108). После: жест включает диагностику | deploy | — | 6–8 + 👤 iPhone | todo | |
| 9 | TASK_109 | Определение окружения для push и единый вход на двух экранах заказа (Д7a) | доп. задача | [TASK_109](https://docs.google.com/document/d/13KxN_U7XjGfdsFojHFoBnZUBrIWH843XdB4OQ14kDr0/edit) | 1, 6, 7, 8 | todo | |
| 🚀 3 | Деплой 3 | Шаг 9. После: можно выставить `WALLET_FORCE_UNAVAILABLE` (секрет prod — только по апруву) | deploy | — | 9 | todo | |
| 10 | TASK_110 | Предварительный экран перед системным запросом уведомлений (Д7b) · **реверс** решения #37 шаг 5 | доп. задача · реверс | [TASK_110](https://docs.google.com/document/d/1egmnNNtibkrI-11u1X4o9AdS_TyeQ2zx42xyXLacaho/edit) | 1, 6, 7, 8, 9 | todo | |
| 11 | TASK_111 | Путь iPhone к уведомлениям: плашка установки на главный экран (Д8) · **реверс** «Wallet на паузе» 22.09 | доп. задача · реверс | [TASK_111](https://docs.google.com/document/d/15pMZBaV5JeHDv_0sgzty7n64Mapc_I2dicZEG1agru8/edit) | 1, 9 | todo | |
| 🚀 4 | Деплой 4 | Шаги 10–11. После: 👤 приёмка Android + iPhone (standalone); iPhone закрывает G4 TASK_99 | deploy | — | 10–11 | todo | |
| 12 | TASK_121 (без Subtask 8) | Повтор заказа из истории с проверкой цен в текущей точке (G v3, R10) | доп. задача (EXT TASK_94) | [TASK_121](https://docs.google.com/document/d/1PE0qQOQD3P2khmm19K8w0s1awGl9hOmQJkK90oVEKLQ/edit) | — | todo | |
| 🚀 5 | Деплой 5 | Шаг 12 (можно объединить с деплоем 6 — решение владельца) | deploy | — | 12 | todo | |
| 13 | TASK_116 | История заказов клиента по всем точкам CODE:BLACK (B v5) | доп. задача | [TASK_116](https://docs.google.com/document/d/1W0uXR3bzAUmYg5W79T4Rb-jMDanuIJ0TZX8BgSKh70s/edit) | 4, 0.4 (результат 👤), 12 | todo | |
| 13a | TASK_119 этап 2 | Исправления RLS — **только** если этап 1 показал, что RLS действует. Текст этапа 2 формулирует заказчик после результатов 0.4 | патч/задача — по документу | [TASK_119](https://docs.google.com/document/d/1-YuCzTQCuGP_Mvioctw0lCQT1IOtzf1_0lsnZGVXXaA/edit) | 0.4 | todo | итог 0.4: RLS к роли приложения **не** применяется → условие строки не выполнено; нужен ли этап 2 — Q3 |
| 🚀 6 | Деплой 6 | Шаги 13 (+13a). **До деплоя:** 13a закрыт или признан ненужным | deploy | — | 13, 13a | todo | |
| 14 | TASK_117 | Безопасное подтверждение смены клиентской сессии по SMS-ссылке (C v3) | доп. задача | [TASK_117](https://docs.google.com/document/d/1_QJ0B8nlKzpObvVR4MT0S22IS-xDAoyQN_xAAOX7WgA/edit) | 1, 5, 0.4; приёмка Subtask 4 — после 13 | todo | |
| 15 | TASK_118 | SMS «Заказ готов» → история заказов CODE:BLACK (D v4), кроме Subtask 9 (сделан в 0.3) | доп. задача (EXT #39, #82) | [TASK_118](https://docs.google.com/document/d/1DVbALzcHHRccOAMk3SMJUU1gA7StyB_pxmNA_RhScII/edit) | 2, 4, 5, 13, 14, 0.4 | todo | |
| 16 | TASK_121 Subtask 8 | Повтор заказов других и закрытых точек | доп. задача (продолжение 12) | [TASK_121](https://docs.google.com/document/d/1PE0qQOQD3P2khmm19K8w0s1awGl9hOmQJkK90oVEKLQ/edit) | 12, 13 | todo | |
| 🚀 7 | Деплой 7 | Шаги 14–16. После: 👤 SMS-ссылка на телефоне end-to-end | deploy | — | 14–16 | todo | |

**Не отправлять (решение заказчика):** Д4 и Д6 (парковка, каскад) · код TASK_114 Subtask 2–6 — до подтверждённого сбоя.

## Метки внутри документов ↔ ID заказчика

Документы ссылаются друг на друга метками. В репо, CBR, коммитах и отчётах — только ID заказчика.

| Метка | ID | Буква в порядке |
|---|---|---|
| TASK-PUSH-ENV-SNAPSHOT | TASK_112 | Д9 |
| TASK-PUSH-DIAG-GATE | TASK_108 | Д3 |
| TASK-PUSH-STORAGE-SAFE | TASK_113 | Д10 |
| TASK-PUSH-ENV-GATE | TASK_109 | Д7a |
| TASK-PUSH-PREPROMPT | TASK_110 | Д7b |
| TASK-IOS-PUSH-PATH | TASK_111 | Д8 |
| TASK-STORAGE-FALLBACK-EXT | TASK_114 | Д11 |
| Патч 1 / Патч 2 TASK_92 | TASK_92 | Д1 / Д5 |
| Патч 2 TASK_90 | TASK_90 | Д2 |
| TASK-CODE-BLACK-NETWORK-MEMBERSHIP | TASK_115 | A |
| TASK-CODE-BLACK-CROSS-POINT-ORDER-HISTORY | TASK_116 | B |
| TASK-SHOP-SMS-SESSION-TRANSITION-EXT | TASK_117 | C |
| TASK-39-SMS-READY-LINK-ORDER-HISTORY-EXT (SMS → история) | TASK_118 | D |
| TASK-PRODUCTION-RLS-VERIFY-HARDEN | TASK_119 | E |
| TASK-SHOP-CART-ON-TENANT-SWITCH | TASK_120 | F |
| TASK-HISTORY-REPEAT-PRICE-CHECK-EXT | TASK_121 | G |

## Ручные шаги владельца (👤)

| Когда | Что |
|---|---|
| Шаг 0.4 | 4 запроса TASK_119 на prod read-only (`fly ssh console` → `psql` с `SET default_transaction_read_only = on`), результат текстом без секретов |
| После 🚀 1 | Android: заказ в фоне, accepted → preparing → ready, уведомление в шторке, один action |
| До 🚀 2 | iPhone: проверка с диагностикой, пока она видна |
| После 🚀 4 | Android + iPhone (установленное приложение): предварительный экран, плашка установки, push; G4 TASK_99 |
| После 🚀 7 | SMS «Заказ готов» → ссылка → история с выделенным заказом |
| Каждый 🚀 | Апрув деплоя |

## Открытые вопросы

| # | Вопрос | Блокирует | Статус |
|---|---|---|---|
| Q1 | Рабочая копия: незакоммиченный отладочный лог (`# region agent log`, sessionId `896a0d`, брошенный чат 2026-10-06/07 про табло) в 4 файлах + `debug-896a0d.log`; пустые `caramel`, `vanilla`, `{`, `typescript`; два незакоммиченных артефакта приёмки (август) | — | **закрыт 2026-10-28:** отладка → `git stash` «debug 896a0d …» (вернуть: `git stash list` → `git stash pop stash@{N}`), пустые файлы удалены, артефакты закоммичены, рабочая копия чистая |
| Q2 | TASK_114 Subtask 3 (открытый вопрос в самом документе): если storage недоступен, состояние оплаты живёт только в памяти и не переживёт возврат из банка (СБП, редирект). Что делать с таким возвратом? | код TASK_114 Subtask 2–6 (и так отложен до данных TASK_112 / сбоя на устройстве) | открыт |
| Q3 | TASK_119 этап 1 показал: в production RLS не действует (роль `neondb_owner` с `BYPASSRLS`, владелец всех таблиц; RLS включён на 8 из 98 таблиц). Изоляция точек — только кодом. Нужен ли этап 2 (шаг 13a) и что в нём: оставить защиту кодом / привести RLS к миграциям / отдельная роль приложения с работающим RLS (тогда сначала правка мест из перечня обхода)? | шаг 13a, 🚀 6 («13a закрыт или признан ненужным») | открыт |
| Q4 | TASK_112 Subtask 9: отчёт «в Metabase», но Metabase в проекте нет (ни в коде, ни в инфраструктуре). Шаг 1 делает таблицу событий и view `v_shop_environment_events`. Где развёрнут Metabase и кто подключает его к Neon (лучше отдельной read-only ролью)? | приёмка Subtask 9 TASK_112 (не код) | открыт · решение владельца 2026-10-28: делаем только view, подключение — отдельно |
