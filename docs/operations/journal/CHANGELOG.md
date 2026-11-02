# CHANGELOG

## Шапка

**Текущий месяц:** `2026-11`  
**Архив:** [`archive/README.md`](archive/README.md) — `CHANGELOG-2026-06.md` … `CHANGELOG-2026-08.md` · **`CHANGELOG-2026-09-early.md`** · **`CHANGELOG-2026-09.md`** (18–30) · **`CHANGELOG-2026-10.md`** (ctx-trim 2026-11-02)

> Агент: **не читать** весь CHANGELOG на старте. Писать новую запись сверху текущего месяца.

---

## Текущий месяц (2026-11)

## 2026-11-02 — feat: TASK_121 Subtask 8 REVIEW — repeat_preview CODE:BLACK (очередь, шаг 16)

- `#repeat_preview` → `CodeBlackCrossPointOrders#find_order!`; цены текущей точки. RED `51c50d5e` → GREEN `70da0ca3`. Local «Проверка» Rails 15/0 + JS 40/0. Ревью диффа вручную (bugbot/security skip). crit-audit CLEAN. Entire `01M6E6SK26KVPBMSJWMAJXCFQ4`. COMPONENT_MAP: да (OrdersController). Без миграции. Не задеплоено (🚀 7).

## 2026-11-02 — ops: эконом-режим пачки приёмки после deploy

- Канон в `coffeeos-dev-gates`: Fly MCP = Chrome DevTools Point A; порядок Sentry→logs→узкий MCP; обязательное vs skip с причиной; запрет молча пропускать hot-path. Отсылки: `coffeeos-index`, `RULES_INDEX`, `agent-workflow`. Код app не тронут.

## 2026-11-02 — docs: SPEC TASK_121 Subtask 8 — повтор заказов других и закрытых точек (очередь, шаг 16)

- Разрыв: `#repeat_preview` = `scope_visible_orders`; `#show` = CodeBlack. План: find через CodeBlack; цены уже по текущей точке; FE без правок. Файлы 2 · Не ломать / Проверка · миграции нет. Код не менялся. Next: `/sbr`.

## 2026-11-02 — docs: intake TASK_121 Subtask 8 — повтор заказов других и закрытых точек (очередь, шаг 16)

- Секция Subtask 8 в `customer_tasks/TASK-121-…md`; Google Docs = локальный 1:1; шаг 16 → `in_progress`; CBR #121; зависимости 12/13 done; статус «ждёт TASK_116» — устаревший снимок. Код не менялся. Next: `/spec`.

## 2026-11-02 — docs: TASK_118 CI green — очередь шаг 15 done

- Push `b96f675b..3e0e1749` · CI [41453248573](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41453248573) + Semgrep/CodeQL green · шаг 15 → `done` · CBR #118. Не задеплоено (🚀 7). Next: `/start` → шаг 16 TASK_121 Subtask 8.

## 2026-11-02 — feat: TASK_118 REVIEW — SMS ready → history CODE:BLACK (очередь, шаг 15)

- Location `#/profile?order=` + `sms_entry` pin; resolve expired/invalid → HTML без bind. RED `7be416af` → GREEN `5422913e`. Local «Проверка» PASS. Ревью диффа вручную (bugbot/security skip). crit-audit CLEAN. Entire `01M6E6SK26KVPBMSJWMAJXCFQ4`. COMPONENT_MAP: нет. Без миграции. Не задеплоено (🚀 7).

## 2026-11-02 — ops: ctx-trim токенов (Sep–Oct archive + шапки + ISSUES)

- CHANGELOG: живой только `2026-11`; архив `CHANGELOG-2026-09.md` + `CHANGELOG-2026-10.md`. HANDOFF/SESSION сжаты; pre-trim в `session/archive/*-pre-trim.md`. ISSUES 🔴 без 🟢 → `ISSUES-resolved-through-2026-10.md`. `ctx_trim: 2026-11-02`. Код не тронут.

## 2026-11-02 — docs: SPEC TASK_118 — SMS ready → history CODE:BLACK (очередь, шаг 15)

- Факты = код; план: resolve expired/invalid; Location `#/profile?order=` + `sms_entry` pin в bootstrap; HTML ошибки без bind; S9 skip. Файлы 6 · Не ломать / Проверка · миграции нет. Код не менялся.

