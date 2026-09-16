# todo — #91 TASK_89-UI-EXT phone input UI/UX

| Поле | Значение |
|------|----------|
| **ID** | CBR **#91** (Google: TASK_89-UI-EXT) |
| **Статус** | **regress PASS** 2026-09-16 · ждёт `/review` |
| **ТЗ** | [`TASK-89-UI-EXT-…md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-UI-EXT-UI-UX-авторизации-PWA-экран-ввода-телефона.md) |
| **Google** | https://docs.google.com/document/d/1PTP5LIVgnj2QNpOMi4Md4Lb8Y8imvL3MQnsHhVNDQoc/edit?usp=drivesdk |
| **Артефакты** | `artifacts/pwa_auth_phone_input_ui_ux/` |
| **GATES** | [`session/GATES.md`](GATES.md) · G1–G4 baseline · reverify после GREEN |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED/GREEN
- [ ] PHASE 3 `/review`

## Цель (observable)

Пока активен phone-auth wizard на checkout: нет CTA с суммой, нет preview/состава корзины, checkout-sheet тоньше (`CHECKOUT_PHONE_AUTH_VH=8`). После `phoneVerified` — обычный checkout UI.

## Файлы (ожидаемо)

1. `app/frontend/routes/Checkout.svelte` — `setCheckoutPhoneAuthActive(!phoneVerified)`
2. `app/frontend/lib/cartSheetStore.js` — `checkoutPhoneAuthActive` + setter
3. `app/frontend/lib/shopWebViewLayout.js` — `shouldHideCartCheckoutCta` + `phoneAuthActive`
4. `app/frontend/lib/cartSheetThresholds.js` — `CHECKOUT_PHONE_AUTH_VH = 8`
5. `app/frontend/components/CartSheet.svelte` — slim sheet / hide CTA+cart
6. `test/javascript/shop_telegram_webview_ui_test.mjs`
7. `test/integration/shop/shop_checkout_cart_sheet_ux_test.rb` + `auth_funnel_wizard_ui_test.rb`

## Не ломать

1. #89 Callcheck→SMS / linker / session / post-verify → PaymentMethodsSheet.
2. CTA суммы и состав корзины **вне** phone-auth.
3. Keyboard hide CTA path.
4. #90 POSTCALL — не трогать.

## Проверка

- `node --test test/javascript/shop_telegram_webview_ui_test.mjs test/javascript/phone_auth_wizard_test.mjs test/javascript/phone_otp_ui_test.mjs` — PASS 28
- `ruby bin/rails test test/integration/shop/shop_checkout_cart_sheet_ux_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb test/integration/shop/checkout_ui_cleanup_test.rb` — PASS 13/247

## Next

`/review`
