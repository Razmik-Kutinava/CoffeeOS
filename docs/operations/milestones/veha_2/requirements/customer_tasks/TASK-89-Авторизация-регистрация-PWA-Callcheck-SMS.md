# TASK_89: Авторизация и регистрация PWA — Callcheck → SMS

**CBR:** #89 · **Дата intake:** 2026-09-16  
**Источник:** Google Doc + правки заказчика (чат)  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/pwa_auth_registration_callcheck_sms/  
**Google Doc:** https://docs.google.com/document/d/1wDRuIFxAl1pBSxh305sEidRxj-Kd6vwjytFkOvWn2ZQ/edit?usp=drivesdk  
**Связь:** предшественник / overlap #80 — [`Регистрация PWA UI UX и каскад Callcheck x2 SMS.md`](Регистрация%20PWA%20UI%20UX%20и%20каскад%20Callcheck%20x2%20SMS.md) · канон Callcheck — [`BUG-REPORT SMS.ru FlashCall вместо Callcheck.md`](BUG-REPORT%20SMS.ru%20FlashCall%20вместо%20Callcheck.md) · [`docs/integrations/sms-auth.md`](../../../../../integrations/sms-auth.md)  
**Статус:** Spec (Google) · intake `[x]` · SPEC `[x]` 2026-09-16 · ждёт `/sbr`

---

## Текст заказчика (дословно) — правки / доп.задача

8/ регистрация,  посмотреть видео есть тех и 
UI\UX  правки, 
1. при вводе номера телефона остается сумма заказа [текст в кнопке], как исчезает цифровая клавиатура виден весь заказ
Реализовано, норм, но нужно сделать толщину шторки меньше, чтобы было видно сумму

2. изменить текст "позвони, на номер, пройди регистрацию" [номер, в кнопке]
Реализовано, нормально 

задача не реализована полностью, на звонке сказали что не прошли регистрацию
Готово, удалось авторизоваться, узнать есть ли мой номер по этому методу БД??

после звонка нет перехода в pwa, решить
Подкинуть экран оплаты, согласно флоу пользователя 

а текст куда ссылклись 
# Рефакторинг воронки авторизации PWA (Каскад Callcheck x2 → SMS) на базе SMS.ru

---

## Текст задачи (дословно) — Google Doc Spec

TASK_89: Авторизация и регистрация PWA — Callcheck → SMS
УСТАРЕЛО, см. ниже
Старая часть задачи описывала каскад FlashCall x2 → SMS через SMS.ru /code/call, ввод последних 4 цифр номера звонящего и хранение Callcheck-кода в mobile_otp_codes.
Эта модель больше не является каноном проекта.
Осознанно удалено/заменено:
SMS.ru /code/call;
channel: "flash_call" в authorization flow;
FlashCall PIN-flow;
хранение Callcheck-кода в mobile_otp_codes.
Основание: BUG-REPORT SMS.ru FlashCall вместо Callcheck.md, docs/integrations/sms-auth.md, commit 87483508.
Защитные тесты удаления FlashCall существуют:
spec/.../phone_otp_test.rb:83–88, auth_funnel_wizard_ui_test.rb:25.
FlashCall не восстанавливать в рамках этой задачи.

АКТУАЛЬНАЯ СПЕЦИФИКАЦИЯ
Бизнес-цель: обеспечить полный и единообразный flow авторизации/регистрации пользователя в PWA через Callcheck с переходом на SMS fallback, корректным созданием/поиском клиента и сохранением авторизованного состояния в checkout.
Глобальные ограничения
Канон телефонной верификации: Callcheck → SMS.
SMS.ru /code/call не используется.
channel: "flash_call" не используется.
Не возвращать FlashCall PIN-flow и ввод последних 4 цифр номера звонящего.
Callcheck подтверждается через check_status.
После успешного Callcheck используется общий PhoneVerifiedCustomerLinker.
Существующий пользователь определяется по номеру телефона.
При отсутствии пользователя создаётся новый MobileCustomer.
После успешной верификации создаётся/обновляется customer session.
Технические параметры SMS.ru хранятся в ENV согласно действующему docs/integrations/sms-auth.md.
Не менять CartSheet thresholds/status-механику, если это не требуется непосредственно для данного auth-flow.
UI-изменения, требующие визуального эталона, в эту спецификацию не включать до отдельной проверки скриншотами.

1. Карта интеграций
Затронуто
PWA phone authentication.
Callcheck через текущий SMS.ru integration layer.
SMS fallback.
Customer/session authorization.
Checkout как хост auth wizard.
Не менять
Платёжный провайдер и существующую PaymentMethodsSheet.
Общую механику CartSheet.
CartSheet status/thresholds, используемые другими сценариями.
FlashCall /code/call.

