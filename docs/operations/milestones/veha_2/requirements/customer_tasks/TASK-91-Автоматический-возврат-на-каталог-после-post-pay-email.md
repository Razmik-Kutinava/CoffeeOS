# TASK_91: Автоматический возврат на каталог после завершения post-pay email-флоу

**CBR:** #93 · **Дата intake:** 2026-09-17  
**Источник:** чат заказчика (п.9 / 9.2) + скрины + Google Doc Spec  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/post_pay_auto_return_catalog_status/  
**Google Doc:** https://docs.google.com/document/d/1nlWXyWV0UcV5X33i0owZixXRJl5d-nF_HwHdjjBVd2o/edit  
**Расширяет:** post-pay success/email-флоу #71 · Continue → `#/` #35  
**Реверсирует:** не применимо (не возвращает settleSuccess → `/order/:id`)  
**Статус:** **SPEC** 2026-09-17 · ждёт `/sbr`

---

## Текст заказчика (дословно) — чат

вот задача на п.2 по флоу возврата после оплаты на гл экран со статусной моделью автоматически

Задачи по правкам:

9/ - напишри если сделали 
9.1 уведомления запрещены в настройках браузера  > нужно перейти в настройки , доделать задачу дописать переход в браузер
https://docs.google.com/document/d/1gBhAA7-xZd0zkEZueOaKrNo8upuk8DfOJLibCt6bvd0/edit?usp=sharing


9.2 Смотри какая х**** по скриншотам видно что при оплате через карточку товара, система не переводит на статусную модель.
Нужно нажать на каталог. После оплаты чтобы перейти.

срин
скрин
Когда покупаешь в автоплатежах повтор. Всё чётко работает. Переход происходит быстро, Не нужно нажимать каталог.
скрин

---

## Текст задачи (дословно) — Google Doc Spec

TASK_91: Автоматический возврат на каталог после завершения post-pay email-флоу

Расширяет: docs/operations/milestones/veha_2/requirements/customer_tasks/TASK-[существующая задача].md
Реверсирует: не применимо. Задача не возвращает удалённый в #71 settleSuccess → /order/:id; она добавляет новый переход после завершения существующего success/email-флоу.
Тип: новая задача / расширение существующего post-pay сценария
Основание: аудит перехода после оплаты → статусная модель от 2026-09-16.
Бизнес-цель: после успешной оплаты сохранить существующий success/email-флоу #71, но после завершения сбора email или явного пропуска автоматически вернуть пользователя на главный экран PWA (#/), где уже существующая статусная модель показывает состояние заказа. Пользователь не должен дополнительно нажимать «В каталог» для продолжения сценария.

1. Карта интеграций — затронуто / нет

Затронуто:
post-pay navigation после завершения PaymentResult;
переход из success/email UI на #/;
последующее отображение существующей статусной модели.

Не затронуто:
платёжный процесс и определение успешности оплаты;
completePaySuccess и переход checkout → payment-result;
SBP bank redirect/recover;
существующая статусная модель;
получение/обновление статусов заказа;
QR / Quick Repeat pay flow;
логика очистки корзины Quick Repeat.

2. Карта компонентов

PaymentResult.svelte
Компонент: затронут.
Отвечает за success screen, email submit/skip и текущий переход на каталог.
Фактические точки:
PaymentResult.svelte:76–99
PaymentResult.svelte:198–207
Общий файл с другими задачами: да.
Граница:
#71 — email-сбор и success screen;
#35 — назначение перехода Continue → #/;
#79/#86 — SBP waiting/recovery.
В рамках этой задачи разрешается изменить только момент перехода после завершения success/email-флоу.
Не изменять контракт checkout → payment-result.

Checkout.svelte
Компонент: не изменять.
completePaySuccess продолжает переводить успешную оплату на:
#/payment-result?status=ok&order_id=…
Факт: Checkout.svelte:436–463.

CartSheet.svelte / OrderStatusSheet.svelte / orderStatusSheet.js
Компоненты: не изменять.
После перехода на #/ должна использоваться уже существующая статусная модель.
Факты:
CartSheet.svelte:453–458
OrderStatusSheet.svelte:230–248
orderStatusSheet.js:85–93

cartSheetStore.js
Компонент: не изменять.
Не менять существующий gate:
isCartSheetRoute
и не добавлять /payment-result в список маршрутов статусной модели только ради этой задачи.
Факт: cartSheetStore.js:97–103.

App.svelte / shopSbpPay.js
Компоненты: не изменять.
SBP recover должен продолжать работать по существующему контракту #79/#86.

3. Текущее поведение — факт

После успешной оплаты checkout переводит пользователя на:
#/payment-result?status=ok&order_id=…
Факт: Checkout.svelte:436–463.
На payment-result выполняется success/email-flow. Автоматического перехода на #/ после его завершения сейчас нет.
Переход на #/ выполняется из PaymentResult.svelte через существующие действия handleEmailSubmit / handleEmailSkip.
Факт: PaymentResult.svelte:76–99.
Существующая статусная модель находится на главном маршруте и не монтируется на /payment-result.
Факты:
cartSheetStore.js:97–103
CartSheet.svelte:81,412
CartSheet.svelte:453–458
Таким образом, сейчас для попадания в статусную модель требуется дополнительное действие пользователя.

4. Scope

