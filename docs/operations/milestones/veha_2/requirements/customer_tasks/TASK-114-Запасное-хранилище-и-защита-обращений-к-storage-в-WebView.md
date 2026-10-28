# TASK_114: Запасное хранилище и защита обращений к storage в WebView

**ID заказчика:** TASK_114 · **CBR:** #114 · **Дата intake:** 2026-10-28 (шаг 0.2 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec  
**Артефакты:** нет (только текст)  
**Google Doc:** https://docs.google.com/document/d/13Hll7Y_DAdmo-pHBUAL0onJj8IcvloT9LUV-vmSN4wQ/edit  
**Статус:** Subtask 1 (docs) — done 2026-10-28 · Subtask 2–6 (код) — **отложены** до данных TASK_112 (доля сессий с недоступным storage) или подтверждённого сбоя на устройстве + ответа по открытому вопросу Subtask 3

---

## Текст задачи (дословно) — Google Doc Spec

TASK_114: Запасное хранилище и защита обращений к storage в WebView

**Расширяет:** docs/operations/milestones/veha_2/requirements/customer_tasks/Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser.md (#66, Definition of Done, строка 134: «Cookies и storage работают либо имеют безопасный fallback»; сценария Given/When/Then для этого пункта в #66 нет)
**Реверсирует:** не применимо
Бизнес-цель: в окружениях с ограниченным storage витрина и оформление заказа не падают, а документы описывают фактическое поведение.

## 1. Карта интеграций — затронуто / нет
Затронуто: клиентские обращения к storage в оплате (tbankPayment.js), ожидающем заказе (codeblackPendingOrder.js), повторе (repeatInvalidTokenStore.js); тексты документов.
Не затронуто: backend, API, tenant, платёжная бизнес-логика, контракт Т-Банка, регистрация push.

## 2. Карта компонентов
safeWebStorage и probeStorage (shopWebView.js:33-53): существуют, не подключены.
tbankPayment.js (:18, :31), codeblackPendingOrder.js (:10-11, :33, :43, :64), repeatInvalidTokenStore.js (:28-29, 41, 47, 54, 57, 59, 61-65, 73, 80, 139, 144-145).
Общий файл с другими задачами: да (оплата, повтор заказа, TASK_94). Граница: меняется только способ доступа к storage; логика оплаты и повтора не меняется.
Граница с #66: Subtask 9 (tenant_id в WebView, строки 85-88) и Subtask 17 (повторное открытие без чужого tenant_id и state, строки 117-120) не меняются.
Граница с Д9: TASK-PUSH-ENV-SNAPSHOT измеряет доступность storage собственной пробой и не использует safeWebStorage и probeStorage.
Новый компонент: нет. В COMPONENT_MAP строк для shopWebView.js и deviceDetect.js нет: добавить после Review.

## 3. Текущее поведение (факт, не требование)
safeWebStorage создан в ca9c5834 (#66), в рабочем коде не используется, причина не записана; тестами покрыт только вариант session без интеграции. DoD #66 (строка 134) пункт о fallback заявляет, а фактически в рантайме только try/catch. Документы утверждают то же: docs/integrations/shop-api.md:225, задача UX/Perf (:246), задача Mobile UI (:193). Кеш каталога защищён (catalog.js:29-48, shopLocalStorage.js:29-40). Перечисленные обращения в оплате и повторе заказа без защиты. Не проверено: стоит ли savePaymentSession (Checkout.svelte:516) внутри внешнего try. Доказательств сбоя на реальных устройствах нет.

## 4. Scope
Разрешено: подключение safeWebStorage или локальная защита в перечисленных файлах; тесты; датированные уточнения в трёх документах.
Запрещено: логика оплаты и повтора, контракт Т-Банка, tenant, API, push (это TASK-PUSH-STORAGE-SAFE), desktop-интерфейс без тестов регрессии, переписывание закрытых документов (допустима одна строка-уточнение).

## 5. Gherkin
Сейчас (документы):
- [ ] Subtask 1: Given документы утверждают наличие memory fallback, When открывается любой из трёх документов, Then в нём есть датированная строка-уточнение: «2026-10-15: в рантайме подключён только try/catch, memory fallback не подключён; см. TASK-STORAGE-FALLBACK-EXT».
Отложено до подтверждённого сбоя на устройстве (код):
- [ ] Subtask 2: Given storage бросает исключение при обращении, When гость открывает витрину и оформляет заказ, Then оформление не падает с исключением.
- [ ] Subtask 3: Given storage недоступен, When сохраняется состояние оплаты, Then оплата стартует, ошибка гостю не показывается. [ОТКРЫТЫЙ ВОПРОС: состояние в памяти не переживёт возврат из банка (СБП, редирект); нужно решение, что делать с возвратом без сохранённого состояния]
- [ ] Subtask 4: Given storage недоступен, When используется ожидающий заказ и повтор, Then обращения не бросают исключений.
- [ ] Subtask 5: Given storage исправен, Then поведение прежнее.
- [ ] Subtask 6: Given тесты задачи, Then есть тест с недоступным storage на уровне витрины и оплаты (сейчас только функция изолированно).

## 6. TDD-проверка: команды
Subtask 1: проверка документов, без тестов.
Subtask 2–6: npm test -- --run (в том числе shop_telegram_webview); npm run lint; npm run typecheck. Ручная проверка: Chrome с блокировкой данных сайта, Safari в приватном режиме, Telegram WebView.
Условие запуска Subtask 2–6: данные Д9 (доля сессий с недоступным storage) или подтверждённый сбой на устройстве.
Документ частично готов к билду: Subtask 1 готов, Subtask 2–6 ждут триггера и ответа по Subtask 3.

---

## Заметки агента

- Метка `TASK-STORAGE-FALLBACK-EXT` в строке Subtask 1 = эта задача (TASK_114). Строка вставлена дословно, метку не меняли.
- **Subtask 1 сделан при intake (2026-10-28, шаг 0.2 очереди).** Строка-уточнение вставлена рядом с утверждением о fallback:
  - `docs/integrations/shop-api.md` — сразу под таблицей «Telegram WebView runtime (#66)» (строка таблицы про localStorage / sessionStorage — :225, совпало);
  - `UX и Performance мобильной витрины CoffeeOS внутри Telegram WebView.md` — пунктом в «Заметках агента» сразу после :246 («#66 уже: … storage try/catch + memory fallback»);
  - `Адаптация Mobile UI витрины CoffeeOS под Telegram WebView.md` — пунктом в «Заметках агента» сразу после :193 («#66 уже даёт runtime: … storage fallback»).
- DoD #66 (строка 134) не трогали — Subtask 1 называет три документа, #66 среди них нет.
- Сдвиг строк: в `app/frontend/lib/shopWebView.js` сейчас `probeStorage` — :20, `safeWebStorage` — :49 (в документе :33-53). Использование вне тестов не найдено — только `test/javascript/shop_telegram_webview_test.mjs`. Остальные номера строк сверяем на `/spec`, когда код будет разблокирован.
- Subtask 2–6 по [очереди](../PUSH_SMS_QUEUE.md) не делаем («код TASK_114 Subtask 2–6 — до подтверждённого сбоя»). Триггер — данные TASK_112 (Д9) или сбой на устройстве; плюс нужен ответ заказчика по открытому вопросу Subtask 3 (возврат из банка без сохранённого состояния).
- COMPONENT_MAP: строки для `shopWebView.js` / `deviceDetect.js` документ просит добавить «после Review» — относится к коду Subtask 2–6, сейчас не добавляем.
