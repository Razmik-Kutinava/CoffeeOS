# BUG-REPORT: SMS.ru Authorization — неправильный протокол FlashCall вместо Callcheck

**Дата интейка:** 2026-08-12  
**Источник:** заказчик (BUG-REPORT, текст 1:1)  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_auth_callcheck_not_flash/  
**Приоритет:** Critical  
**Тип:** Bug / Refactoring  
**Статус:** GREEN local `[x]` 2026-08-12 · Fly MCP `[ ]`

> **SUPERSEDES:** смешанные Flash Call×2→SMS ТЗ; ошибочный split «Flash отдельно / SMS отдельно» как равноправные каналы входа. Канон: **Callcheck primary + SMS fallback**.

---

## Текст заказчика (дословно)

BUG-REPORT: SMS.ru Authorization — неправильный протокол FlashCall вместо Callcheck
Приоритет: Critical
Тип: Bug / Refactoring
Затронутые области: Rails backend, PWA frontend, RSpec, Vitest, SMS.ru integration

### 1. Проблема
В текущей реализации SMS.ru авторизации использован неправильный протокол подтверждения телефона.
Фактически реализована механика FlashCall: SMS.ru инициирует звонок пользователю, после чего пользователь должен ввести 4 цифры из входящего номера.
Требуемая механика — Callcheck: пользователь самостоятельно звонит на специальный номер SMS.ru, SMS.ru сбрасывает звонок и подтверждает номер.
Из-за этого текущие backend API, frontend state machine и тестовые моки не соответствуют фактическому контракту SMS.ru.

### 2. Требуемое исправление

#### Backend
Заменить интеграцию с /code/call на:
POST/GET https://sms.ru/callcheck/add
https://sms.ru/callcheck/status
https://sms.ru/sms/send — только для SMS fallback.

Обновить Shop::SmsRuClient:
init_callcheck(phone) → возвращает check_id, call_phone_pretty, call_phone_html;
check_call_status(check_id) → статус 401 трактуется как подтверждение номера;
send_sms(phone, code) → отправляет fallback SMS.

Обновить Shop::Api::PhoneOtpController:
POST /shop/api/phone_otp/init_callcheck;
GET /shop/api/phone_otp/check_status;
POST /shop/api/phone_otp/send_sms;
POST /shop/api/phone_otp/verify_sms.

check_id должен сохраняться в сессии либо в соответствующей сущности БД и быть связан с текущей попыткой авторизации.
SMS OTP должен быть случайным 4-значным кодом с TTL 10 минут.

#### PWA
Изменить state machine авторизации:
Phone input — пользователь вводит номер; POST /init_callcheck.
Callcheck — отсутствуют поля ввода 4 цифр; отображаются инструкции для исходящего звонка; отображается call_phone_html; номер должен открывать tel: на мобильном устройстве; GET /check_status каждые 3 секунды; timeout — 40 секунд; успешный статус → авторизация и redirect; timeout / ручной fallback → SMS.
SMS fallback — автоматически вызывается /send_sms; отображаются 4 ячейки OTP; после ввода 4-й цифры выполняется /verify_sms; 422 → shake-анимация, очистка кода и возврат фокуса.

### 3. Тестовое покрытие
RSpec → в CoffeeOS: Minitest (`test/`). Vitest → `node --test` (`test/javascript/`).
Обновить sms_ru_client + phone_otp request/integration tests.
Удалить моки /code/call из authorization flow.
Добавить: callcheck/add, callcheck/status, check_status==401, сохранение check_id, fallback SMS, TTL OTP, SMS verify ok/fail.
FE: Phone→Callcheck, call_phone_html, нет OTP на Callcheck, poll 3s, success, timeout 40s→SMS, auto send_sms, auto-submit 4-й, 422.

### 4. Критерии приёмки
В production-коде authorization flow отсутствуют запросы к sms.ru/code/call.
Callcheck — основной способ. Пользователь сам звонит. После Callcheck — авторизация без ввода кода.
При невозможности Callcheck — SMS fallback. SMS OTP только fallback.
Backend и PWA согласованы. Прочие auth-сценарии вне воронки не регрессировали.

### 5. Ограничения Scope
Разрешено: sms_ru_client*, phone_otp*, связанные OTP сервисы/модели в рамках flow, PWA phone auth, тесты, INTEGRATIONS.md / sms-auth.md.
Запрещено: общая auth вне phone OTP; identity mapping без нужды; платежи; заказы; loyalty; чужие интеграции; production secrets/.env.

### 6. Definition of Done
/code/call удалён из authorization flow. Callcheck E2E. SMS fallback E2E. Тесты зелёные. sms-auth/INTEGRATIONS отражают связку.

## Заметки агента

- Стек: Minitest + `node --test`, не RSpec/Vitest.
- Клиент `callcheck_add!` / `callcheck_status!` уже есть (#52); воронка и API — этот баг.
- Связанный контракт: [`BUG-REPORT Изменение связки SMS.ru Callcheck SMS fallback.md`](BUG-REPORT%20Изменение%20связки%20SMS.ru%20Callcheck%20SMS%20fallback.md)
