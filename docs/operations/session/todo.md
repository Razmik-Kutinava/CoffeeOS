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
- [x] **GREEN**
- [ ] **/regress**
- [ ] **REVIEW**

## Local GREEN

- JS: 33/0 PASS (cascade + wizard + webview)
- rails phone_otp + auth_funnel + phone_otp service: 23/0 PASS

## Решение (slice)

| # | Решение |
|---|---------|
| 1 | Канон = Callcheck (не flash_call) |
| 2 | `#/checkout` + keyboard → скрыть CTA `+N₽` |
| 3 | Hint про регистрацию; номер = кнопка `tel:` |
| 4 | Poll: confirmed → `onVerified`; ошибки check_status не глотать |
| 5 | **Вне slice:** Callcheck×2 |

## Файлы (ожидаемо)

- `app/frontend/lib/shopWebViewLayout.js` — `shouldHideCartCheckoutCta`
- `app/frontend/components/CartSheet.svelte` — hide CTA при keyboard
- `app/frontend/lib/phoneAuthCascade.js` — hint / CTA label / interpret poll
- `app/frontend/components/PhoneAuthCodeStep.svelte` — кнопка номера + poll complete
- `app/frontend/components/PhoneAuthWizard.svelte` — без дельты если не нужно
- `app/frontend/routes/Checkout.svelte` — без дельты если не нужно
- `app/services/shop/phone_otp.rb` — без дельты если poll FE хватает

### Blast-radius

- `cartSheetStore.js` — не трогаем без нужды
- `phone_otp_controller.rb` — без дельты

## Не ломать

- One-Click / SBP CTA вне phone-keyboard
- Peek витрины
- Callcheck→SMS @40s
- #35 status

## Проверка

- `node --test test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_auth_wizard_test.mjs test/javascript/shop_telegram_webview_ui_test.mjs`
- `bin/rails test test/integration/shop/api/phone_otp_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb test/services/shop/phone_otp_test.rb`
