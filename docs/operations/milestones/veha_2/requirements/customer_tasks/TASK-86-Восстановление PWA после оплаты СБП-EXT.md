# TASK_86: Восстановление PWA после оплаты СБП — EXT

**CBR:** #86 · **Дата intake:** 2026-09-15  
**Источник:** Google Doc + правки заказчика (чат)  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sbp_pwa_recovery_after_bank_ext/  
**Google Doc:** https://docs.google.com/document/d/1i12UGabEH3UJQrR9y7tQS9ONZMvOxG_ARCg3bKcdDoU/edit?usp=drivesdk  
**Расширяет:** [`Интеграция Т-Кассы СБП и токенизации в PWA CODE BLACK.md`](Интеграция%20Т-Кассы%20СБП%20и%20токенизации%20в%20PWA%20CODE%20BLACK.md)  
**Связь:** reopen / split из #79 — [`Надписи автоплатежа и экран после возврата из банка СБП.md`](Надписи%20автоплатежа%20и%20экран%20после%20возврата%20из%20банка%20СБП.md)  
**Статус:** Spec (Google) · intake `[x]` · `/spec` → todo

---

## Текст заказчика (дословно) — правки

Задачи по правкам:

7/  надписи по ответу от банка- авто платеж статусы сломаны, нет нихуя
проверить оплаты 11,8 сбп 
Вернулись, но не понятно через сколько дней 

не ясно какой экран подкинуть  после перехода в сайт приложение  БОЛЬШАЯ ПРОБЛЕМА!!  проверял на андроиде
По моему это хуйня, как задача, или она реализована и я не понял, что все - ок

возможно отправлять смс с ссылкой на гл экран со статусами, задача по бесшовному восстановлению нихуя не вышло возможно на IOS - нужен тест 
Это реализовать, как задачу к каскадной рассылке

---

## Текст задачи (дословно) — Google Doc Spec

# TASK_86:Восстановление PWA после оплаты СБП-EXT.md 
Тип: новая задача (сценарий не был полностью зафиксирован в исходной задаче)
Расширяет: docs/operations/milestones/veha_2/requirements/customer_tasks/Интеграция Т-Кассы СБП и токенизации в PWA CODE BLACK.md
Основание: аудит восстановления PWA после СБП, read-only
Платформы: Android + iOS
Статус: Spec
Платформенные различия Android/iOS на этапе Spec не разделяются на отдельные задачи. Сначала реализуется и проверяется общий recovery-сценарий. Если device-тесты после реализации покажут различия, требующие отдельного поведения, создаются отдельные патчи/доп.задачи по правилам проекта.
Бизнес-цель:
Обеспечить восстановление пользовательского платежного состояния после перехода из PWA в СБП/нативное банковское приложение независимо от того, сохранился ли исходный browsing context PWA. Пользователь должен после завершения оплаты либо вернуться в PWA, либо повторно открыть PWA и получить актуальный результат платежа без потери orderId и без необходимости начинать оплату заново.

## 1. Карта интеграций — затронуто / нет
### Затронуто
Существующий платежный flow:
PWA → /payments/sbp/init → paymentUrl → qr.nspk.ru → СБП/банк → webhook → Payment.status/order.status → PWA recovery → GET /payments/status/:orderId
Используемые существующие backend-механизмы:
1. SBP init;
1. payment_url;
1. webhook Т-Кассы;
1. сохранение статуса платежа;
1. GET /payments/status/:orderId.
### Не требуется менять в рамках этой задачи
1. алгоритм инициации SBP;
1. /payments/sbp/init;
1. webhook Т-Кассы;
1. источник истины статуса платежа в БД;
1. SHA-256/Token validation;
1. существующую бизнес-логику CONFIRMED/REJECTED/CANCELED;
1. токенизацию/RebillId;
1. card payment flow.
Граница: задача решает восстановление frontend/PWA после ухода в SBP/банк. Backend payment processing не переписывается.

## 2. Карта компонентов
### Затронутые компоненты
| Компонент/файл | Назначение | Общий файл с другой задачей | Граница |
| --- | --- | --- | --- |
| App.svelte | lifecycle/recovery PWA | Да | Не ломать существующий guest restore и pageshow-flow |
| Checkout.svelte | запуск SBP flow | Да | Не менять checkout/card flow за пределами SBP recovery |
| PaymentResult.svelte | waiting/result UI | Да | Не менять существующие terminal-status semantics |
| shopSbpPay.js | SBP redirect/status | Да | Не менять backend payment protocol |
| codeblackPendingOrder.js | persistence pending order | Нет/требует проверки карты | Только данные, необходимые для recovery |
| shopGuestSession.js | восстановление ownership/session | Да | Не ломать существующий guest reconnect |
| payments_controller.rb | status API | Да | Только если device/recovery тест выявит реальное ограничение ownership/status |
### COMPONENT_MAP
COMPONENT_MAP.md в рамках Spec не изменять.
После Review и зелёных тестов обновление выполняется отдельно по правилам проекта.
### Не трогать
1. CartSheet;
1. OrderStatusSheet active-orders recovery;
1. Product/catalog visibility polling;
1. card/Rebill payment flow;
1. unrelated PWA install/telemetry lifecycle;
1. существующий guest reconnect, кроме необходимого для восстановления SBP order ownership.

