# todo — SMS.ru #48 sms/send · PHASE 2 GREEN (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| RED | **GREEN** local PASS | REVIEW (bugbot) **или** следующий метод SMS.ru |

## Цель (#48)
Клиент `sms/send`: `SendResult`/`sms_id`, per-phone ERROR, payload лога. Без DDL / shop-proxy / captcha.

## Acceptance
- [x] `send_message!` / `send_sms!` → `SendResult` с `sms_id`
- [x] per-phone ERROR → `Error` + `status_code`
- [x] fallback → `fallback-*`
- [x] notifier → `payload["sms_id"]`
- [x] регрессия cascade + phone_otp
- [x] Не трогали multi/time/captcha/legacy SmsClient

## Файлы
- `app/services/shop/sms_ru_client.rb` ✅
- `test/services/shop/sms_ru_client_test.rb` ✅
- `app/services/shop/order_ready_paid_notifier.rb` ✅
- `test/services/shop/order_ready_paid_notifier_test.rb` ✅
- `docs/integrations/sms-auth.md` ✅ gap закрыт

## Не ломать
- Phone OTP flash→SMS · cascade skip/≤70 · без `/shop/api` proxy

## Проверка (Local)
```
sms_ru_client_test — 14/0 PASS
order_ready_paid_notifier_test — 1/0 PASS
order_ready_cascade_job_test — 11/0 PASS
phone_otp_test — 6/0 PASS
```
Fly MCP: skip (нет UI/deploy для #48)

## SBR
- [x] SPEC
- [x] RED
- [x] GREEN
- [ ] REVIEW

## Вне этого шага
status · cost · callcheck · balance · limits · senders · auth · stoplist · webhooks
