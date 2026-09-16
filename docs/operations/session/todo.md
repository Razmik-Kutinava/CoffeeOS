# todo — #91 TASK_89-UI-EXT phone input UI/UX

| Поле | Значение |
|------|----------|
| **ID** | CBR **#91** (Google: TASK_89-UI-EXT) |
| **Статус** | **SPEC** 2026-09-16 · ждёт `/sbr` |
| **ТЗ** | [`TASK-89-UI-EXT-…md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-UI-EXT-UI-UX-авторизации-PWA-экран-ввода-телефона.md) |
| **Google** | https://docs.google.com/document/d/1PTP5LIVgnj2QNpOMi4Md4Lb8Y8imvL3MQnsHhVNDQoc/edit?usp=drivesdk |
| **Артефакты** | `artifacts/pwa_auth_phone_input_ui_ux/` |
| **GATES** | [`session/GATES.md`](GATES.md) · G1–G4 baseline PASS · G5 после deploy |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec`
- [ ] PHASE 2 RED/GREEN
- [ ] PHASE 3 `/review`

## Цель (observable)

Пока активен phone-auth wizard на checkout: нет CTA с суммой, нет preview/состава корзины, checkout-sheet тоньше (UX Guide). После `phoneVerified` — обычный checkout UI. Callcheck/SMS/backend не менять.

**Канон:** Google Doc (скрыть CTA). Фраза чата «чтобы было видно сумму» = тоньше шторка / меньше визуального шума, не «оставить кнопку суммы».

## Файлы (ожидаемо)

1. `app/frontend/routes/Checkout.svelte` — сигнал «phone-auth active» (`!phoneVerified` / wizard visible) в store/CartSheet.
2. `app/frontend/lib/cartSheetStore.js` — writable/флаг phone-auth active для шторки (сейчас только keyboard + payStack).
3. `app/frontend/lib/shopWebViewLayout.js` — расширить `shouldHideCartCheckoutCta` на phone-auth (не только `keyboardOpen`).
4. `app/frontend/lib/cartSheetThresholds.js` — константа меньшей vh для phone-auth sheet (не ломая `CHECKOUT_PEEK_VH` / pay-stack вне auth).
5. `app/frontend/components/CartSheet.svelte` — при phone-auth: скрыть `checkoutBar` CTA + peek/list состав; применить thinner height.

### Blast-radius (+соседи)

6. `test/javascript/shop_telegram_webview_ui_test.mjs` — `shouldHideCartCheckoutCta` + phone-auth case.
7. `test/integration/shop/shop_checkout_cart_sheet_ux_test.rb` + `test/integration/shop/auth_funnel_wizard_ui_test.rb` — structural: CTA/cart hide + thinner sheet на phone-auth.

**Не в scope:** `phoneAuthCascade.js`, `PaymentMethodsSheet`, Callcheck/SMS API, `#90` POSTCALL.

## Не ломать

1. #89 Callcheck→SMS / linker / session / post-verify → PaymentMethodsSheet.
2. CTA суммы и состав корзины **вне** phone-auth (обычный checkout / peek / pay-stack).
3. CartSheet thresholds / keyboard hide CTA только на клавиатуре — не сломать существующий keyboard path.
4. #90 POSTCALL — не трогать (parked).

## Проверка

- `node --test test/javascript/shop_telegram_webview_ui_test.mjs test/javascript/phone_auth_wizard_test.mjs test/javascript/phone_otp_ui_test.mjs`
- `ruby bin/rails test test/integration/shop/shop_checkout_cart_sheet_ux_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb test/integration/shop/checkout_ui_cleanup_test.rb`

## Next

`/sbr` → RED (падающие asserts CTA/cart/sheet) → GREEN.
