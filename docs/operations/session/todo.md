# todo — Group 1: session / auth / profile (2026-08-10)

**Намерение:** ебашь Группа 1 — durable sessions · Flash Call×2→SMS · Email↔Phone merge

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Group 1 local PASS + silent-refresh race fix | FE fix **не** на Fly до deploy | deploy FE **или** Group 3 шторка/повторы |

## Файлы (ожидаемо)
- `app/frontend/lib/silentRefreshSession.js` ✅ race fix
- `app/frontend/lib/phoneAuthWizard.js` ✅ comment
- `test/integration/shop/silent_refresh_frontend_structural_test.rb` ✅
- `test/javascript/silent_refresh_session_test.mjs` ✅
- `app/services/shop/session_refresh.rb` / phone_otp / customer_profile_merger (без кода — ок)

## Не ломать
- оплата / 1-клик / UserCards список
- кнопка «повторить» / frequent
- табло бариста / статусы в PWA
- peek корзины / CartSheet layering

## Проверка
```bash
bundle exec rails test test/integration/shop/silent_refresh_frontend_structural_test.rb \
  test/integration/shop/api/session_refresh_test.rb \
  test/integration/shop/api/phone_otp_test.rb \
  test/integration/shop/api/profile_merge_test.rb \
  test/integration/shop/auth_funnel_wizard_ui_test.rb
node test/javascript/silent_refresh_session_test.mjs
```
→ **PASS**

## Чеклист
- [x] Local PASS
- [x] MCP silent refresh + profile email/phone confirmed
- [x] Auth cascade = flash×2→sms (tests + source; live OTP skip)
- [x] Merge state Point A: email+phone Подтвержден, cards 2
- [x] Косяк race silent refresh → fix
- [ ] Deploy FE на Fly (апрув владельца)
