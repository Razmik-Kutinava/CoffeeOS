# todo — #80 Registration UI/UX + Callcheck cascade

| Поле | Значение |
|------|----------|
| **CBR** | #80 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Регистрация%20PWA%20UI%20UX%20и%20каскад%20Callcheck%20x2%20SMS.md) |
| **Тип** | Fix / hot-path витрина · phone auth + CartSheet |
| **Цель** | P0: скрыть сумму при клавиатуре; копирайт Callcheck (номер = кнопка); переход после confirmed |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/registration_callcheck_cascade_ui_ux/`](../milestones/veha_2/artifacts/registration_callcheck_cascade_ui_ux/) |

## SBR

- [x] **SPEC** (`9c28d388`)
- [x] **RED** (`cbd1d8a4`)
- [x] **GREEN** (`61593bb2`)
- [ ] **/regress**
- [ ] **REVIEW**

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | Канон = Callcheck (не flash_call) |
| 2 | `#/checkout` + keyboard → скрыть CTA `+N₽` (`shouldHideCartCheckoutCta`) |
| 3 | Hint про регистрацию; номер = кнопка `phone-auth-tel-btn` |
| 4 | `interpretCallcheckPoll` → `onVerified`; ошибки check_status не глотать |
| 5 | **Вне slice:** Callcheck×2 |

## Файлы (ожидаемо)

- `app/frontend/lib/shopWebViewLayout.js`
- `app/frontend/components/CartSheet.svelte`
- `app/frontend/lib/phoneAuthCascade.js`
- `app/frontend/components/PhoneAuthCodeStep.svelte`

## Не ломать

- One-Click / SBP CTA вне phone-keyboard
- Peek витрины
- Callcheck→SMS @40s
- #35 status

## Проверка

- `node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_auth_wizard_test.mjs test/javascript/shop_telegram_webview_ui_test.mjs`
- `bin/rails test test/integration/shop/api/phone_otp_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb test/services/shop/phone_otp_test.rb`

## Local GREEN

- JS: 33/0 PASS
- rails: 23/0 PASS
- Entire: `61593bb2` no trailer — attach на docs ops (session `6516e70c…`)