Разрешено
Сохранить существующий сценарий:
успешная оплата → payment-result.
Сохранить success screen и email-сбор #71.
Сохранить возможность:
отправить email;
пропустить email-сбор.
После завершения email submit или явного skip автоматически выполнить:
payment-result → #/.
После перехода на #/ использовать существующий CartSheet / OrderStatusSheet без изменения их внутренней логики.
Сохранить существующий переход Continue → #/ как совместимый с #35.

Запрещено
Возвращать старую логику #71:
payment-result → settleSuccess() → /order/:id.
Делать автоматический переход сразу при открытии payment-result, до завершения email/skip-флоу.
Удалять или обходить email-блок #71.
Изменять completePaySuccess только ради данной задачи.
Изменять маршрутизацию SBP recover #79/#86.
Изменять OrderStatusSheet, orderStatusSheet.js или механизм определения статуса заказа.
Добавлять /payment-result в isCartSheetRoute для отображения статусной модели непосредственно на success screen.
Изменять Quick Repeat / QR payment flow #87.
Изменять поведение корзины или clearCartAfterSuccessfulPay, если это не требуется отдельным доказанным дефектом.

Защитная граница #71
Должен сохраниться принцип:
оплата → payment-result → email/skip → только после завершения email/skip → #/
а не:
оплата → payment-result → немедленный auto-redirect.
Защитный тест #71:
email_collection_test.mjs:73–80
должен продолжать проверять отсутствие немедленного settleSuccess/auto-redirect при открытии success screen.

5. Gherkin

Subtask 1 — автоматический переход после отправки email
Subtask 1: Given пользователь успешно завершил оплату и находится на #/payment-result?status=ok,
And отображается success/email screen,
When пользователь отправляет email для чека,
Then email обрабатывается существующим механизмом #71,
And после завершения email-flow система автоматически переводит пользователя на #/,
And пользователь не должен дополнительно нажимать «В каталог».

Subtask 2 — автоматический переход после Skip
Subtask 2: Given пользователь успешно завершил оплату и находится на #/payment-result?status=ok,
And отображается email-блок,
When пользователь выбирает Skip / пропуск email,
Then система автоматически переводит пользователя на #/,
And пользователь не должен дополнительно нажимать «В каталог».

Subtask 3 — статусная модель после автоматического перехода
Subtask 3: Given пользователь завершил email submit или Skip после успешной оплаты,
When система автоматически переводит пользователя на #/,
Then существующая OrderStatusSheet отображается согласно текущим правилам статусной модели,
And статус заказа определяется существующей статусной моделью,
And новая задача не изменяет правила определения/обновления статуса.

Subtask 4 — защита email-флоу #71
Subtask 4: Given пользователь только что открыл #/payment-result?status=ok,
When success screen монтируется,
Then система не должна автоматически переходить на #/ до завершения email submit или Skip,
And существующий email-блок должен остаться доступным.

Subtask 5 — защита старого удаления settleSuccess
Subtask 5: Given успешная оплата завершена,
When пользователь проходит post-pay success flow,
Then система не должна возвращать удалённый в #71 переход settleSuccess() → /order/:id,
And конечным маршрутом после email/Skip должен быть #/.

Subtask 6 — существующий Continue
Subtask 6: Given пользователь находится на success screen и использует существующий CTA «В каталог»,
When CTA выполняется,
Then система продолжает переходить на #/,
And существующий acceptance #35 остаётся зелёным.

Subtask 7 — SBP recover
Subtask 7: Given пользователь проходит SBP waiting/recover flow,
When система восстанавливает pending payment согласно #79/#86,
Then новая автоматизация post-pay email-flow не изменяет существующую SBP recovery/navigation логику.

6. TDD-проверка: команды

Перед Build обязательно проверить существующие защитные тесты #71 и #35.
Минимальный набор:
# Email / PaymentResult
npm test -- email_collection_test.mjs

# Acceptance post-pay / catalog
bundle exec ruby -Itest test/.../order_status_acceptance_cbr_test.rb

Точные команды должны быть уточнены по фактическому test runner проекта.
Добавить/изменить тесты для:
payment success
  → payment-result
  → email submit
  → automatic "/"

и:
payment success
  → payment-result
  → skip email
  → automatic "/"

Отдельно сохранить regression test:
payment-result mount
  → НЕ automatic "/"
  → email/skip required

и:
после email/skip
  → "/"
  → existing OrderStatusSheet

Критерий готовности Spec
Документ готов к Build, если подтверждено:
какой именно компонент завершает email submit;
какой именно компонент выполняет Skip;
в какой момент считается завершённым email-flow;
каким существующим navigation API выполняется push("/");
каким тестовым runner'ом запускаются email_collection_test.mjs и acceptance #35.
Если любой из этих пунктов невозможно установить из текущего кода — пометить как [ОТКРЫТЫЙ ВОПРОС] и не переходить к Build.

---

## Заметки агента

- Заказчик п.9.2 ≈ Google TASK_91 → CBR **#93** (#91 в CBR занят UI-EXT phone input).
- Скрины чата: (1) stuck «Чек сформирован»+«В каталог»; (2) эталон каталог+статусная модель; (3) статусная модель (автоплатёж/повтор / кейс отмены). Файлы: `artifacts/post_pay_auto_return_catalog_status/screenshots/01`–`03`.
- п.9.1 → уже #92 TASK_90 (REVIEW, deploy апрув); в этот intake не входит.
- Unlazy: `docs/operations/session/GATES.md` — G1–G3 baseline met; G4 Fly после deploy.