## 3. Текущее поведение — факт
По результатам аудита:
1. Перед переходом в SBP сохраняется codeblack_pending_order с:
  1. orderId;
  1. timestamp.
1. Затем PWA переводит UI в waiting-state и выполняет переход через:
window.location.assign(paymentUrl).
1. paymentUrl ведёт на *.nspk.ru, поэтому исходный document PWA заменяется внешним document.
1. В текущей реализации recovery выполняется через:
  1. visibilitychange;
  1. cold start/onMount;
  1. ручную кнопку «Я оплатил».
1. Backend способен определить финальный статус независимо от frontend:
  1. webhook обновляет БД;
  1. status endpoint выполняет актуализацию статуса.
1. Реальный путь:
PWA → NSPK → bank app → PWA
не покрыт полноценным device E2E.
1. Существующий Gherkin 4.2 описывает hidden → visible, но не фиксирует полный сценарий cross-origin navigation + native bank app + возврат/re-entry.
1. Android/iOS-specific реализации SBP recovery в коде нет.

## 4. Scope
### Разрешено
1. Исследовать и реализовать общий механизм восстановления SBP payment state после:
  1. возврата в существующий PWA context;
  1. восстановления PWA после background;
  1. повторного открытия PWA;
  1. cold start;
  1. повторной загрузки страницы.
1. Использовать существующий codeblack_pending_order либо безопасно скорректировать его, если это необходимо для recovery.
1. Использовать существующий status endpoint как источник актуального frontend payment status.
1. Использовать несколько lifecycle entry points, если это необходимо для корректного общего recovery flow.
1. Добавить защиту от:
  1. повторной проверки одного order;
  1. race condition;
  1. устаревшего pending order;
  1. повторного показа результата;
  1. нескольких lifecycle events.
1. Провести реальные device-тесты на:
  1. Android;
  1. iOS.
1. Зафиксировать фактические различия платформ.
1. Если после реализации Android/iOS требуют разных механизмов — вынести платформенную специфику в отдельные изменения по результатам Review, а не закладывать её заранее.
### Запрещено
1. Не менять backend payment processing без подтвержденной необходимости.
1. Не менять контракт /payments/sbp/init без отдельного основания.
1. Не менять webhook contract.
1. Не менять card/Rebill flow.
1. Не хранить на клиенте:
  1. данные карты;
  1. платежные credentials;
  1. чувствительные данные Т-Кассы.
1. Не считать visibilitychange единственным обязательным механизмом восстановления.
1. Не считать наличие visibilitychange доказательством возврата пользователя из банковского приложения.
1. Не добавлять platform-specific Android/iOS hacks до подтверждения реальным device test.
1. Не ломать существующий guest session reconnect.
1. Не менять COMPONENT_MAP.md до успешного Review.

## 5. Gherkin
### Subtask 1 — сохранение pending payment перед уходом в SBP
Subtask: Given пользователь находится на checkout и инициирует оплату СБП
When backend возвращает валидный paymentUrl и orderId
Then frontend сохраняет pending payment state с orderId и временем создания
And переводит UI в состояние WAITING_FOR_BANK
And выполняет переход на paymentUrl.

### Subtask 2 — recovery при возврате в существующий PWA context
Subtask: Given перед переходом в банк существует валидный codeblack_pending_order
And пользователь возвращается в тот же PWA browsing context
When PWA получает lifecycle event, свидетельствующий о возобновлении приложения
Then recovery запускает получение актуального payment status
And не запускает несколько параллельных проверок одного orderId.
Примечание: конкретное browser lifecycle event (visibilitychange, pageshow, focus или комбинация) не является частью бизнес-контракта и определяется реализацией после device testing.

### Subtask 3 — recovery после cold start
Subtask: Given существует codeblack_pending_order с валидным TTL
When пользователь повторно открывает или перезапускает PWA
Then PWA восстанавливает orderId из persistent storage
And запрашивает актуальный payment status
And показывает результат платежа.

### Subtask 4 — восстановление после завершенного платежа
Subtask: Given существует pending payment
And backend уже получил подтверждение успешной оплаты
When PWA выполняет recovery/status check
Then PWA получает CONFIRMED
And очищает pending payment state
And показывает экран успешной оплаты.

