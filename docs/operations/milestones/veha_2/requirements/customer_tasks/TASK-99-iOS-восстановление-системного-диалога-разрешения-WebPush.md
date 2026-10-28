# TASK_99: iOS: восстановление системного диалога разрешения WebPush

**ID заказчика:** TASK_99 · **CBR:** #99 · **Дата intake:** 2026-10-28 (шаг 0.1 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/ios_webpush_permission/ (ledger `GATES.md`)  
**Google Doc:** https://docs.google.com/document/d/1RFadqCs70QvUX2dFZmL98SEtPd1N5sGSEy-hNNrlVwU/edit  
**Статус:** код сделан 2026-09-29 до intake — GREEN `48fa2646` · REVIEW `0a3ac0db` (bugbot/security 0, CI green) · на проде с Fly v504 · G1–G3 PASS · **G4 физический iPhone — pending** (после 🚀 4 очереди, только standalone) · G5 Fly MCP — bundle PASS (v504)

---

## Текст задачи (дословно) — Google Doc Spec

TASK_99: iOS: восстановление системного диалога разрешения WebPush

Бизнес-цель: Исправить подписку на WebPush на iOS, чтобы при нажатии пользователем «Разрешить уведомления» системный диалог разрешения iOS открывался непосредственно из user gesture. После выдачи разрешения существующий flow получения и регистрации push-токена должен продолжать работать без изменений backend-контрактов.

## 1. Связь с картой интеграций

- **Затронутые сервисы из `@INTEGRATIONS.md`:** Firebase WebPush / FCM — только frontend-последовательность получения permission и последующей регистрации push-токена.
- **Смежные модули, которые НЕЛЬЗЯ ломать:** существующая регистрация push-токена на сервере, backend push-уведомления, Apple Wallet / PassKit, SMS-каскад.

Изменение внешнего контракта интеграции не требуется. Меняется только порядок frontend-операций до получения разрешения.

## 2. Связь с картой компонентов

- **Затронутые компоненты из `@COMPONENT_MAP.md`:** `registerShopPush()` в `app/frontend/lib/firebasePush.js`; flow подписки из `app/frontend/lib/orderStatusNotifyActions.js`.
- **Общий файл с другой задачей:** нет. Другие задачи, упомянутые в исходном описании, являются контекстом и не входят в текущую задачу.
- **Новый компонент (не в карте):** нет.

## 3. Разрешенный и Запрещенный Scope

- **Разрешено менять/создавать:**
  - `app/frontend/lib/firebasePush.js`
    - изменить порядок операций внутри `registerShopPush()`;
    - оставить синхронную проверку `"Notification" in window` перед запросом permission;
    - сделать `Notification.requestPermission()` первым асинхронным вызовом в цепочке;
    - перенести `isSupported()` и `firebaseClientConfigured()` после получения `permission === "granted"`;
    - сохранить существующий `getToken()` и регистрацию токена после успешного permission.
  - `app/frontend/lib/orderStatusNotifyActions.js`
    - заменить динамический `await import("./firebasePush.js")` в пути подписки через аккордеон на статический импорт;
    - не менять остальную логику аккордеона.
  - `order_status_push_subscribe_test.mjs`
    - добавить/изменить тесты, проверяющие порядок вызовов;
    - добавить/изменить тест пути подписки через аккордеон.

- **Строго запрещено менять:**
  - backend `OrderStatusPushNotifier`;
  - `ReadyPushJob`;
  - `FcmClient`;
  - API и контракт регистрации push-токена;
  - PassKit / Apple Wallet;
  - `WALLET_SIMULATE`;
  - SMS-каскад;
  - хранение `push_enabled` / `push_token` в БД;
  - бизнес-логику `getToken()` после получения `granted`;
  - любые изменения, не связанные с устранением асинхронного барьера перед `Notification.requestPermission()`.

## 4. Сценарии и Чек-лист (Gherkin)

- [ ] **Subtask 1: Сделать `requestPermission()` первым async-вызовом**
  - Given: пользователь на iOS нажимает кнопку подписки на уведомления, а `Notification` доступен в `window`.
  - When: вызывается `registerShopPush()`.
  - Then: после синхронной проверки `"Notification" in window` вызывается `Notification.requestPermission()` без единого `await` перед ним; `isSupported()` и `firebaseClientConfigured()` до permission не вызываются.

- [ ] **Subtask 2: Перенести проверки Firebase после получения permission**
  - Given: `Notification.requestPermission()` вернул `granted`.
  - When: продолжается выполнение `registerShopPush()`.
  - Then: после получения `granted` вызываются `isSupported()` и `firebaseClientConfigured()`, после чего выполняется существующий flow `getToken()` и регистрации токена.

- [ ] **Subtask 3: Сохранить корректное поведение при отказе**
  - Given: `Notification.requestPermission()` вернул `denied` или `default`.
  - When: `registerShopPush()` завершает обработку результата permission.
  - Then: `isSupported()`, `firebaseClientConfigured()` и `getToken()` не вызываются; функция завершается без необработанной ошибки.