2. Карта компонентов
Основные компоненты
PhoneAuthWizard
PhoneAuthCodeStep
PhoneAuthPinInputs
phoneAuthWizard.js
phoneAuthCascade.js
phoneOtp.js
PhoneOtpController
PhoneOtp
PhoneVerifiedCustomerLinker
SmsRuClient
MobileOtpCode
mobile_otp_codes
Checkout как host auth wizard.
Общий файл с другой задачей
CartSheet является общим компонентом checkout.
Граница:
Разрешено: использовать существующий CartSheet/checkout state для размещения auth wizard.
Запрещено: менять общие STATUS_IN_SHEET, thresholds и поведение CartSheet ради auth-flow без отдельной UI-задачи.
Новый компонент
Нет.

3. Текущее поведение — факт
3.1 Ввод телефона
PhoneAuthWizard предоставляет первый экран ввода номера с autofocus, маской и проверкой 10 национальных цифр.
Факт:
PhoneAuthWizard.svelte:63–88
phoneOtp.js:10–25
phoneAuthWizard.js:18–20
3.2 Запуск Callcheck
Основной путь — POST .../init_callcheck.
Backend создаёт Callcheck attempt и сохраняет check_id в session.
Факт:
phone_otp.rb:45–54
phone_otp_controller.rb:6–19
3.3 Подтверждение Callcheck
Frontend периодически вызывает check_status.
При confirmed backend выполняет PhoneVerifiedCustomerLinker.link!.
Факт:
phone_otp_controller.rb:26–54
phone_otp.rb:87–90
PhoneAuthCodeStep.svelte:96–117
3.4 Поиск/создание клиента
PhoneVerifiedCustomerLinker:
ищет MobileCustomer по phone;
при отсутствии создаёт нового;
устанавливает phone_verified;
устанавливает customer session.
Факт:
phone_verified_customer_linker.rb:21
phone_verified_customer_linker.rb:30–43
3.5 SMS fallback
После timeout Callcheck используется SMS fallback.
SMS имеет отдельный OTP flow:
отправка SMS;
ввод 4-значного PIN;
автоматический submit;
verify_sms.
Факт:
PhoneAuthCodeStep.svelte:81–84,131–160
phone_otp.rb:103–119
phone_otp_controller.rb:89–106
3.6 Текущее завершение авторизации
После успешной верификации frontend:
сохраняет refresh token;
устанавливает phoneVerified=true;
скрывает wizard;
остаётся на существующем checkout.
Факт:
Checkout.svelte:346–352
Checkout.svelte:685–726
Автоматического router redirect или автоматического открытия PaymentMethodsSheet сейчас нет.

4. Scope
Разрешено
Backend
Поддерживать актуальный Callcheck flow.
Обеспечить корректную обработку успешного confirmed.
Выполнять поиск существующего MobileCustomer по номеру.
Создавать MobileCustomer, если номер отсутствует.
Устанавливать phone_verified.
Устанавливать customer session.
Возвращать frontend подтверждение успешной авторизации.
Сохранять/передавать refresh token согласно существующему flow.
Поддерживать SMS fallback.
Сохранять текущую защиту от FlashCall.
Frontend
Обрабатывать успешный Callcheck через существующий onVerified.
Корректно завершать auth wizard после успешной верификации.
Сохранять авторизованное состояние checkout.
Обеспечить корректное завершение flow Callcheck → authenticated checkout.
Запрещено
Возвращать SMS.ru /code/call.
Возвращать channel: "flash_call".
Возвращать FlashCall PIN.
Возвращать ввод последних 4 цифр номера звонящего.
Переносить Callcheck-код в mobile_otp_codes.
Менять общий CartSheet thresholds/status без отдельной UI-задачи.
Автоматически открывать PaymentMethodsSheet в рамках этой технической задачи, пока это не подтверждено отдельным UX-сценарием.
Менять UI состава корзины/высоты шторки до получения и проверки UX-эталона.