### Subtask 5 — восстановление после отклоненного/отмененного платежа
Subtask: Given существует pending payment
And backend сообщает REJECTED или CANCELED
When PWA выполняет recovery/status check
Then pending payment state очищается
And пользователь получает соответствующий экран ошибки/повторной оплаты.

### Subtask 6 — платеж ещё не завершён
Subtask: Given существует pending payment
And backend сообщает PENDING
When PWA выполняет recovery/status check
Then pending payment state сохраняется
And пользователь остаётся на экране ожидания
And пользователь может повторно запросить статус через существующий механизм Я оплатил.

### Subtask 7 — истекший pending payment
Subtask: Given codeblack_pending_order старше установленного TTL
When PWA запускает recovery
Then pending payment state удаляется
And старый orderId не используется для восстановления
And пользователь не получает устаревший результат платежа.

### Subtask 8 — несколько lifecycle events
Subtask: Given пользователь вернулся из банковского приложения
And браузер генерирует несколько lifecycle events
When recovery получает несколько сигналов
Then для одного orderId выполняется не более одной активной проверки статуса
And race condition не приводит к неправильному UI state
And terminal result не отображается повторно.

### Subtask 9 — сетевой сбой во время recovery
Subtask: Given существует валидный pending payment
When status request завершается сетевой ошибкой
Then payment не считается REJECTED или CANCELED
And pending state сохраняется в пределах TTL
And пользователь остаётся в состоянии ожидания/повторной проверки.

### Subtask 10 — Android device flow
Subtask: Given пользователь использует Android PWA
When выполняется полный flow PWA → NSPK → СБП → банковское приложение → возврат/повторное открытие PWA
Then фактический lifecycle фиксируется в тестовом результате
And recovery корректно восстанавливает payment state.
Обязательно зафиксировать:
1. PWA standalone или browser;
1. браузер;
1. что происходит при переходе в NSPK;
1. запускается ли банковское приложение;
1. что происходит при возврате;
1. какие lifecycle events приходят;
1. сохраняется ли localStorage;
1. происходит ли cold start;
1. какой status/result отображается.

### Subtask 11 — iOS device flow
Subtask: Given пользователь использует iOS PWA
When выполняется полный flow PWA → NSPK → СБП → банковское приложение → возврат/повторное открытие PWA
Then фактический lifecycle фиксируется в тестовом результате
And recovery корректно восстанавливает payment state.
Обязательно отдельно проверить:
1. Safari PWA/standalone;
1. Safari browser tab, если используется;
1. возврат из банковского приложения;
1. lifecycle events;
1. сохранение localStorage;
1. cold start;
1. status/result.

### Subtask 12 — единый cross-platform recovery contract
Subtask: Given Android и iOS прошли device test
When сравниваются результаты recovery
Then общий бизнес-сценарий восстановления остаётся одинаковым
And platform-specific различия документируются отдельно
And platform-specific код добавляется только при подтвержденной необходимости.

## 6. TDD-проверка
### Unit
Проверить:
codeblackPendingOrder
├── save pending order
├── load pending order
├── TTL expiration
├── clear terminal order
├── duplicate lifecycle events
└── concurrent recovery guard

Проверить recovery:
recover pending order
├── CONFIRMED
├── REJECTED
├── CANCELED
├── PENDING
└── network error

### Integration
Проверить:
SBP init
→ pending state
→ redirect state
→ recovery
→ status API
→ result UI

Отдельно проверить:
webhook
→ DB status
→ subsequent PWA recovery
→ correct UI result

### E2E
Минимально:
checkout
→ SBP
→ waiting
→ recovery
→ status
→ result

и:
cold start
→ pending order
→ status
→ result

### Device E2E
Обязательно:
Android:
PWA → NSPK → bank → return/reopen PWA → recovery → result

iOS:
PWA → NSPK → bank → return/reopen PWA → recovery → result

Для device E2E не считать SKIP успешным прохождением сценария.

## 7. Критерии проверки
### Functional
1. Pending order сохраняется до ухода в SBP.
1. Пользователь не теряет orderId.
1. Recovery работает после возврата в существующий context.
1. Recovery работает после cold start.
1. CONFIRMED приводит к success.
1. REJECTED/CANCELED приводят к соответствующему error/retry state.
1. PENDING не приводит к ложному отказу.
1. Сетевой сбой не приводит к ложному terminal status.
1. Истекший pending order не восстанавливается.
### Concurrency
1. Несколько lifecycle events не создают параллельные проверки одного заказа.
1. Terminal result не отображается повторно.
1. Старый order не перезаписывает результат нового заказа.
### Platform
1. Android device flow проверен на реальном устройстве.
1. iOS device flow проверен на реальном устройстве.
1. Результаты Android/iOS зафиксированы отдельно.
1. Если платформы ведут себя одинаково — используется общий recovery flow.
1. Если платформы различаются — различие документировано до внесения platform-specific workaround.