- [ ] **Subtask 4: Сохранить обработку неподдерживаемого Notification API**
  - Given: `Notification` отсутствует в `window`.
  - When: вызывается `registerShopPush()`.
  - Then: `Notification.requestPermission()` не вызывается, функция завершается через существующую ветку unsupported environment без необработанной ошибки.

- [ ] **Subtask 5: Убрать async import перед регистрацией из аккордеона**
  - Given: пользователь запускает подписку на уведомления через аккордеон активных заказов.
  - When: выполняется обработчик подписки.
  - Then: `firebasePush.js` подключается через статический импорт, `await import("./firebasePush.js")` отсутствует в этом пути, а вызов `registerShopPush()` может сразу выполнить `Notification.requestPermission()` из user gesture.

- [ ] **Subtask 6: Зафиксировать порядок вызовов тестом**
  - Given: в тесте замокированы `Notification.requestPermission()`, `isSupported()`, `firebaseClientConfigured()` и `getToken()`.
  - When: вызывается `registerShopPush()` при результате permission `granted`.
  - Then: тест проверяет порядок `requestPermission → isSupported → firebaseClientConfigured → getToken`, а не только факт вызова функций.

- [ ] **Subtask 7: Проверить существующий frontend flow**
  - Given: измененный frontend-код и существующий набор тестов push-подписки.
  - When: запускаются целевые тесты.
  - Then: проходят сценарии `granted`, `denied`, `default`, unsupported environment и подписка из аккордеона; backend-контракт и регистрация токена после `granted` не изменены.

- [ ] **Subtask 8: Проверить production flow на физическом iPhone**
  - Given: сборка установлена на физический iPhone, у приложения ранее нет разрешения на уведомления.
  - When: пользователь нажимает «Разрешить уведомления».
  - Then: системный диалог iOS появляется непосредственно после клика; после выбора «Разрешить» приложение появляется в `Настройки → Уведомления`, а существующий flow сохраняет push-токен на сервере.

## 5. Команды TDD-проверки

- **Запуск тестов:** `npm test -- order_status_push_subscribe_test.mjs`
- **Проверка типов:** `npm run typecheck`

## iOS: восстановление системного диалога разрешения WebPush

## SBR
Текущая фаза: SPEC

## Файлы (ожидаемо)
- app/frontend/lib/firebasePush.js
- app/frontend/lib/orderStatusNotifyActions.js
- order_status_push_subscribe_test.mjs

## Не ломать
- backend OrderStatusPushNotifier
- ReadyPushJob
- FcmClient
- API/контракт регистрации push-токена
- PassKit / Apple Wallet
- WALLET_SIMULATE
- SMS-каскад
- push_enabled / push_token в БД
- существующий getToken() и register flow после granted
- остальную бизнес-логику аккордеона
- не вносить изменения, не связанные с устранением async-барьера перед Notification.requestPermission()

## Проверка
- npm test -- order_status_push_subscribe_test.mjs
- npm run typecheck
- production smoke-test на физическом iPhone

## DoD
- Notification.requestPermission() является первым асинхронным вызовом после синхронной проверки Notification API.
- Перед requestPermission() нет ни одного await.
- isSupported() и firebaseClientConfigured() выполняются только после permission === granted.
- В пути аккордеона отсутствует await import("./firebasePush.js").
- Тест проверяет порядок вызовов requestPermission → isSupported → firebaseClientConfigured → getToken.
- Сценарии granted / denied / default / unsupported проходят.
- На физическом iPhone системный диалог разрешения появляется непосредственно после клика.
- После granted существующий flow сохраняет push-токен на сервере.

---

## Заметки агента

- Файл ТЗ создан 2026-10-28 по [ответам заказчика](../../artifacts/push_sms_task_order/customer_answers_2026-10-28.md) п. 2; код задачи сделан раньше по тексту из чата (2026-09-29): GREEN `48fa2646`, REVIEW `0a3ac0db`, ledger `artifacts/ios_webpush_permission/GATES.md` (G1–G3 PASS, G4/G5 pending), прод — Fly v504 ([MCP_RESULT](../../artifacts/mcp/fly_v504_2026-09-29/MCP_RESULT.md)).
- Чекбоксы Subtask в тексте заказчика не отмечаем — статус ведём в шапке и в `GATES.md`.
- Ниже — строки «Уточнение 2026-10-18» дословно, место по указанию заказчика: «в конец файла».

---

Уточнение 2026-10-18 (§2): «общий файл с другой задачей: нет» неверно: firebasePush.js и orderStatusNotifyActions.js общие с TASK_90 (COMPONENT_MAP.md:33, 36).

Уточнение 2026-10-18 (режимы): режим вкладки Safari на iPhone не описан: в нём Notification отсутствует (firebasePush.js:85-88), кнопку там скрывает TASK-PUSH-ENV-GATE (Subtask 2). G4 проверяется только в установленном приложении (standalone).

Уточнение 2026-10-18 (метки): в коде и тестах метка «#99» относится к этой задаче.
