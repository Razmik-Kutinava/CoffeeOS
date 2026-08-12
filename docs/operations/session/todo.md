# todo — SMS.ru auth Callcheck + SMS fallback (2026-08-12)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Callcheck API + PWA + tests | GREEN local | push + Fly MCP Point A |

## Цель
BUG-REPORT: убрать FlashCall `/code/call` из auth; Callcheck primary + SMS fallback.

## Файлы (ожидаемо)
- `app/services/shop/phone_otp.rb` — **[x]**
- `app/controllers/shop/api/phone_otp_controller.rb` — **[x]**
- `app/services/shop/sms_ru_client.rb` — **[x]**
- `app/frontend/lib/phoneAuthCascade.js` · `phoneAuthWizard.js` · `PhoneAuth*.svelte` — **[x]**
- `docs/integrations/sms-auth.md` — **[x]**
- tests phone_otp / cascade JS — **[x]**

## Не ломать
- Profile link SMS (`send_sms` / legacy send channel=sms)
- Email OTP / MobileSessionIssuer
- SMS.ru webhooks / order-ready SMS
- Платежи

## Проверка
- `ruby bin/rails test test/services/shop/phone_otp_test.rb test/services/shop/sms_ru_phone_otp_test.rb test/integration/shop/api/phone_otp_test.rb`
- `node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_auth_wizard_test.mjs`