## 2026-11-02 — docs: intake TASK_118 — SMS «Заказ готов» → история CODE:BLACK (очередь, шаг 15)

- Текст уже в `customer_tasks/TASK-118-…md` с шага 0.3; Google Docs = локальный файл 1:1; шаг 15 → `in_progress`; CBR #118; зависимости done; Subtask 9 не повторять. Код не менялся. Next: `/spec`.

## 2026-11-02 — docs: TASK_117 CI green — очередь шаг 14 done

- Push `62f6e539..c44e2058` · CI [41449958217](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41449958217) + Semgrep/CodeQL green · шаг 14 → `done` · CBR #117. Не задеплоено (🚀 7). Next: `/start` → шаг 15 TASK_118.

## 2026-11-02 — docs: explore — не «на всякий», только если пути неясны

- Канон: дефолт без `explore`; звать 1 раз только после узкого поиска, если кандидатов много/пути неясны. Мелочь и пути из ТЗ — без. Правки: `coffeeos-agent-workflow` § explore, `/spec`, SBR, `SUBAGENTS`.

## 2026-11-02 — docs: /regress вне дефолтной цепочки

- После GREEN → `/review` (local зона = шаг 1 PHASE 3, обязательно). Отдельный `/regress` только: пауза без review, пачка патчей, хотфикс без PHASE 3, просьба владельца. Reuse в review если regress только что PASS. Правки: `regress.md`, sbr/unlazy/README, agent-workflow, SBR, skills, AGENTS, PUSH_SMS_QUEUE.

## 2026-11-02 — feat: TASK_117 REVIEW — SMS session transition confirm (очередь, шаг 14)

- Conflict → окно confirm до bind; Location без `reconnect_token`; confirm → clear cart + push/offer caches + `#/profile?order=`. RED `d358c4a2` → GREEN `ff924f2d`. Local «Проверка» Rails 48/0 + JS 12/0. Ревью диффа вручную (bugbot/security skip). crit-audit CLEAN. Entire `01M6E2SNX67JASNF4ZVNFRQCSA`. COMPONENT_MAP обновлён. Без миграции. Не задеплоено (🚀 7).

## 2026-11-02 — docs: SPEC TASK_117 — SMS session transition confirm (очередь, шаг 14)

- Факты = код; план: `SmsSessionTransition` + short link без тихого overwrite + confirm/decline API + FE-диалог/generation; после confirm — история с highlight; `reconnect_token` убрать из SMS Location. Файлы 6 · Не ломать / Проверка · миграции нет. Код не менялся.

## 2026-11-02 — docs: intake TASK_117 — безопасное подтверждение смены сессии по SMS-ссылке (очередь, шаг 14)

- ТЗ сохранено дословно в `customer_tasks/TASK-117-…md` + строка #117 в реестре задач заказчика; шаг 14 очереди → `in_progress`. Суть: SMS-ссылка `/o/:hash` не подменяет клиента сессии без согласия; при другом клиенте в точке заказа — подтверждение до смены; отказ без изменений; при подтверждении — очистка корзины с предупреждением, сброс отметки уведомлений и кэшей профиля/оффера, затем история с выделенным заказом; защита от гонок refresh/reconnect. Миграции нет. Код не менялся.

## 2026-11-02 — docs: TASK_119 шаг 13a / Q3→A — этап 2 не делаем, RLS в backlog

- Решение владельца **A**: условие этапа 2 не выполнено (RLS в prod не действует) → шаг 13a очереди `done` без кода; Q3 закрыт. Включение RLS — отдельный эпик позже: `PRACTICES` **V2-TASK-119-RLS-HARDEN** (B/C). Обновлены очередь, TASK-119, CBR #119, ISSUES 🟡. Не блокер 🚀 5 / 🚀 6. Следующий код — шаг 14 TASK_117.

## 2026-11-02 — docs: TASK_116 CI green — очередь шаг 13 done

- Push `2400053b..ce0baedf`, CI [41444177250](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41444177250) зелёный + Semgrep/CodeQL. Шаг 13 очереди Push + SMS закрыт; следующий по коду — шаг 13a / Q3, затем 🚀 6 (по апруву). Не задеплоено.

## 2026-11-02 — feat: TASK_116 REVIEW — история заказов CODE:BLACK (очередь, шаг 13)

