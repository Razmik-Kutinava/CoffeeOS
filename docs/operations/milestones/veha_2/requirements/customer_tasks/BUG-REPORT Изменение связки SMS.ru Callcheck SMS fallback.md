# [BUG-REPORT] Изменение связки: SMS.ru — Callcheck + SMS fallback

**Дата интейка:** 2026-08-12  
**Источник:** заказчик (BUG-REPORT, текст 1:1)  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/sms_ru_auth_callcheck_not_flash/  
**Статус:** GREEN local `[x]` 2026-08-12 · Fly MCP `[ ]`

> Парный док к [`BUG-REPORT SMS.ru FlashCall вместо Callcheck.md`](BUG-REPORT%20SMS.ru%20FlashCall%20вместо%20Callcheck.md) — identity / endpoints / errors / security / deprecated.

---

## Текст заказчика (дословно)

[BUG-REPORT] Изменение связки: SMS.ru — Callcheck + SMS fallback

### Точки входа нашего backend:
- POST /shop/api/phone_otp/init_callcheck
- GET /shop/api/phone_otp/check_status
- POST /shop/api/phone_otp/send_sms
- POST /shop/api/phone_otp/verify_sms

### Identity Mapping:
- phone → текущая попытка phone authorization / пользователь;
- check_id SMS.ru → идентификатор текущей Callcheck-попытки;
- SMS OTP → временный mobile_otp_codes, связанный с номером телефона.

### Наши исходящие вызовы к SMS.ru:
- callcheck/add — создание Callcheck-попытки;
- callcheck/status — проверка результата Callcheck;
- sms/send — отправка OTP только при fallback.

### Handling Errors:
- отсутствие подтверждения Callcheck в течение 40 секунд → остановить polling и перейти к SMS fallback;
- пользователь явно выбирает SMS fallback → остановить polling и отправить SMS;
- ошибка SMS → вернуть контролируемую ошибку клиенту без авторизации;
- неверный SMS OTP → 422, OTP не считается подтверждённым;
- истёкший OTP → 422, требуется повторная отправка;
- check_status == "401" → считать телефон подтверждённым и завершить authorization flow.

### Security:
- api_id и другие секреты SMS.ru хранятся только в environment secrets;
- check_id не должен позволять подтвердить другой пользовательский/телефонный flow;
- OTP имеет TTL 10 минут;
- OTP не хранится в открытом виде в логах;
- endpoint check_status валидирует принадлежность check_id текущей authorization-сессии.

### Deprecated contract:
- sms.ru/code/call не используется и должен быть удалён из нашего authorization flow.

## Заметки агента

- Канон стека: Minitest / node --test.
- Session binding: `session[:shop_phone_callcheck]` = { phone, check_id, tenant_id }.