5. Gherkin
Subtask 1 — успешный Callcheck
Given: пользователь ввёл корректный номер телефона и запустил Callcheck.
When: backend через check_status получает подтверждённый статус Callcheck.
Then: номер считается подтверждённым, вызывается общий PhoneVerifiedCustomerLinker.link!, создаётся/находится клиент и устанавливается customer session.
Subtask 2 — существующий пользователь
Given: номер телефона уже связан с MobileCustomer.
When: Callcheck подтверждён.
Then: используется существующий MobileCustomer, новый customer не создаётся, устанавливается его customer session.
Subtask 3 — новый пользователь
Given: номер телефона отсутствует среди MobileCustomer.
When: Callcheck подтверждён.
Then: создаётся новый MobileCustomer, устанавливается phone_verified=true и customer session.
Subtask 4 — frontend завершает wizard
Given: backend вернул успешное подтверждение Callcheck.
When: frontend получает confirmed.
Then: auth wizard завершается, сохраняется авторизованное состояние и пользователь остаётся в текущем checkout context.
Subtask 5 — SMS fallback
Given: Callcheck не был подтверждён в установленный timeout.
When: наступает SMS fallback.
Then: отправляется SMS OTP, пользователь получает 4-значный код и может завершить верификацию через verify_sms.
Subtask 6 — успешный SMS
Given: пользователь ввёл корректный SMS OTP.
When: выполняется POST /shop/api/phone_otp/verify_sms.
Then: номер считается подтверждённым, используется тот же PhoneVerifiedCustomerLinker, создаётся/находится MobileCustomer и устанавливается customer session.
Subtask 7 — защита от FlashCall
Given: authorization flow использует актуальный Callcheck.
When: код пытается использовать legacy flash_call.
Then: legacy FlashCall flow остаётся недоступным.
Subtask 8 — завершение checkout context
Given: пользователь успешно прошёл Callcheck или SMS.
When: customer session установлена.
Then: auth wizard больше не блокирует checkout и пользователь остаётся в контексте текущего заказа.
Открытый вопрос: должен ли после успешной авторизации автоматически открываться PaymentMethodsSheet либо пользователь должен самостоятельно нажать существующий CTA оплаты.
Этот вопрос относится к UX/product flow и будет уточнён отдельной задачей/патчем после предоставления визуального эталона.

6. TDD-проверка
Backend
bundle exec rspec spec/requests/shop/api/phone_otp_spec.rb
bundle exec rspec spec/services/shop/phone_verified_customer_linker_test.rb
bundle exec rspec spec/services/shop/sms_ru_client_spec.rb

Проверить минимум:
Callcheck confirmed;
existing customer;
new customer;
customer session;
refresh token;
SMS verify;
Callcheck без init;
legacy flash_call rejection.
Frontend
Запустить существующие тесты phone-auth/wizard/cascade и typecheck/lint согласно package scripts проекта.
Проверить минимум:
успешный onVerified;
скрытие wizard;
сохранение checkout context;
SMS fallback;
SMS OTP auto-submit;
обработку ошибки verify;
отсутствие legacy FlashCall UI.
Exit Criteria
Callcheck является primary phone verification flow.
Успешный Callcheck приводит к PhoneVerifiedCustomerLinker.link!.
Существующий пользователь корректно находится по номеру.
Новый пользователь корректно создаётся.
Customer session устанавливается после успешной верификации.
SMS остаётся fallback.
Callcheck не использует mobile_otp_codes как хранилище Callcheck-кода.
/code/call и flash_call не возвращены.
Frontend корректно завершает auth wizard после успешной верификации.
Checkout context сохраняется.
Существующие защитные тесты legacy FlashCall продолжают проходить.
Все релевантные RSpec/Vitest/Jest тесты проходят.
tsc и линтер проходят без ошибок.
Изменения CartSheet/payment UI не входят в эту техническую задачу без отдельного UX-сценария.

7. Не трогать
SMS.ru /code/call
channel: "flash_call"
FlashCall PIN-flow
защитные тесты удаления FlashCall
общие CartSheet thresholds
STATUS_IN_SHEET
существующую механику PaymentMethodsSheet
UI состав корзины/высоту шторки до отдельной UX-проверки.
8. Следующий этап
После Review технической реализации отдельно проверить UX-замечания по:
CTA с суммой;
отображению состава корзины;
высоте/толщине шторки;
поведению после успешного Callcheck;
необходимости автоматического открытия экрана оплаты.
Для этих пунктов использовать фактические screenshots/device evidence и классифицировать каждое изменение отдельно как ПАТЧ / ДОП.ЗАДАЧА.

---

## Заметки агента

- **Доп.задача заказчика (чат 2026-09-16)** закрывает пункт: после Callcheck — сессия/номер в БД + переход в PWA + **подкинуть экран оплаты** по флоу. П.1 (толщина шторки) и п.2 (копирайт) — отдельный UX/уже ок; не смешивать с post-verify handoff без `/spec`.
- Google Doc §4 запрещает авто-open `PaymentMethodsSheet` «пока не подтверждено отдельным UX»; чат заказчика это подтверждает («Подкинуть экран оплаты») → на `/spec` включить в scope #89 как доп. UX-критерий, не откладывать в «открытый вопрос».
- Overlap с **#80**: UI п.8 + «нет перехода после звонка»; #89 — актуальный канон Callcheck→SMS + post-verify checkout/pay. Не дублировать FlashCall/каскад×2 из старого чек-листа #80.
- FlashCall не восстанавливать. Канон: `callcheck/add` + `check_status` + `PhoneVerifiedCustomerLinker`.