- Ревью диффа вручную (bugbot/security не запускались — решение владельца): 0 находок. crit-audit CLEAN `b64a7657..75055edb`. COMPONENT_MAP: Profile, OrderReceipt, shopAccountOrders, OrdersController. Entire `01M6E2SNX67JASNF4ZVNFRQCSA` на GREEN. Next: push → CI green → шаг 13 `done` → 🚀 6 по апруву (после 13a/Q3).

## 2026-11-02 — docs: bugbot/security — батч + nudge, не блокер

- Канон: не автозапуск на каждый `/review`. Уведомление `⚠️ Субагенты: пора` после 2–3 задач / перед deploy; на оплате/hot-path — настаиваем. Запуск только по просьбе владельца; отсутствие субагентов не стопает push/CI/deploy. Правки: `coffeeos-agent-workflow`, SBR PHASE 3, `dev-gates`, `/review`, `SUBAGENTS`/`AGENTS`, `RULES_INDEX`.

## 2026-11-02 — docs: TASK_116 /regress PASS (очередь, шаг 13)

- Локальная регрессия по todo «Проверка»: Rails 8 файлов 66/0; JS 52/0; rubocop 0; `vite:build` OK. GREEN `75055edb`. Следующий шаг — `/review`. Fly MCP Point A — после 🚀 6.

## 2026-11-02 — feat: TASK_116 — история заказов по точкам CODE:BLACK (очередь, шаг 13)

- Вошедший клиент в точке сети CODE:BLACK видит в ЛК свои заказы и чеки по всем точкам сети (вкл. разные франчайзи и закрытые), с меткой точки; чек другой точки без смены текущей точки. RED `3869881a` → GREEN `75055edb`; Entire `01M6E2SNX67JASNF4ZVNFRQCSA`. Не запушено.

## 2026-11-02 — docs: SPEC TASK_116 — история заказов по точкам CODE:BLACK (очередь, шаг 13)

- Сверка ТЗ с кодом: факты совпали (сдвиги строк после TASK_121). План: сервис выборки по `customer_id` + сеть CODE:BLACK (только если текущая точка в сети), метка точки/`closed` в API, UI в Profile и OrderReceipt, highlight `?order=`; без `shop_city_lookup` и без миграции. todo обновлён (файлы, Не ломать, Проверка). Код не менялся.

## 2026-11-02 — docs: intake TASK_116 — история заказов по всем точкам CODE:BLACK (очередь, шаг 13)

- ТЗ сохранено дословно в `customer_tasks/TASK-116-…md` + строка #116 в реестре задач заказчика; шаг 13 очереди → `in_progress`. Суть: вошедший клиент видит в истории ЛК свои заказы и чеки по всем явно включённым точкам сети CODE:BLACK (включая разные франчайзи и закрытые точки), с меткой точки в строке и чеке; чек другой точки открывается без смены текущей точки и без изменения корзины; выделение заказа по `#/profile?order=<id>` до первого касания, не дольше 3 с. Выборка — `customer_id` сессии + список точек сети на сервере (без `shop_city_lookup`). «Повторить» не меняем (TASK_121). По этапу 1 TASK_119 RLS не действует → чтение кодом с фильтрами; шаг 13a/Q3 шаг 13 не блокирует. Миграции нет. Код не менялся.

## 2026-11-02 — docs: TASK_121 CI green — очередь шаг 12 done

- Push `48412465..3c555276`, CI [41439722267](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41439722267) зелёный + Semgrep/CodeQL. Первая попытка упала на `scan_ruby` (свежие advisories `addressable`/`rack`) — гемы обновлены до 2.9.2 / 3.2.8. Шаг 12 очереди Push + SMS закрыт; следующий — 🚀 5 (по апруву), затем шаг 13 TASK_116. Не задеплоено.

## 2026-11-02 — feat: TASK_121 REVIEW — проверка цен перед повтором из истории (очередь, шаг 12)

- Ревью диффа вручную без bugbot/security-субагентов: 0 находок C1–C5. crit-audit CLEAN `6f13e80c..b64a7657`. COMPONENT_MAP: `historyRepeatAdapter`, `OrdersController#repeat_preview`, новые `historyRepeatPriceCheck` / `HistoryRepeatNotice`. Entire `01M6E12XSECHGEDV4WMJVTHYFX`.