## 8. Exit Criteria
1. Все новые unit/integration тесты зелёные.
1. Frontend E2E recovery tests зелёные.
1. tsc/typecheck зелёный.
1. Lint зелёный.
1. Android device flow выполнен без SKIP.
1. iOS device flow выполнен без SKIP.
1. Для каждого устройства зафиксировано:
  1. способ открытия PWA;
  1. браузер/OS;
  1. lifecycle;
  1. возврат из банка;
  1. сохранение pending state;
  1. итоговый UI.
1. Recovery не зависит исключительно от visibilitychange.
1. Backend payment processing не изменён без отдельного подтверждённого основания.
1. Existing guest reconnect не сломан.
1. Card/Rebill flow не изменён.
1. Review подтверждает отсутствие регрессий в соседних задачах.

## 9. Результат Review
После реализации и device testing принять одно из решений:
### Вариант A — общий механизм
Android и iOS имеют совместимое поведение.
→ Оставить единый cross-platform recovery.
### Вариант B — Android-specific correction
Android требует отдельного поведения.
→ Создать отдельный патч/доп.задачу по результатам фактов device test.
### Вариант C — iOS-specific correction
iOS требует отдельного поведения.
→ Создать отдельный патч/доп.задачу по результатам фактов device test.
### Вариант D — обе платформы различаются
→ Сохранить общий recovery contract и выделить platform-specific implementation changes отдельными задачами.
До получения device evidence нельзя считать Android/iOS различия установленным фактом.

## 10. Не трогать
В рамках этой задачи не изменять без отдельного основания:
1. CartSheet;
1. active orders / OrderStatusSheet;
1. Product visibility polling;
1. card payment;
1. RebillId;
1. Т-Касса webhook contract;
1. Receipt;
1. SHA-256 Token validation;
1. unrelated PWA install flow;
1. business semantics заказа;
1. существующий guest reconnect вне необходимого SBP recovery.
Ключевая граница: задача отвечает за восстановление состояния PWA после ухода пользователя в SBP/банк, а не за изменение самого платежного протокола.

## SBR: Spec → Build → Review — SBP PWA Recovery
### Файлы (ожидаемо)
1. App.svelte
1. Checkout.svelte
1. PaymentResult.svelte
1. shopSbpPay.js
1. codeblackPendingOrder.js
1. shopGuestSession.js
1. связанные payment/recovery tests
1. e2e/payment-flow.spec.ts или фактический существующий E2E-файл
1. device test artifacts для Android/iOS
### Не ломать
1. Card/Rebill flow
1. T-Касса webhook/payment processing
1. OrderStatusSheet / active orders recovery
1. Product/catalog visibility polling
1. guest session reconnect
1. существующие terminal payment statuses
Общая граница: recovery SBP payment state не должен менять бизнес-логику платежа и соседние lifecycle-сценарии.
### Проверка
1. Unit: pending state / TTL / terminal clear / race guard
1. Integration: SBP → pending → status → result
1. E2E: cold start + recovery
1. Device E2E: Android PWA → NSPK → bank → return/reopen → recovery
1. Device E2E: iOS PWA → NSPK → bank → return/reopen → recovery
1. tsc
1. lint
### DoD
1. Unit/integration/E2E зелёные
1. Android device flow проверен без SKIP
1. iOS device flow проверен без SKIP
1. Recovery работает после возврата и cold start
1. Нет race condition при повторных lifecycle events
1. Нет регрессий card/Rebill и guest reconnect
1. Review завершён
1. После Review принято решение по необходимости Android/iOS-specific corrections
1. COMPONENT_MAP.md обновляется только после зелёного Review

---

## Заметки агента

**IN (#86):** бесшовное восстановление PWA после СБП/банка — понятный экран success / error / waiting после возврата или cold start; device E2E Android + iOS без SKIP.

**OUT (#86) — не смешивать в этот SBR:**
- надписи/статусы автоплатежа по ответу банка → остаётся в #79 (и/или отдельные тексты);
- «проверить оплаты 11,8 сбп» / «вернулись, но не понятно через сколько дней» → проверка/копирайт вне recovery UI;
- SMS со ссылкой на гл. экран со статусами → **отдельная задача к каскадной рассылке** (заказчик явно: «как задачу к каскадной рассылке»), не scope #86.

**Факт кода на intake:** `codeblack_pending_order` + visibilitychange/pageshow/cold start уже есть; gap = реальный device path PWA→NSPK→bank→return и ясный result screen (подтверждено жалобой Android).

**Путь:** полный SBR (Spec уже в Google → `/spec` в todo → `/sbr`). Не «просто доп.работа».
