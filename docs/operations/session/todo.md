# todo вЂ” TASK_100: С‚РѕС‡РЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ РїСЂРё РѕС€РёР±РєРµ РѕРїР»Р°С‚С‹ Рё РѕС‚РґРµР»СЊРЅС‹Р№ CTA

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **РћСЃРЅРѕРІР°РЅРёРµ** | [TASK_100](../milestones/veha_2/requirements/customer_tasks/TASK-100-РўРѕС‡РЅС‹Рµ-СЃРѕРѕР±С‰РµРЅРёСЏ-РїСЂРё-РѕС€РёР±РєРµ-РѕРїР»Р°С‚С‹-Рё-РѕС‚РґРµР»СЊРЅС‹Р№-CTA.md) В· РЅРѕРІР°СЏ Р·Р°РґР°С‡Р°, РїРѕР»РЅС‹Р№ SBR В· [GATES](../milestones/veha_2/artifacts/payment_error_messages_cta/GATES.md) G1вЂ“G7 |
| **РЎС‚Р°С‚СѓСЃ** | SPEC `[x]` В· `[РћРўРљР Р«РўР«Р™ Р’РћРџР РћРЎ]` = 0 в†’ РіРѕС‚РѕРІРѕ Рє Build |

## SBR

- [x] intake `f0fa419a` В· ledger `a3059bd7`
- [x] SPEC вЂ” РєР»Р°СЃСЃРёС„РёРєР°С†РёСЏ РєРѕРґРѕРІ + СЂРµС€РµРЅРёСЏ РІР»Р°РґРµР»СЊС†Р° (РЅРёР¶Рµ)
- [x] RED `8bb1b27a` вЂ” `payment_error_matrix_test.mjs` (РЅРµС‚ СЌРєСЃРїРѕСЂС‚РѕРІ) + 2 С‚РµСЃС‚Р° СЃС‚Р°СЂРѕРіРѕ С‚РµРєСЃС‚Р°
- [x] GREEN `efb05433` В· Entire `01M45D9SXG53EDFVFDZ758KEP7` вЂ” `classifyPaymentError` / `resolvePaymentErrorUi` / `PAY_ERROR_CATEGORY`, С‚РµРєСЃС‚С‹ РІ i18n, `errorCta` РІ РєРЅРѕРїРєСѓ (close/retry/change_card), `showPayError` РІ Checkout (РІРєР». 3DS abort) В· + РѕР±РЅРѕРІР»С‘РЅ `repeat_invalid_token_payment_test.mjs` (Р¶РґР°Р» inline = label РєРЅРѕРїРєРё вЂ” С‚Рѕ СЃР°РјРѕРµ В«СЃРјРµС€Р°РЅРѕВ») В· GATES G1вЂ“G6 met (matrix 21/0 В· JS Р·РѕРЅР° 68/0 В· Rails 4 С„Р°Р№Р»Р° 0F/0E В· vite build OK)
- [x] `/regress` PASS вЂ” РЅР°Р№РґРµРЅР° СЂРµРіСЂРµСЃСЃРёСЏ #79 (РЎР‘Рџ NETWORK + `NET_ERROR` в†’ РѕР±С‰РёР№ fallback РІРјРµСЃС‚Рѕ В«РќРµС‚ СЃРІСЏР·РёВ») в†’ RED `9aeb5ac8` в†’ GREEN fix В· JS 640 (60 fail = legacy, 3 РЅР°Р±РѕСЂР°) В· Rails shop 673/0 В· G3 + `shop_sbp_autopay_checkout_ui_test.mjs`
- [ ] `/review` (bugbot + security + crit-audit, push)

## Р¤Р°РєС‚ (РґРѕ РїСЂР°РІРѕРє)

- `shopPayFsm.js`: 12 РєРѕРґРѕРІ `CLIENT_ERROR_CODES` + regex РїРѕ message в†’ РѕРґРЅРѕ `PAY_FSM.CLIENT_ERROR` СЃ РґР»РёРЅРЅС‹Рј С‚РµРєСЃС‚РѕРј В«вЂ¦РёР»Рё РєР°СЂС‚Р° Р·Р°Р±Р»РѕРєРёСЂРѕРІР°РЅР° Р±Р°РЅРєРѕРјвЂ¦В».
- В«РЎРјРµС€Р°РЅРѕВ» Р±СѓРєРІР°Р»СЊРЅРѕ: `CheckoutPayButton` РІ `CLIENT_ERROR` РїРѕРєР°Р·С‹РІР°РµС‚ **С‚РѕС‚ Р¶Рµ** `PAY_FSM_LABELS[5]` РєР°Рє РїРѕРґРїРёСЃСЊ РєРЅРѕРїРєРё, Р° `PaymentMethodsSheet` вЂ” РµРіРѕ Р¶Рµ РІ `role="alert"` (`resolveCheckoutSheetInlineError`).
- CTA СЃРµР№С‡Р°СЃ: `CLIENT_ERROR` в†’ `onChangeCard` (С„РѕСЂРјР° РЅРѕРІРѕР№ РєР°СЂС‚С‹ РїРѕ РєР»РёРєСѓ; auto-open = false вЂ” В§7 Рї.5 СѓР¶Рµ СЃРѕР±Р»СЋРґС‘РЅ); `NET/BANK` в†’ retry.
- Backend `Shop::TbankPaymentError::FRIENDLY_MESSAGES` в‰  РњР°С‚СЂРёС†Рµ (В«РљР°СЂС‚Р° РїСЂРѕСЃСЂРѕС‡РµРЅР°В») вЂ” **РЅРµ С‚СЂРѕРіР°РµРј** (HTTP-РєРѕРЅС‚СЂР°РєС‚), РјР°РїРїРёРЅРі РЅР° С„СЂРѕРЅС‚Рµ РїРѕ `error_code`.

## РљР»Р°СЃСЃРёС„РёРєР°С†РёСЏ `error_code` (G6)

| РљРѕРґ | РљР°С‚РµРіРѕСЂРёСЏ | РСЃС‚РѕС‡РЅРёРє |
|-----|-----------|----------|
| 1051 | РќРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ СЃСЂРµРґСЃС‚РІ | РўР— РњР°С‚СЂРёС†Р° |
| 1014 | РСЃС‚С‘Рє СЃСЂРѕРє РєР°СЂС‚С‹ | РўР— РњР°С‚СЂРёС†Р° |
| 119, 2200 | РЎР»РёС€РєРѕРј РјРЅРѕРіРѕ РїРѕРїС‹С‚РѕРє | РўР— РњР°С‚СЂРёС†Р° |
| 1005 | РєР°СЂС‚РѕС‡РЅС‹Р№ fallback | `shopWidgetPayFsm.js` В«РѕС‚РєР°Р· СЌРјРёС‚РµРЅС‚Р°В» |
| 1041 | РєР°СЂС‚РѕС‡РЅС‹Р№ fallback | С‚Р°Рј Р¶Рµ В«СѓС‚РµСЂСЏРЅР°В» |
| 1054 | РєР°СЂС‚РѕС‡РЅС‹Р№ fallback | С‚Р°Рј Р¶Рµ В«РёСЃС‚С‘Рє СЃСЂРѕРєВ» вЂ” РўР— Р·Р°РєСЂРµРїР»СЏРµС‚ В«РёСЃС‚С‘РєВ» С‚РѕР»СЊРєРѕ Р·Р° 1014 в†’ РЅРµ СЂР°СЃС€РёСЂСЏРµРј |
| 1057 | РєР°СЂС‚РѕС‡РЅС‹Р№ fallback | С‚Р°Рј Р¶Рµ В«РЅРµ СЂР°Р·СЂРµС€РµРЅР°В» |
| 1062 | РєР°СЂС‚РѕС‡РЅС‹Р№ fallback | С‚Р°Рј Р¶Рµ В«РѕРіСЂР°РЅРёС‡РµРЅРёРµ РєР°СЂС‚С‹В» |
| 1013, 1053, 1061, 1078 | РєР°СЂС‚РѕС‡РЅС‹Р№ fallback | `INVALID_REBILL_CODES` (С‚РѕРєРµРЅ РєР°СЂС‚С‹ РЅРµРІР°Р»РёРґРµРЅ) В· **СЂРµС€РµРЅРёРµ РІР»Р°РґРµР»СЊС†Р° 2026-10-05** |
| РЅРµС‚ РєРѕРґР°, message РїРѕ regex В«РєР°СЂС‚/СЃСЂРµРґСЃС‚РІ/РёСЃС‚С‘Рє/Р±Р»РѕРєРёСЂвЂ¦В» | РєР°СЂС‚РѕС‡РЅС‹Р№ fallback | backend message РїРѕРґС‚РІРµСЂР¶РґР°РµС‚ РєР°СЂС‚Сѓ |
| РЅРµРёР·РІРµСЃС‚РЅС‹Р№ РєРѕРґ Р±РµР· РєР°СЂС‚РѕС‡РЅРѕРіРѕ message | РѕР±С‰РёР№ fallback | РўР— В§5 Рї.5вЂ“6 |
| 3DS РїСЂРµСЂРІР°РЅ (РЅРµС‚ РєРѕРґР°) | РѕР±С‰РёР№ fallback | **СЂРµС€РµРЅРёРµ РІР»Р°РґРµР»СЊС†Р°** |
| СЃРµС‚СЊ (`NET_ERROR`), 5xx (`BANK_ERROR`) | Р±РµР· РёР·РјРµРЅРµРЅРёР№ | **СЂРµС€РµРЅРёРµ РІР»Р°РґРµР»СЊС†Р°** вЂ” РІРЅРµ РњР°С‚СЂРёС†С‹ |

## Р РµС€РµРЅРёСЏ РІР»Р°РґРµР»СЊС†Р° (2026-10-05)

- CTA В«РџРѕРїСЂРѕР±РѕРІР°С‚СЊ РїРѕР·Р¶РµВ» (119/2200) в†’ Р·Р°РєСЂС‹РІР°РµС‚ С€С‚РѕСЂРєСѓ РѕРїР»Р°С‚С‹, РєР°СЂС‚Сѓ РЅРµ С‚СЂРѕРіР°РµС‚.
- В«РР·РјРµРЅРёС‚СЊ РєР°СЂС‚СѓВ» в†’ С‚РµРєСѓС‰РµРµ `onChangeCard` (С„РѕСЂРјР° РЅРѕРІРѕР№ РєР°СЂС‚С‹ РїРѕ РєР»РёРєСѓ).
- В«РџРѕРІС‚РѕСЂРёС‚СЊ РѕРїР»Р°С‚СѓВ» в†’ С‚РµРєСѓС‰РёР№ retry.

## Р”РёР·Р°Р№РЅ

- `shopPayFsm.js`: `classifyPaymentError(error)` в†’ РєР°С‚РµРіРѕСЂРёСЏ `insufficient_funds | card_expired | too_many_attempts | card_declined | payment_failed` (null РґР»СЏ NET/BANK); FSM-РїРµСЂРµС…РѕРґ РєР°Рє Р±С‹Р» (РєР°СЂС‚РѕС‡РЅС‹Рµ + РїРѕРїС‹С‚РєРё в†’ `CLIENT_ERROR`; `payment_failed` в†’ РЅРѕРІРѕРµ РѕС‚РѕР±СЂР°Р¶РµРЅРёРµ Р±РµР· СЃРјРµРЅС‹ `NET/BANK`). `resolvePaymentErrorUi(category)` в†’ `{ message, ctaLabel, ctaAction: change_card | close | retry }`. РЎС‚Р°СЂС‹Р№ С‚РµРєСЃС‚ `PAY_FSM_LABELS[CLIENT_ERROR]` СѓРґР°Р»РёС‚СЊ.
- `paymentMethodI18n.js`: 5 СЃРѕРѕР±С‰РµРЅРёР№ + 3 CTA, РєР»СЋС‡Рё РїРѕ РєР°С‚РµРіРѕСЂРёСЏРј (В§9).
- `Checkout.svelte`: С…СЂР°РЅРёС‚СЊ `payErrorCategory` СЂСЏРґРѕРј СЃ `payFsmState` РІ catch / `onThreeDsClose` / 3DS catch; СЃР±СЂРѕСЃ С‚Р°Рј Р¶Рµ, РіРґРµ `sheetInlineError = null`; РїРµСЂРµРґР°С‚СЊ РІ С€С‚РѕСЂРєСѓ.
- `PaymentMethodsSheet.svelte`: alert = `message`, РєРЅРѕРїРєР° = `ctaLabel` вЂ” РґРІР° РѕС‚РґРµР»СЊРЅС‹С… СЌР»РµРјРµРЅС‚Р°.
- `CheckoutPayButton.svelte` (+1 СЃРѕСЃРµРґ): РїСЂРѕРї `errorCta` (label + action) РІРјРµСЃС‚Рѕ `payFsmLabel` РІ РѕС€РёР±РєРµ; `close` в†’ РЅРѕРІС‹Р№ РєРѕР»Р±СЌРє `onClose`.

## Р¤Р°Р№Р»С‹ (РѕР¶РёРґР°РµРјРѕ)

- `app/frontend/lib/shopPayFsm.js` вЂ” РєР»Р°СЃСЃРёС„РёРєР°С†РёСЏ + UI-СЂРµР·РѕР»РІРµСЂ (РѕР±С‰РёР№ С„Р°Р№Р»: С‚РѕР»СЊРєРѕ payment error)
- `app/frontend/lib/paymentMethodI18n.js` вЂ” С‚РµРєСЃС‚С‹ РњР°С‚СЂРёС†С‹
- `app/frontend/routes/Checkout.svelte` вЂ” РєР°С‚РµРіРѕСЂРёСЏ РѕС€РёР±РєРё в†’ С€С‚РѕСЂРєР°
- `app/frontend/components/PaymentMethodsSheet.svelte` вЂ” message Рё CTA СЂР°Р·РґРµР»СЊРЅРѕ
- `app/frontend/components/CheckoutPayButton.svelte` вЂ” РїРѕРґРїРёСЃСЊ/РґРµР№СЃС‚РІРёРµ CTA (blast-radius: СЂРµРЅРґРµСЂРёС‚ label РѕС€РёР±РєРё)
- `test/javascript/payment_error_matrix_test.mjs` вЂ” РЅРѕРІС‹Р№ (G1)
- `test/javascript/payment_error_user_messages_test.mjs`, `test/integration/shop/shop_pay_fsm_3ds_test.rb` вЂ” РѕР±РЅРѕРІРёС‚СЊ РѕР¶РёРґР°РЅРёСЏ СЃС‚Р°СЂРѕРіРѕ С‚РµРєСЃС‚Р°

## РќРµ Р»РѕРјР°С‚СЊ

- repeat-order invalid-token: `isInvalidRebillPaymentError` в†’ `setTokenInvalid` (РЅРµ С‚СЂРѕРіР°РµРј `repeatInvalidTokenStore.js`)
- HTTP 422 / payment token / SBP autopay (`resolveSbpAutopaySheetError`) / РІС‹Р±РѕСЂ СЃРїРѕСЃРѕР±Р° РѕРїР»Р°С‚С‹
- РѕС‚РєСЂС‹С‚РёРµ/Р·Р°РєСЂС‹С‚РёРµ `PaymentMethodsSheet`, 3DS overlay, `shouldAutoOpenNewCardOnClientError = false`
- inline pay РІРёРґР¶РµС‚Р° (`shopInlinePayFsm.js` / `shopWidgetPayFsm.js`) вЂ” РґСЂСѓРіРѕР№ РїРѕС‚РѕРє

## РџСЂРѕРІРµСЂРєР°

- `node --test test/javascript/payment_error_matrix_test.mjs` (G1) + G2 РѕСЂР°РєСѓР» РёР· GATES
- `node --test test/javascript/payment_error_user_messages_test.mjs test/javascript/repeat_invalid_token_payment_test.mjs test/javascript/widget_repeat_pay_flow_patch1_test.mjs test/javascript/shop_inline_pay_button_fsm_test.mjs test/javascript/open_repeat_payment_sheet_test.mjs test/javascript/shop_widget_pay_fsm_test.mjs test/javascript/payment_method_promo_11rub_i18n_test.mjs` вЂ” baseline 68/0
- `bin/rails test test/integration/shop/shop_pay_fsm_3ds_test.rb test/integration/shop/inline_pay_button_patch1_test.rb test/services/shop/tbank_payment_error_test.rb test/integration/shop/api/payment_status_error_code_test.rb`
- `npm run vite:build` В· Fly MCP Point A РїРѕСЃР»Рµ deploy РїРѕ Р°РїСЂСѓРІСѓ

---

# todo вЂ” TASK_SAFE-BOTTOM-MIN (РґРѕРї.Р·Р°РґР°С‡Рё 3+4): РјРёРЅРёРјР°Р»СЊРЅС‹Р№ РЅРёР¶РЅРёР№ РѕС‚СЃС‚СѓРї 8px

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **РћСЃРЅРѕРІР°РЅРёРµ** | [TASK_SAFE-BOTTOM-MIN](../milestones/veha_2/requirements/customer_tasks/TASK-SAFE-BOTTOM-MIN-РњРёРЅРёРјР°Р»СЊРЅС‹Р№-РЅРёР¶РЅРёР№-РѕС‚СЃС‚СѓРї-Home-Indicator.md) вЂ” N = 8px В· Р·Р°РґР°С‡Рё 3 Рё 4 СЃР»РёС‚С‹ (СЂРµС€РµРЅРёРµ РІР»Р°РґРµР»СЊС†Р°: С€С‚РѕСЂРєР° СЃС‚Р°С‚СѓСЃР° РІСЃС‚СЂРѕРµРЅР° РІ CartSheet, РµС‘ РЅРёР· = `--shop-safe-bottom`) |
| **РЎС‚Р°С‚СѓСЃ** | REVIEW `[x]` В· CI green [36837366924](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36837366924) РЅР° `f74e2e5d` В· deploy Р·Р°РїСЂРµС‰С‘РЅ |

## SBR

- [x] intake `5e516968`
- [x] RED `e6a57efb` вЂ” `shop_safe_bottom_min_test.mjs` 9 fail (РєРѕРЅСЃС‚Р°РЅС‚Р°, WebView 0в†’8, `app.css` max(), 5 СЌРєСЂР°РЅРѕРІ Р±РµР· `env()`, РґРѕР±Р°РІРєРё 24/16px)
- [x] GREEN `1c21dbda` вЂ” `app.css` max(8px, env), `shopWebViewLayout.js` `SHOP_SAFE_BOTTOM_MIN_PX`, 5 СЌРєСЂР°РЅРѕРІ РЅР° `var(--shop-safe-bottom)` В· Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS вЂ” JS 616 (60 fail = legacy baseline) В· `vite build` OK В· Rails РІРµСЃСЊ `test/integration/shop` 70 С„Р°Р№Р»РѕРІ 420/0
- [x] `/review` вЂ” bugbot: 1 РЅР°С…РѕРґРєР° (СЂРµР·РµСЂРІ Catalog/CategoryProducts/Product РїРѕРґ CartSheet Р±РµР· safe-bottom) в†’ RED `835566b2` в†’ GREEN `6309066c` в†’ РїРѕРІС‚РѕСЂРЅС‹Р№ bugbot 0 В· security 0 В· `/crit-audit` CLEAN (`6309066c`) В· push В· CI + Semgrep + CodeQL green [36837366924](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36837366924)

## Р¤Р°Р№Р»С‹

- `routes/Catalog.svelte`, `routes/CategoryProducts.svelte`, `routes/Product.svelte` вЂ” СЂРµР·РµСЂРІ РїРѕРґ CartSheet `+ var(--shop-safe-bottom, 0px)` (bugbot)
- `app/frontend/styles/app.css` вЂ” `--shop-safe-bottom: max(8px, env(safe-area-inset-bottom, 0px))`
- `app/frontend/lib/shopWebViewLayout.js` вЂ” `SHOP_SAFE_BOTTOM_MIN_PX = 8`, `max()` РґР»СЏ Р·РЅР°С‡РµРЅРёСЏ РѕС‚ WebView
- `CatalogFiltersSheet.svelte`, `CatalogSortSheet.svelte`, `ContactSupportSheet.svelte`, `routes/OrderReceipt.svelte`, `OrderStatusSheet.svelte` вЂ” `env()` в†’ `var(--shop-safe-bottom, 0px)`
- `test/javascript/shop_safe_bottom_min_test.mjs` вЂ” РЅРѕРІС‹Р№

## РќРµ Р»РѕРјР°С‚СЊ

- `--shop-safe-top`, `--shop-keyboard-inset`, РІС‹СЃРѕС‚С‹ CartSheet / `stackBottomPx` (pay stack) / `cartSheetThresholds`
- #67 С‚РµСЃС‚ В«34pxВ» (`shop_telegram_webview_ui_test.mjs`) вЂ” Р·РЅР°С‡РµРЅРёРµ > 8 РЅРµ РјРµРЅСЏРµС‚СЃСЏ
- С‡РµРє / peek-only / СЃС‚СЂРµР»РєР° / `Г—`

## РџСЂРѕРІРµСЂРєР°

- `node --test test/javascript/shop_safe_bottom_min_test.mjs` вЂ” 11/0
- Р·РѕРЅР° JS (`shop_*` `order_status*` `active_orders*` `cart_sheet*` `catalog*` `contact*` `order_receipt*` `sticky*` `order_cancel*` `order_action*`, 33 С„Р°Р№Р»Р°) вЂ” 344/1 (legacy В«422/500В»)
- Rails (telegram/webview/safe, b113_s2*, cart_sheet, catalog filter/sort, contact support, order receipt, order_status_sheet вЂ” 11 С„Р°Р№Р»РѕРІ) вЂ” 67/0
- РІРёР·СѓР°Р»СЊРЅРѕ: Android (inset 0) вЂ” CartSheet РІ peek РїРѕРґРЅСЏС‚ РЅР° 8px; iPhone вЂ” Р±РµР· РёР·РјРµРЅРµРЅРёР№ (34px). РЈСЃС‚СЂРѕР№СЃС‚РІРѕ / Fly вЂ” РїРѕСЃР»Рµ deploy

## DoD

- [x] inset 0 в†’ РѕС‚СЃС‚СѓРї 8px; inset 34 в†’ 34px
- [x] РІСЃРµ bottom-sheet Р±РµСЂСѓС‚ РѕС‚СЃС‚СѓРї РёР· `--shop-safe-bottom`
- [x] РґРѕР±Р°РІРєРё 24px/16px СЃРѕС…СЂР°РЅРµРЅС‹
- [x] Review + CI green

---

# todo вЂ” TASK_84-RECEIPT-ARROW-EXT (РґРѕРї.Р·Р°РґР°С‡Р° 2): СЃС‚СЂРµР»РєР° `>` / `v` РЅР° РєРЅРѕРїРєРµ В«РЎРѕСЃС‚Р°РІ Р·Р°РєР°Р·Р°В»

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **РћСЃРЅРѕРІР°РЅРёРµ** | [TASK_84-RECEIPT-ARROW-EXT](../milestones/veha_2/requirements/customer_tasks/TASK-84-RECEIPT-ARROW-EXT-РЎС‚СЂРµР»РєР°-СЃРѕСЃС‚РѕСЏРЅРёСЏ-РЅР°-РєРЅРѕРїРєРµ-РЎРѕСЃС‚Р°РІ-Р·Р°РєР°Р·Р°.md) вЂ” СЃС†РµРЅР°СЂРёР№ РІР»Р°РґРµР»СЊС†Р° 2026-10-01 В· СЃС‚СЂРµР»РєР° С‚РѕР»СЊРєРѕ РЅР° РєРЅРѕРїРєРµ С‡РµРєР° |
| **Р РµРІРµСЂСЃРёСЂСѓРµС‚** | Р·Р°РїСЂРµС‚ В«РЅРѕРІС‹Рµ СЃС‚СЂРµР»РєРёВ» РІ Scope TASK_84-RECEIPT-DISPLAY-EXT (С‚РѕР»СЊРєРѕ РєРЅРѕРїРєР° С‡РµРєР°); chevron #36 РЅР° С€Р°РїРєРµ Рё С‚РµСЃС‚ #35 РѕСЃС‚Р°СЋС‚СЃСЏ |
| **РЎС‚Р°С‚СѓСЃ** | REVIEW `[x]` В· CI green [36832232323](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36832232323) РЅР° `f4658bb7` В· deploy Р·Р°РїСЂРµС‰С‘РЅ |

## SBR

- [x] intake `86a123ce`
- [x] RED `c0aef683` вЂ” `active_orders_receipt_arrow_test.mjs` 3 fail (SSR: С‚РµРєСЃС‚ РєРЅРѕРїРєРё, `aria-expanded`, `aria-hidden` СЃС‚СЂРµР»РєР°)
- [x] GREEN `d3f929a8` вЂ” `ActiveOrdersAccordion.svelte`: `<span class="aoa__receipt-arrow" aria-hidden="true">{row.chevron}</span>` РІ РєРЅРѕРїРєРµ В· Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS вЂ” JS 605 (60 fail = legacy baseline) В· `vite build` OK В· Rails 18 С„Р°Р№Р»РѕРІ 100/0
- [x] `/review` вЂ” bugbot 0 В· security 0 В· `/crit-audit` CLEAN (`406b10e7`) В· push В· CI + Semgrep + CodeQL green [36832232323](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36832232323)

## Р¤Р°Р№Р»С‹

- `app/frontend/components/ActiveOrdersAccordion.svelte` вЂ” СЃС‚СЂРµР»РєР° РІ `aoa__receipt-cta` + CSS `.aoa__receipt-arrow`
- `test/javascript/active_orders_receipt_arrow_test.mjs` вЂ” РЅРѕРІС‹Р№

## РќРµ Р»РѕРјР°С‚СЊ

- С€Р°РїРєР° СЃС‚СЂРѕРєРё Р±РµР· СЃС‚СЂРµР»РєРё (chevron #36 РЅРµ РІРѕР·РІСЂР°С‰Р°РµРј, С‚РµСЃС‚ #35 В«РЅРµС‚ `aoa__chevron`В»)
- `LABELS.receipt` = В«РЎРѕСЃС‚Р°РІ Р·Р°РєР°Р·Р°В» (`orderStatusNotifyActions.js`) Рё С‚РµСЃС‚С‹ РЅР° РЅРµРіРѕ; `aria-label` РєРЅРѕРїРєРё Р±РµР· СЃС‚СЂРµР»РєРё
- С‡РµРє / `fitReceiptInView` / peek-only (`OrderStatusSheet.svelte`) / `Г—` / polling / Cable

## РџСЂРѕРІРµСЂРєР°

- `node --test test/javascript/active_orders_receipt_arrow_test.mjs` вЂ” 3/0
- Р·РѕРЅР° JS (`order_status*` `active_orders*` `cart_sheet*` `sticky*` `order_cancel*` `order_action*` `subscription_offer_banner*`) вЂ” 197/1 (legacy В«422/500В»)
- Р±СЂР°СѓР·РµСЂ вЂ” browser MCP Р·Р°РІРёСЃ 2026-10-01, РЅРµ РїСЂРѕР№РґРµРЅРѕ (SSR РїРѕРєСЂС‹РІР°РµС‚ С‚РµРєСЃС‚ Рё `aria-expanded`)

## DoD

- [x] СЃРІС‘СЂРЅСѓС‚ вЂ” В«РЎРѕСЃС‚Р°РІ Р·Р°РєР°Р·Р° >В», `aria-expanded="false"`
- [x] РѕС‚РєСЂС‹С‚ вЂ” В«РЎРѕСЃС‚Р°РІ Р·Р°РєР°Р·Р° vВ», `aria-expanded="true"`
- [x] Review + CI green

---

# todo вЂ” TASK_84-PEEK-ONLY-EXT (РґРѕРї.Р·Р°РґР°С‡Р° 1): СЃС‚Р°С‚СѓСЃРЅР°СЏ С€С‚РѕСЂРєР° С‚РѕР»СЊРєРѕ peek

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **РћСЃРЅРѕРІР°РЅРёРµ** | [TASK_84-PEEK-ONLY-EXT](../milestones/veha_2/requirements/customer_tasks/TASK-84-PEEK-ONLY-EXT-РЎС‚Р°С‚СѓСЃРЅР°СЏ-С€С‚РѕСЂРєР°-РѕСЃС‚Р°С‘С‚СЃСЏ-РІ-peek-РїСЂРё-РѕС‚РєСЂС‹С‚РѕРј-С‡РµРєРµ.md) вЂ” СЃС†РµРЅР°СЂРёР№ РІР»Р°РґРµР»СЊС†Р° 2026-10-01 В· РІР°СЂРёР°РЅС‚ (Р°): CartSheet РЅРµ РїРѕРґРЅРёРјР°РµРј |
| **Р РµРІРµСЂСЃРёСЂСѓРµС‚** | `expanded` СЃС‚Р°С‚СѓСЃРЅРѕР№ С€С‚РѕСЂРєРё РїСЂРё РѕС‚РєСЂС‹С‚РѕРј С‡РµРєРµ + Rails-С‚РµСЃС‚ В«вЂ¦EXPANDEDВ» |
| **РЎС‚Р°С‚СѓСЃ** | REVIEW `[x]` В· CI green [36825940981](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36825940981) РЅР° `f6f95987` В· deploy Р·Р°РїСЂРµС‰С‘РЅ |

## SBR

- [x] intake `c4f4bd0e`
- [x] RED `8f795504` вЂ” 3 fail: РЅРµС‚ `ORDER_STATUS_SHEET_MODES.EXPANDED`, РЅРµС‚ `.expanded` CSS/РєР»Р°СЃСЃР°, РµСЃС‚СЊ `.receipt-open { overflow-y: auto }` Р±РµР· `max-height`; Rails `mount_acceptance` РїРµСЂРµРІС‘СЂРЅСѓС‚ РЅР° `refute EXPANDED`
- [x] GREEN `8b75d868` вЂ” `OrderStatusSheet.svelte`: СЂРµР¶РёРј С‚РѕР»СЊРєРѕ hidden/peek, `class:receipt-open`, CSS `.expanded` СѓРґР°Р»С‘РЅ В· Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS вЂ” JS 602 (60 fail = legacy baseline) В· `vite build` OK В· Rails 18 С„Р°Р№Р»РѕРІ (С€С‚РѕСЂРєР°, CartSheet b113_s2*, quick_repeat_section, catalog_hidden, active orders) 100/0
- [x] `/review` вЂ” bugbot 0 В· security 0 В· `/crit-audit` CLEAN (`44ec7814`) В· push В· CI + Semgrep + CodeQL green [36825940981](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36825940981)

## Р¤Р°Р№Р»С‹

- `app/frontend/components/OrderStatusSheet.svelte` вЂ” `receiptOpen` РІРјРµСЃС‚Рѕ `panelExpanded`; `statusSheetMode` Р±РµР· `EXPANDED`; `.oss__panel.receipt-open { overflow-y: auto }`
- `test/javascript/order_status_sheet_peek_only_test.mjs` вЂ” РЅРѕРІС‹Р№
- `test/integration/shop/order_status_sheet_mount_acceptance_test.rb` вЂ” `EXPANDED` в†’ `refute`

## РќРµ Р»РѕРјР°С‚СЊ

- С‡РµРє (`ActiveOrdersAccordion`, `fitReceiptInView`, `receiptView`), `Г—` (СѓР¶Рµ СѓРґР°Р»С‘РЅ), polling/Cable, `lib/orderStatusSheet.js` (`ORDER_STATUS_SHEET_MODES` СЃ `EXPANDED` РѕСЃС‚Р°С‘С‚СЃСЏ)
- `CartSheet.svelte` Рё РµРіРѕ `MODE_EXPANDED` (РґСЂСѓРіРѕР№ СЂРµР¶РёРј вЂ” С€С‚РѕСЂРєР° РєРѕСЂР·РёРЅС‹)
- #42 РІС‹СЃРѕС‚Р° peek `min(22vh, 8.5rem)`

## РџСЂРѕРІРµСЂРєР°

- `node --test test/javascript/order_status_sheet_peek_only_test.mjs` вЂ” 5/0
- Р·РѕРЅР° JS (`order_status*` `active_orders*` `cart_sheet*` `sticky*` `order_cancel*` `order_action*`) вЂ” 173/1 (legacy В«422/500В»)
- Rails `order_status_sheet_mount_acceptance`, `order_status_expanded_stack_canon`, `active_order_cart_peek_stack`, `api/active_orders_receipt` вЂ” 20/0
- Р±СЂР°СѓР·РµСЂ 390Г—844: peek 136px РґРѕ/РїРѕСЃР»Рµ РєР»РёРєР°, С‡РµРє 101px РІРЅСѓС‚СЂРё РїР°РЅРµР»Рё, `Total Amount` С‡РµСЂРµР· scroll С‡РµРєР°, РїР°РЅРµР»СЊ РЅРµ СЃРєСЂРѕР»Р»РёС‚СЃСЏ вЂ” [MEASURE](../milestones/veha_2/artifacts/active_orders_receipt_display_restore/peek_only_2026-10-01/MEASURE.md)

## DoD

- [x] РѕС‚РєСЂС‹С‚РёРµ С‡РµРєР° вЂ” `data-status-sheet-mode="peek"`, РІС‹СЃРѕС‚Р° РЅРµ СЂР°СЃС‚С‘С‚
- [x] С‡РµРє РІРЅСѓС‚СЂРё peek СЃРѕ СЃРІРѕРµР№ РїСЂРѕРєСЂСѓС‚РєРѕР№, `Total Amount` РґРѕСЃС‚РёР¶РёРј
- [x] Р·Р°РєСЂС‹С‚РёРµ С‡РµРєР° вЂ” peek
- [x] Review + CI green

---

# todo вЂ” TASK_83 РџР°С‚С‡ 1 (2026-09-30): СѓР±СЂР°С‚СЊ Г— РёР· СЃС‚Р°С‚СѓСЃРЅРѕР№ С€С‚РѕСЂРєРё (patch v1)

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **РћСЃРЅРѕРІР°РЅРёРµ** | [TASK_83 В§ РџР°С‚С‡ 1: 2026-09-30](../milestones/veha_2/requirements/customer_tasks/TASK-83-status-sheet-dismiss.md) вЂ” В«РСЃРїСЂР°РІР»РµРЅРЅС‹Р№ СЃС†РµРЅР°СЂРёР№В», Subtask 1, 4, 5, 6 (patch v1) |
| **РўРёРї** | РїР°С‚С‡ (РЅРµ РґРѕРї.Р·Р°РґР°С‡Р°) В· РѕСЃС‚Р°Р»СЊРЅС‹Рµ Subtask TASK_83 вЂ” РєРѕРЅС‚РµРєСЃС‚, РЅРµ С‚СЂРѕРіР°Р»РёСЃСЊ |
| **РЎС‚Р°С‚СѓСЃ** | REVIEW `[x]` В· CI green [36821953421](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36821953421) РЅР° `f2253be4` В· deploy Р·Р°РїСЂРµС‰С‘РЅ РґРѕ Р·Р°РєСЂС‹С‚РёСЏ Р·Р°РґР°С‡Рё |

## SBR

- [x] SPEC вЂ” `dismissOrder` (lib) РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РІ `test/javascript/order_status_sheet_test.mjs` в†’ **РѕСЃС‚Р°РІР»РµРЅ**; UI-С†РµРїРѕС‡РєР° `onDismissOrder` в†’ `onDismiss` в†’ `aoa__dismiss` РїРѕСЃР»Рµ СѓРґР°Р»РµРЅРёСЏ РєРЅРѕРїРєРё РјРµСЂС‚РІР° в†’ СѓР±СЂР°РЅР° (Scope РїР°С‚С‡Р° СЂР°Р·СЂРµС€Р°РµС‚)
- [x] RED `f7a6dc49` вЂ” 4 fail: SSR В«Г— РЅРµС‚ РІ DOMВ», source В«РЅРµС‚ `status-widget-dismiss`/В«РЎРєСЂС‹С‚СЊ СЃС‚Р°С‚СѓСЃ Р·Р°РєР°Р·Р°В»В», В«РЅРµС‚ `aoa__dismiss`/`onDismiss`В», В«С€С‚РѕСЂРєР° РЅРµ РїСЂРѕР±СЂР°СЃС‹РІР°РµС‚ `onDismiss={onDismissOrder}`В»
- [x] GREEN `93f500ee` вЂ” СѓРґР°Р»РµРЅС‹ РєРЅРѕРїРєР° `Г—`, РїСЂРѕРї `onDismiss`, CSS `.aoa__dismiss` (`ActiveOrdersAccordion.svelte`); РїСЂРѕР±СЂРѕСЃ `onDismiss`, `onDismissOrder`, РёРјРїРѕСЂС‚ `dismissOrder` (`OrderStatusSheet.svelte`) В· Entire `01M3SBAXJXWA8X0DWT56SNEE36`
- [x] `/regress` PASS вЂ” JS 597 (60 fail = legacy baseline) В· `vite build` OK В· Rails active_orders(_receipt) + cart_peek_stack 13/0
- [x] `/review` вЂ” bugbot 0 В· security 0 В· `/crit-audit` CLEAN (`0b54ac21`) В· push В· CI СЃРЅР°С‡Р°Р»Р° red: `scan_ruby` brakeman `--ensure-latest` (РІС‹С€РµР» 8.1.0, Рє РїР°С‚С‡Сѓ РЅРµ РѕС‚РЅРѕСЃРёС‚СЃСЏ) в†’ bump `f2253be4` в†’ CI + Semgrep + CodeQL green [36821953421](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36821953421)
- [ ] РїРѕСЃР»Рµ Review: РЅРѕРјРµСЂР° СЃС‚СЂРѕРє РІ TASK_83 Рё COMPONENT_MAP (`COMPONENT_MAP.md` РІ СЌС‚РѕР№ РёС‚РµСЂР°С†РёРё С‚РѕР»СЊРєРѕ С‡РёС‚Р°Р»СЃСЏ)
- [ ] deploy вЂ” **Р·Р°РїСЂРµС‰С‘РЅ** РґРѕ Р·Р°РєСЂС‹С‚РёСЏ Р·Р°РґР°С‡Рё; Р·Р°С‚РµРј Fly MCP Point A

## Р¤Р°Р№Р»С‹

- `app/frontend/components/ActiveOrdersAccordion.svelte` вЂ” в€’РєРЅРѕРїРєР° `Г—`, в€’РїСЂРѕРї `onDismiss`, в€’CSS `.aoa__dismiss`
- `app/frontend/components/OrderStatusSheet.svelte` вЂ” в€’`onDismiss={onDismissOrder}`, в€’`onDismissOrder`, в€’РёРјРїРѕСЂС‚ `dismissOrder`
- `test/javascript/active_orders_accordion_test.mjs` вЂ” С‚РµСЃС‚ В«aria-label РЎРєСЂС‹С‚СЊВ» в†’ SSR В«Г— РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚, CTA С‡РµРєР° Рё action buttons РЅР° РјРµСЃС‚РµВ»
- `test/javascript/order_status_notify_actions_test.mjs` вЂ” С‚РµСЃС‚С‹ РЅР°Р»РёС‡РёСЏ `Г—` в†’ РєРѕРЅС‚СЂР°РєС‚ РѕС‚СЃСѓС‚СЃС‚РІРёСЏ + С‚РµСЃС‚ РїСЂРѕР±СЂРѕСЃР° РёР· С€С‚РѕСЂРєРё

## РќРµ Р»РѕРјР°С‚СЊ

- Р±Р»РѕРє С‡РµРєР° Рё CTA (#84 / TASK_84-EXT): `receiptView`, `receiptPanelView`, fit/scroll С‡РµРєР°, С„РѕСЂРјР° `accordionState`
- `dismissOrder` / `refreshMode` РІ `lib/orderStatusSheet.js` Рё РёС… С‚РµСЃС‚С‹ (`order_status_sheet_test.mjs`)
- `OrderCancelModal` `onDismiss` (`OrderStatusSheet.svelte`), `OrderStatus.svelte` `onDismiss` вЂ” РґСЂСѓРіРѕР№ СЃРјС‹СЃР», РЅРµ С‚СЂРѕРіР°Р»РёСЃСЊ
- status / polling / ActionCable / reconnect / `OrderActionButtons` / cancel flow

## РџСЂРѕРІРµСЂРєР°

- `node --test test/javascript/active_orders_accordion_test.mjs test/javascript/order_status_notify_actions_test.mjs` вЂ” 51/0
- Р·РѕРЅР° (13 С„Р°Р№Р»РѕРІ `order_status*` `active_orders*` `cart_sheet*` `sticky*` `order_cancel*` `order_action*`) вЂ” 168/1; 1 fail `order_action_buttons_cancel_test` В«422/500В» вЂ” legacy, СѓР¶Рµ РІ ISSUES, РїР°РґР°Р» Рё РґРѕ РїР°С‚С‡Р°
- Fly MCP Point A вЂ” РїРѕСЃР»Рµ deploy РїРѕ Р°РїСЂСѓРІСѓ

## DoD

- [x] Subtask 1: `Г—` РЅРµС‚ РІ DOM СЃС‚Р°С‚СѓСЃРЅРѕР№ С€С‚РѕСЂРєРё
- [x] Subtask 4вЂ“5: status / polling / Cable / С‡РµРє Р±РµР· РёР·РјРµРЅРµРЅРёР№; РјС‘СЂС‚РІС‹Р№ РїСЂРѕР±СЂРѕСЃ `onDismiss` СѓРґР°Р»С‘РЅ, `dismissOrder` (lib) СЃРѕС…СЂР°РЅС‘РЅ
- [x] Subtask 6: С‚РµСЃС‚С‹ РЅР° РЅР°Р»РёС‡РёРµ `Г—` Р·Р°РјРµРЅРµРЅС‹ РєРѕРЅС‚СЂР°РєС‚РѕРј РѕС‚СЃСѓС‚СЃС‚РІРёСЏ
- [x] Review + CI green

---

# todo вЂ” РџР°С‚С‡Рё 2026-09-30: TASK_83 (СѓР±СЂР°С‚СЊ Г—) + TASK_84-RECEIPT-DISPLAY-EXT (receipt runtime)

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **РћСЃРЅРѕРІР°РЅРёРµ** | read-only Р°СѓРґРёС‚ 2026-09-30 В· РєР»Р°СЃСЃРёС„РёРєР°С†РёСЏ `/patch` |
| **РџР°С‚С‡ A** | [TASK_83 В§ РџР°С‚С‡ 1](../milestones/veha_2/requirements/customer_tasks/TASK-83-status-sheet-dismiss.md) вЂ” СѓР±СЂР°С‚СЊ `Г—` |
| **РџР°С‚С‡ B** | [TASK_84-RECEIPT-DISPLAY-EXT В§ РџР°С‚С‡ 1](../milestones/veha_2/requirements/customer_tasks/TASK-84-RECEIPT-DISPLAY-EXT-Р’РѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёРµ-С„Р°РєС‚РёС‡РµСЃРєРѕРіРѕ-РѕС‚РѕР±СЂР°Р¶РµРЅРёСЏ-СЃРѕСЃС‚Р°РІР°-С‡РµРєР°-РІ-ActiveOrdersAccordion.md) вЂ” DOM-РєРѕРЅС‚СЂР°РєС‚ receipt + РІРЅСѓС‚СЂРµРЅРЅРёР№ scroll |
| **Р”РѕРї.Р·Р°РґР°С‡Рё (backlog)** | В«С‚РѕР»СЊРєРѕ peekВ» В· РЅРѕРІС‹Рµ `>`/`v` В· min Home Indicator (С€С‚РѕСЂРєР° / РІСЃРµ СЌРєСЂР°РЅС‹) вЂ” [DEMO_FEEDBACK](../milestones/veha_2/requirements/DEMO_FEEDBACK.md) |
| **РЎС‚Р°С‚СѓСЃ** | SPEC `[x]` В· RED pending |

## SBR: SPEC в†’ RED

- [x] SPEC вЂ” РїР°С‚С‡Рё РѕС„РѕСЂРјР»РµРЅС‹
- [x] РџР°С‚С‡ B RED-РїРѕРїС‹С‚РєР°: SSR DOM-С‚РµСЃС‚С‹ (`svelte_ssr_helper.mjs` + 3 С‚РµСЃС‚Р° РІ `active_orders_accordion_test.mjs`) **СЃСЂР°Р·Сѓ Р·РµР»С‘РЅС‹Рµ** вЂ” РїРѕСЃР»Рµ `openOrderReceipt` HTML СЃРѕРґРµСЂР¶РёС‚ `.aoa__receipt`, РїРѕР·РёС†РёСЋ, РјРѕРґРёС„РёРєР°С‚РѕСЂ, `Total Amount`, inline `max-height: 350px; overflow-y: auto`, Р±РµР· `<button>`; С‚РѕР»СЊРєРѕ СЂР°СЃРєСЂС‹С‚С‹Р№ Р·Р°РєР°Р· СЂРµРЅРґРµСЂРёС‚ С‡РµРє. РњСѓС‚Р°С†РёСЏ `{#if false}` в†’ 2 fail (С‚РµСЃС‚ РЅРµ РїСѓСЃС‚РѕР№). РЎС‚РµР№С‚: `$state` proxy (`OrderStatusSheet.svelte:47`), `sync()` СЃРѕС…СЂР°РЅСЏРµС‚ СЂР°СЃРєСЂС‹С‚С‹Р№ id (`:73вЂ“78`) вЂ” РґРµС„РµРєС‚Р° РЅРµС‚. **Р’С‹РІРѕРґ: СЂРµРЅРґРµСЂ РєРѕРјРїРѕРЅРµРЅС‚Р° РёСЃРїСЂР°РІРµРЅ; RED РЅРµ РІРѕСЃРїСЂРѕРёР·РІРµРґС‘РЅ.**
- [x] РџР°С‚С‡ B вЂ” РїСЂРёС‡РёРЅР° **РґРѕРєР°Р·Р°РЅР°** РІ Р±СЂР°СѓР·РµСЂРµ ([MEASURE](../milestones/veha_2/artifacts/active_orders_receipt_display_restore/patch1_browser_2026-09-30/MEASURE.md)): 390Г—844, РєР»РёРє CTA в†’ `.aoa__receipt` 196px РІ DOM, РІРёРґРЅРѕ **61px**; СЂРµР¶СѓС‚ `.oss__panel.embedded.expanded` 224px (`OrderStatusSheet.svelte:348вЂ“350`, С‡РµРє РЅР° 145px РЅРёР¶Рµ РІРµСЂС…Р°) Рё `CartSheet` `overflow:hidden` 287px. Р’РЅРµС€РЅСЏСЏ РїР°РЅРµР»СЊ СЃРєСЂРѕР»Р»РёС‚СЃСЏ (498 > 224) вЂ” Subtask 11 РЅР°СЂСѓС€РµРЅ. РћРґРЅРѕР№ CSS-РїСЂР°РІРєРё РїР°РЅРµР»Рё РјР°Р»Рѕ вЂ” СЂРµР¶РµС‚ `CartSheet` (РІРЅРµ scope)
- [x] РџР°С‚С‡ B вЂ” scope: РІР°СЂРёР°РЅС‚ 1 (РІ Р°РєРєРѕСЂРґРµРѕРЅРµ, Р±РµР· `CartSheet`); РїРѕРґСЉС‘Рј `CartSheet` РїСЂРё РѕС‚РєСЂС‹С‚РѕРј С‡РµРєРµ вЂ” РєР°РЅРґРёРґР°С‚ РІ РґРѕРї.Р·Р°РґР°С‡Сѓ
- [x] РџР°С‚С‡ B RED `d237ed6d` вЂ” `fitReceiptInView` (Р·Р°РјРµСЂ 390Г—844) + source-РєРѕРЅС‚СЂР°РєС‚ `overscroll-behavior: contain`
- [x] РџР°С‚С‡ B GREEN вЂ” `fitReceiptInView` + fit/scroll РІ `ActiveOrdersAccordion.svelte`; С‚РµСЃС‚С‹ 46/0, Р·РѕРЅР° 134/0; Р±СЂР°СѓР·РµСЂ: С‡РµРє РІРёРґРµРЅ С†РµР»РёРєРѕРј, Total Amount С‡РµСЂРµР· СЃРІРѕР№ scroll, РІРЅРµС€РЅСЏСЏ РїР°РЅРµР»СЊ РЅРµ СЃРєСЂРѕР»Р»РёС‚СЃСЏ ([MEASURE](../milestones/veha_2/artifacts/active_orders_receipt_display_restore/patch1_browser_2026-09-30/MEASURE.md))
- [x] РџР°С‚С‡ B `/regress` PASS вЂ” JS 592 (60 fail = legacy baseline) В· zone 134/0 В· vite build В· Rails active_orders_receipt 4/0
- [x] РџР°С‚С‡ B `/review`: bugbot в†’ 2 СЂР°СѓРЅРґР° С„РёРєСЃРѕРІ (transitionend refit + stale async guard `74b0dd48`; СЂРµР°Р»СЊРЅС‹Р№ РѕС‚СЃС‚СѓРї CTAв†’С‡РµРє + ResizeObserver РЅР° CartSheet `0f06a868`) В· security С‡РёСЃС‚Рѕ В· `/crit-audit` CLEAN В· Р±СЂР°СѓР·РµСЂ: refit РїРѕСЃР»Рµ Р°РЅРёРјР°С†РёРё 101в†’171px, С€С‚РѕСЂРєР° в€’40px в†’ 131px, РЅРёР· РїРѕ РєР»РёРїСѓ
- [x] РџР°С‚С‡ B push `93d1dac` в†’ CI green [36745691728](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36745691728) + Semgrep/CodeQL
- [ ] РџР°С‚С‡ B deploy РїРѕ Р°РїСЂСѓРІСѓ в†’ Fly MCP Point A
- [x] РџР°С‚С‡ A RED `f7a6dc49` / GREEN `93f500ee` вЂ” СЃРј. Р±Р»РѕРє В«TASK_83 РџР°С‚С‡ 1В» РІС‹С€Рµ

## Р¤Р°Р№Р»С‹ (РѕР¶РёРґР°РµРјРѕ)

- `app/frontend/components/ActiveOrdersAccordion.svelte` вЂ” A: `aoa__dismiss` (190вЂ“202) В· B: РїСѓС‚СЊ СЂР°СЃРєСЂС‹С‚РёСЏ (38вЂ“41, 78вЂ“80, 263вЂ“288) С‚РѕР»СЊРєРѕ РїРѕ RED
- `app/frontend/components/OrderStatusSheet.svelte` вЂ” A: РїСЂРѕРї `onDismiss` (274), РµСЃР»Рё РјС‘СЂС‚РІС‹Р№ В· B: `.oss__panel.embedded.expanded` (344вЂ“350) С‚РѕР»СЊРєРѕ РµСЃР»Рё RED РґРѕРєР°Р¶РµС‚ РѕР±СЂРµР·Р°РЅРёРµ
- `app/frontend/lib/activeOrdersAccordion.js` вЂ” B, С‚РѕР»СЊРєРѕ РїРѕ RED
- `test/javascript/active_orders_accordion_test.mjs`, `test/javascript/order_status_notify_actions_test.mjs`
- `test/javascript/svelte_ssr_helper.mjs` (+1 РїСѓС‚СЊ: loader-С…СѓРє РєРѕРјРїРёР»СЏС†РёРё `.svelte` РґР»СЏ SSR)

## РќРµ Р»РѕРјР°С‚СЊ

- A РЅРµ С‚СЂРѕРіР°РµС‚ receipt; B РЅРµ С‚СЂРѕРіР°РµС‚ `Г—`/dismiss; РѕР±С‰РёР№ РѕР±СЉРµРєС‚ вЂ” `accordionState` (С„РѕСЂРјСѓ РЅРµ РјРµРЅСЏС‚СЊ)
- backend active-orders API, `OrdersController#active`, `ActiveOrdersPresenter`, polling, ActionCable, reconnect, push, wallet, cancel API, `OrderActionButtons`, cancel-modal
- `receiptView` вЂ” РїРѕРєР° РЅРµ РґРѕРєР°Р·Р°РЅРѕ, С‡С‚Рѕ РїСЂРѕР±Р»РµРјР° РІ РЅС‘Рј В· chevron #36 В· РЅРµРіР°С‚РёРІРЅС‹Р№ С‚РµСЃС‚ #35 В· Home Indicator / safe-area
- `COMPONENT_MAP.md` Рё РЅРѕРјРµСЂР° СЃС‚СЂРѕРє РІ TASK_83 вЂ” С‚РѕР»СЊРєРѕ РїРѕСЃР»Рµ Review

## Р РµС€РµРЅРёРµ РІР»Р°РґРµР»СЊС†Р° 2026-09-30

- DOM-С‚РµСЃС‚ РџР°С‚С‡Р° B: **SSR** вЂ” `svelte/compiler` + `svelte/server` `render()` СЃ `accordionState` РїРѕСЃР»Рµ `openOrderReceipt` (РїСѓС‚СЊ С‡РµСЂРµР· СЃС‚РµР№С‚, Р±РµР· РєР»РёРєР°); РЅРѕРІС‹С… Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ РЅРµС‚.
- РћРіСЂР°РЅРёС‡РµРЅРёРµ: SSR РЅРµ РїРѕРєСЂС‹РІР°РµС‚ РєР»РёРє Рё РЅРµ РјРѕР¶РµС‚ РїСЂРѕРІРµСЂРёС‚СЊ scroll-РєРѕРЅС‚СЂР°РєС‚ (layout) в†’ Subtask 11 РїСЂРѕРІРµСЂСЏРµС‚СЃСЏ РІРёР·СѓР°Р»СЊРЅРѕ/Fly MCP РїРѕСЃР»Рµ deploy; РІ РѕС‚С‡С‘С‚Рµ GREEN СѓРєР°Р·Р°С‚СЊ СЏРІРЅРѕ.
- РџРѕСЂСЏРґРѕРє: **B в†’ A**.

## РџСЂРѕРІРµСЂРєР°

- `node --test test/javascript/active_orders_accordion_test.mjs test/javascript/order_status_notify_actions_test.mjs`
- Р·РѕРЅР°: order status sheet / notify actions / accordion
- Fly MCP Point A вЂ” РїРѕСЃР»Рµ deploy РїРѕ Р°РїСЂСѓРІСѓ

## DoD

- [ ] B: DOM СЃРѕРґРµСЂР¶РёС‚ `.aoa__receipt`, РїРѕР·РёС†РёСЋ, `Total Amount` РїРѕСЃР»Рµ С„Р°РєС‚РёС‡РµСЃРєРѕРіРѕ СЂР°СЃРєСЂС‹С‚РёСЏ
- [ ] B: scroll С‚РѕР»СЊРєРѕ РІРЅСѓС‚СЂРё receipt, РІРЅРµС€РЅСЏСЏ РїР°РЅРµР»СЊ Р±РµР· scroll
- [ ] A: `Г—` РЅРµС‚ РІ DOM; status/polling/Cable Р±РµР· РёР·РјРµРЅРµРЅРёР№; С‚РµСЃС‚С‹ РЅР° РЅР°Р»РёС‡РёРµ `Г—` Р·Р°РјРµРЅРµРЅС‹ РїРѕР·РёС‚РёРІРЅС‹Рј РєРѕРЅС‚СЂР°РєС‚РѕРј РѕС‚СЃСѓС‚СЃС‚РІРёСЏ

---

# todo вЂ” TASK_99: iOS вЂ” СЃРёСЃС‚РµРјРЅС‹Р№ РґРёР°Р»РѕРі СЂР°Р·СЂРµС€РµРЅРёСЏ WebPush

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **ID** | TASK_99 |
| **Google** | https://docs.google.com/document/d/1RFadqCs70QvUX2dFZmL98SEtPd1N5sGSEy-hNNrlVwU/edit (РїР°С‚С‡РµР№/РґРѕРї.Р·Р°РґР°С‡ РЅРµС‚) |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/ios_webpush_permission/GATES.md) |
| **РЎС‚Р°С‚СѓСЃ** | REVIEW `[x]` В· CI green В· Р¶РґС‘С‚ deploy (Р°РїСЂСѓРІ) |

## SBR

- [x] /unlazy ledger (`def97615`)
- [x] RED `b016f7dc` вЂ” 9 РЅРѕРІС‹С… С‚РµСЃС‚РѕРІ fail (РїРѕСЂСЏРґРѕРє, sync requestPermission, denied/default/unsupported, Р°РєРєРѕСЂРґРµРѕРЅ, СЃС‚Р°С‚РёС‡РµСЃРєРёР№ РёРјРїРѕСЂС‚)
- [x] GREEN `48fa264` вЂ” 27/0 В· G1вЂ“G3 PASS В· Entire `01M3PPE93CDW728HQ2PP4ZNDM8`
- [x] /regress вЂ” JS 584: 60 fail legacy (= `def97615`, ISSUES) В· Rails 19/0 В· G1вЂ“G3 reverify
- [x] REVIEW вЂ” bugbot 0 В· security 0 В· CI green [36578386943](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578386943) РЅР° `180d88fc`
- [ ] deploy РїРѕ Р°РїСЂСѓРІСѓ В· G4 iPhone В· G5 Fly

## Р¤Р°Р№Р»С‹ (РѕР¶РёРґР°РµРјРѕ)

- `app/frontend/lib/firebasePush.js` вЂ” `requestPermission()` РїРµСЂРІС‹Рј async; Firebase-РїСЂРѕРІРµСЂРєРё РїРѕСЃР»Рµ `granted`; `opts.deps` РґР»СЏ С‚РµСЃС‚РѕРІ (РґРµС„РѕР»С‚ = СЂРµР°Р»СЊРЅС‹Рµ С„СѓРЅРєС†РёРё)
- `app/frontend/lib/orderStatusNotifyActions.js` вЂ” СЃС‚Р°С‚РёС‡РµСЃРєРёР№ РёРјРїРѕСЂС‚ `registerShopPush`
- `test/javascript/order_status_push_subscribe_test.mjs`

## РќРµ Р»РѕРјР°С‚СЊ

- backend `OrderStatusPushNotifier` / `ReadyPushJob` / `FcmClient` В· РєРѕРЅС‚СЂР°РєС‚ `/push/register` В· PassKit / `WALLET_SIMULATE` В· SMS В· `push_enabled`/`push_token`
- `getToken()` + СЂРµРіРёСЃС‚СЂР°С†РёСЏ РїРѕСЃР»Рµ `granted` В· РѕСЃС‚Р°Р»СЊРЅР°СЏ Р»РѕРіРёРєР° Р°РєРєРѕСЂРґРµРѕРЅР°

## РџСЂРѕРІРµСЂРєР°

- `node --test test/javascript/order_status_push_subscribe_test.mjs` (РўР— `npm test`/`typecheck` РІ СЂРµРїРѕ РЅРµС‚)
- G3 Р·РѕРЅР°: notify actions / init / accordion / SW / order status sheet
- С„РёР·РёС‡РµСЃРєРёР№ iPhone + Fly MCP вЂ” РїРѕСЃР»Рµ deploy РїРѕ Р°РїСЂСѓРІСѓ

---

# todo вЂ” TASK_97: Push-РѕС„С„РµСЂ РїРѕРґРїРёСЃРєРё

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **ID** | TASK_97 В· CBR #97 |
| **Р”РѕРє** | [TASK-97-Push-РѕС„С„РµСЂ-РїРѕРґРїРёСЃРєРё.md](../milestones/veha_2/requirements/customer_tasks/TASK-97-Push-РѕС„С„РµСЂ-РїРѕРґРїРёСЃРєРё.md) |
| **Google** | https://docs.google.com/document/d/1VN1VSBHuGtIjluoNFATbmAw0OsfL_UBqKnPho_fTtU4/edit?usp=drivesdk |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/subscription_offer_push/GATES.md) |
| **РўРёРї** | вЉ‚ TASK_96 Subtask 14вЂ“21 В· СЂРµР°Р»РёР·Р°С†РёСЏ СѓР¶Рµ РІ `63a317a1` (GREEN #96) В· РѕСЃС‚Р°С‚РѕРє вЂ” concurrent idempotency + Р·Р°РєСЂС‹С‚РёРµ |
| **РЎС‚Р°С‚СѓСЃ** | REVIEW вЂ” bugbot 0 В· security 0 В· push/CI В· G4 Fly РїРѕСЃР»Рµ deploy |

## SBR

- [x] PHASE 0 intake (`a98bf595`)
- [x] /unlazy ledger вЂ” G1вЂ“G3 PASS, G4 Fly pending (`a79978d3`)
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED вЂ” G5: `OfferPushNotifier.call` Г—2 РѕРґРЅРёРј РєР»СЋС‡РѕРј в†’ 2 push (`d798968b`); РїР°СЂР°Р»Р»РµР»СЊРЅС‹Р№ `mark_shown` СѓР¶Рµ Р±С‹Р» РІРµСЂРµРЅ
- [x] PHASE 2 GREEN вЂ” advisory xact lock РІ `OfferPushNotifier#create_once` В· 14/0 В· `--reverify` G1вЂ“G3, G5 PASS
- [x] /regress вЂ” `--reverify` G1вЂ“G3, G5 В· Р·РѕРЅР° 28 С„Р°Р№Р»РѕРІ 176/0 В· concurrent Г—5 PASS
- [ ] PHASE 3 REVIEW вЂ” push/CI В· deploy РїРѕ Р°РїСЂСѓРІСѓ В· G4 Fly

## РџРѕРєСЂС‹С‚РёРµ TASK_97 СЂРµР°Р»РёР·Р°С†РёРµР№ #96 (СЃРІРµСЂРєР° SPEC)

| TASK_97 | Р“РґРµ СЃРґРµР»Р°РЅРѕ | РўРµСЃС‚ |
|---|---|---|
| Subtask 1 notifier С‡РµСЂРµР· СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ FCM | `OfferPushNotifier` в†’ `PushNotification` + `Shop::SendPushNotificationJob` | `offer_push_notifier_test` |
| Subtask 2 side-effect `not_shown в†’ shown` | `OfferPresentationService#mark_shown` в†’ `after_shown_transition` (РїРѕСЃР»Рµ `with_lock`, С‚.Рµ. РїРѕСЃР»Рµ РєРѕРјРјРёС‚Р°) | С‚Рѕ Р¶Рµ |
| Subtask 3 `push_enabled_at = null` | guard РІ `OfferPushNotifier#call` | В«push_enabled_at nil в†’ no pushВ» |
| Subtask 4 idempotency РЅР° РїРµСЂРµС…РѕРґ | `transition_key = state.id:updated_at` + `already_sent?` РїРѕ `payload->>'offer_transition_key'`; РїРµСЂРµС…РѕРґ РїРѕРґ row-lock | РїРѕСЃР»РµРґРѕРІР°С‚РµР»СЊРЅС‹Рµ РїРѕРІС‚РѕСЂС‹ В· **concurrent вЂ” РЅРµС‚** |
| Subtask 5 РїРѕРІС‚РѕСЂ РїРѕСЃР»Рµ 3 Р·Р°РєР°Р·РѕРІ | РЅРѕРІС‹Р№ `updated_at` в†’ РЅРѕРІС‹Р№ РєР»СЋС‡ | В«re-show after dismiss + 3 ordersВ» |
| Subtask 6 `purchased` | `mark_shown` + `purchased?` РІ notifier | В«purchased в†’ no offer pushВ» |
| Subtask 7 РїСЂРѕРјРѕ 11в‚Ѕ | `should_show_banner` false в†’ РЅРµС‚ РїРµСЂРµС…РѕРґР° | В«GrowthPromo availableВ» |
| Subtask 8 РѕС€РёР±РєР° FCM | `rescue` РІ notifier + job `failed` Р±РµР· raise | 2 С‚РµСЃС‚Р° |
| Subtask 9 СЂРµРіСЂРµСЃСЃРёСЏ FCM | вЂ” | G3 (8 С„Р°Р№Р»РѕРІ) |
| РќРµ Р»РѕРјР°С‚СЊ в„–10 COMPONENT_MAP | СЃС‚СЂРѕРєР° `OfferPushNotifier` СѓР¶Рµ РµСЃС‚СЊ (TASK_96) | вЂ” |

## Р¤Р°Р№Р»С‹ (РѕР¶РёРґР°РµРјРѕ)

1. `test/services/subscriptions/offer_push_concurrency_test.rb` вЂ” **РЅРѕРІС‹Р№**: `use_transactional_tests = false` (С‚СЂР°РЅР·Р°РєС†РёРѕРЅРЅС‹Рµ С‚РµСЃС‚С‹ С€Р°СЂСЏС‚ РѕРґРЅРѕ СЃРѕРµРґРёРЅРµРЅРёРµ в†’ РїРѕС‚РѕРєРё СЃРµСЂРёР°Р»РёР·СѓСЋС‚СЃСЏ, РєР°Рє РІ `saved_card_store_test`), 4 РїРѕС‚РѕРєР° `OfferPresentationService#mark_shown` РѕРґРЅРѕРІСЂРµРјРµРЅРЅРѕ в†’ СЂРѕРІРЅРѕ 1 `push_notifications` `subscription_offer`, 1 `banner_shown`; РІС‚РѕСЂРѕР№ РєРµР№СЃ вЂ” 2 РїРѕС‚РѕРєР° `OfferPushNotifier.call` СЃ РѕРґРЅРёРј `transition_key` в†’ 1 push. Teardown С‡РёСЃС‚РёС‚ СЃРІРѕРё Р·Р°РїРёСЃРё (РѕР±СЂР°Р·РµС† вЂ” `test/integration/pg_inventory_test.rb`).
2. `app/services/subscriptions/offer_push_notifier.rb` вЂ” **С‚РѕР»СЊРєРѕ РµСЃР»Рё** РІС‚РѕСЂРѕР№ РєРµР№СЃ РєСЂР°СЃРЅС‹Р№: `already_sent?` + `create!` РЅРµ Р°С‚РѕРјР°СЂРЅС‹. Р¤РёРєСЃ Р±РµР· РјРёРіСЂР°С†РёРё вЂ” `transaction` + `pg_advisory_xact_lock(hashtext(transition_key))` РІРѕРєСЂСѓРі РїСЂРѕРІРµСЂРєРё Рё СЃРѕР·РґР°РЅРёСЏ.
3. `docs/operations/milestones/veha_2/artifacts/subscription_offer_push/GATES.md` вЂ” +G5 (concurrent-С‚РµСЃС‚).
4. `docs/operations/session/COMPONENT_MAP.md` вЂ” СЃС‚СЂРѕРєР° `OfferPushNotifier`: РІР»Р°РґРµР»РµС† `TASK_96 В· TASK_97` (Р±РµР· СЃРјРµРЅС‹ СЃРјС‹СЃР»Р°).
5. `customer_tasks/TASK-97-Push-РѕС„С„РµСЂ-РїРѕРґРїРёСЃРєРё.md` + CBR вЂ” СЃС‚Р°С‚СѓСЃ Р·Р°РєСЂС‹С‚РёСЏ СЃРѕ СЃСЃС‹Р»РєРѕР№ РЅР° `63a317a1`.

Blast-radius (С‚РѕР»СЊРєРѕ С‡РёС‚Р°С‚СЊ, РЅРµ РјРµРЅСЏС‚СЊ): `app/services/subscriptions/offer_presentation_service.rb` (РїРµСЂРµС…РѕРґ РїРѕРґ `with_lock`), `app/jobs/shop/send_push_notification_job.rb` (РґРѕСЃС‚Р°РІРєР° + `push_sent`).

## Р РµС€РµРЅРёСЏ SPEC (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ)

1. Р РµР°Р»РёР·Р°С†РёСЋ #96 РЅРµ РїРµСЂРµРїРёСЃС‹РІР°РµРј вЂ” TASK_97 Р·Р°РєСЂС‹РІР°РµС‚СЃСЏ РµР№; РЅРѕРІС‹Р№ РєРѕРґ С‚РѕР»СЊРєРѕ РµСЃР»Рё concurrent-С‚РµСЃС‚ СѓРїР°Р».
2. Idempotency Р±РµР· РјРёРіСЂР°С†РёРё (partial unique index РЅР° `payload->>'offer_transition_key'` вЂ” С‚РѕР»СЊРєРѕ РµСЃР»Рё advisory lock РЅРµ С…РІР°С‚РёС‚; С‚РѕРіРґР° Migration Gate).
3. РўРµРєСЃС‚ push вЂ” РєР°Рє РІ #96 (В«РљРѕС„Рµ РїРѕ РїРѕРґРїРёСЃРєРµВ» / В«РћС„РѕСЂРјРёС‚Рµ РїРѕРґРїРёСЃРєСѓ Рё СЌРєРѕРЅРѕРјСЊС‚Рµ РЅР° РєР°Р¶РґРѕРј Р·Р°РєР°Р·РµВ»), РїРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ Сѓ Р·Р°РєР°Р·С‡РёРєР° вЂ” РѕР±С‰РёР№ С…РІРѕСЃС‚ #96.

## РќРµ Р»РѕРјР°С‚СЊ

- push Рѕ СЃС‚Р°С‚СѓСЃРµ Р·Р°РєР°Р·Р° + Cascade ready (`OrderStatusPushNotifier`, `ReadyPushJob`, `OrderReadyCascadeJob`)
- FCM registration flow / `push_enabled_at` (`push_register`)
- `OfferPresentationService` РїСЂР°РІРёР»Р° TASK_95 (dismiss / РїРѕРІС‚РѕСЂ РїРѕСЃР»Рµ 3 Р·Р°РєР°Р·РѕРІ / purchased / РїСЂРѕРјРѕ 11в‚Ѕ) Рё `profile` С„Р»Р°РіРё
- `SendPushNotificationJob` РґР»СЏ РЅРµ-offer push (Р±РµР· `marketing_events`)

## РџСЂРѕРІРµСЂРєР°

```text
ruby bin/rails test test/services/subscriptions/offer_push_concurrency_test.rb test/services/subscriptions/offer_push_notifier_test.rb
node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/milestones/veha_2/artifacts/subscription_offer_push/GATES.md
```

---

# todo вЂ” TASK_96: РћС„С„РµСЂ РїРѕРґРїРёСЃРєРё вЂ” frontend, push Рё Р°РЅР°Р»РёС‚РёРєР°

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **ID** | TASK_96 В· CBR #96 |
| **Р”РѕРє** | [TASK-96-РћС„С„РµСЂ-РїРѕРґРїРёСЃРєРё-frontend-push-Рё-Р°РЅР°Р»РёС‚РёРєР°.md](../milestones/veha_2/requirements/customer_tasks/TASK-96-РћС„С„РµСЂ-РїРѕРґРїРёСЃРєРё-frontend-push-Рё-Р°РЅР°Р»РёС‚РёРєР°.md) |
| **Google** | https://docs.google.com/document/d/1kbB0iDYgFoioln0I2xUXeMBXWaKo_cKqDEfproHJN1M/edit?usp=drivesdk |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/subscription_offer_frontend_push_analytics/GATES.md) |
| **РўРёРї** | РЅРѕРІР°СЏ С„РёС‡Р° РїРѕРІРµСЂС… TASK_95 В· РїРѕР»РЅС‹Р№ SBR В· **РІРµСЃСЊ scope TASK_96 (Subtask 1вЂ“36)** |
| **РЎС‚Р°С‚СѓСЃ** | RED В· РІР»Р°РґРµР»РµС† (2026-09-29 `/sbr`): РґРµР»Р°РµРј РІСЃС‘, РєСЂРѕРјРµ С†РµР»Рё РїРµСЂРµС…РѕРґР° вЂ” `OFFER_TARGET_PATH = "/profile"` РґРѕ billing UI; G7/Subtask 35 РѕС‚РєСЂС‹С‚С‹ |

## SBR

- [x] PHASE 0 intake
- [x] /unlazy ledger (G5вЂ“G6 baseline PASS)
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED вЂ” G1вЂ“G4 (Ruby 38 runs В· 13 F В· 25 E; JS вЂ” РјРѕРґСѓР»СЊ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚)
- [x] PHASE 2 GREEN вЂ” G1вЂ“G6 reverify PASS В· СЃРѕСЃРµРґРё 80/0 В· vite build OK
- [ ] /regress
- [ ] PHASE 3 REVIEW вЂ” push/CI В· deploy РїРѕ Р°РїСЂСѓРІСѓ В· G7 Fly

## Р‘Р»РѕРєРµСЂ

- **Р­РєСЂР°РЅ РѕС„РѕСЂРјР»РµРЅРёСЏ РїРѕРґРїРёСЃРєРё РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚ РІРѕ frontend.** Р’ `App.svelte` РЅРµС‚ `#/subscriptionвЂ¦` / В«РњРѕСЏ РїРѕРґРїРёСЃРєР°В»; РµСЃС‚СЊ С‚РѕР»СЊРєРѕ backend `POST /shop/api/subscriptions` (РїСЂРёРЅРёРјР°РµС‚ `utm_campaign`, `utm_content`, `offer_channel`). Billing UI вЂ” Р·РѕРЅР° Р—Р°РґР°С‡Рё-3 (Point A offer OFF В«РґРѕ billing UIВ»), СЃРІРѕРµР№ Р·Р°РґР°С‡Рё/CBR РІ СЂРµРїРѕ РЅРµС‚.
- Р—Р°РІРёСЃСЏС‚ РѕС‚ РЅРµРіРѕ: Subtask 5, 26вЂ“27 (С†РµР»СЊ РїРµСЂРµС…РѕРґР°), 30 (С†РµР»СЊ push deep link), 11 (В«РњРѕСЏ РїРѕРґРїРёСЃРєР°В»), 35 (E2E В«РїРµСЂРµС…РѕРґ РІ РѕС„РѕСЂРјР»РµРЅРёРµВ»).
- Р РµС€РµРЅРёРµ РІР»Р°РґРµР»СЊС†Р° (SPEC 2026-09-29): **TASK_96 Р¶РґС‘С‚ billing UI**. РЎРЅСЏС‚РёРµ Р±Р»РѕРєРµСЂР° = РїРѕСЏРІРёР»СЃСЏ СЂРѕСѓС‚ СЌРєСЂР°РЅР° РѕС„РѕСЂРјР»РµРЅРёСЏ в†’ РІРїРёСЃР°С‚СЊ РїСѓС‚СЊ РІ `subscriptionOffer.js` Рё СЃС‚Р°СЂС‚РѕРІР°С‚СЊ `/sbr`.

## РџРµСЂРµСЃРµС‡РµРЅРёСЏ (РґРµСЂР¶РёРј РІ СѓРјРµ, РЅРµ РґРµР»Р°РµРј)

- TASK_97 (push-РѕС„С„РµСЂ) вЉ‚ Subtask 14вЂ“21; TASK_98 (РІРѕСЂРѕРЅРєР° + UTM) вЉ‚ Subtask 22вЂ“33. TASK_96 РґРµР»Р°РµРј С†РµР»РёРєРѕРј; СЂРµС€РµРЅРёСЏ СЃРѕРІРјРµСЃС‚РёРјС‹ СЃ РёС… С‚РµРєСЃС‚РѕРј (idempotency РЅР° РїРµСЂРµС…РѕРґ РІ `shown`, Р° РЅРµ РЅР° Р·Р°РєР°Р·/РґР°С‚Сѓ; Р°С‚СЂРёР±СѓС†РёСЏ РІ `subscriptions.utm_*` РёР· РїРѕСЃР»РµРґРЅРµРіРѕ `offer_opened`; РѕС€РёР±РєРё Р°РЅР°Р»РёС‚РёРєРё/FCM РЅРµ РІР»РёСЏСЋС‚ РЅР° РѕСЃРЅРѕРІРЅРѕР№ flow). РЎСѓРґСЊР±Р° TASK_97/98 вЂ” СЂРµС€Р°РµС‚ РІР»Р°РґРµР»РµС†.

## Р РµС€РµРЅРёСЏ SPEC (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ вЂ” РїРѕРґС‚РІРµСЂРґРёС‚СЊ РґРѕ RED)

1. **РўРѕС‡РєР° РїРѕРєР°Р·Р° Р±Р°РЅРЅРµСЂР°** вЂ” `OrderStatus.svelte` РїРѕСЃР»Рµ Р±Р»РѕРєР° РїСЂРѕРіСЂРµСЃСЃР° (РїРѕСЃР»Рµ L340, РїРµСЂРµРґ В«РЎРѕСЃС‚Р°РІ Р·Р°РєР°Р·Р°В»), С‚РѕР»СЊРєРѕ РїСЂРё `order.status === "ready"` + `should_show_banner` + РїСЂРѕС„РёР»СЊ 200. Layout РІРёРґР¶РµС‚Р° СЃС‚Р°С‚СѓСЃР° РЅРµ РјРµРЅСЏРµС‚СЃСЏ.
2. **`mark_shown` СЃ С„СЂРѕРЅС‚Р°** вЂ” СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ `POST /shop/api/subscription_offer/shown` (TASK_95), РѕРґРёРЅ СЂР°Р· Р·Р° РјРѕРЅС‚РёСЂРѕРІР°РЅРёРµ СЌРєСЂР°РЅР° (С„Р»Р°Рі РІ РјРѕРґСѓР»Рµ, РїРѕ `order.id`).
3. **Р¤Р»Р°РіРё** вЂ” РёР· `GET /shop/api/profile` (`should_show_banner`, `has_unread_offer_in_lk`); РєР°СЂС‚РѕС‡РєР° Р›Рљ РїРѕРєР°Р·С‹РІР°РµС‚СЃСЏ РїСЂРё `eligible_for_subscription_offer && !purchased`; purchased = РµСЃС‚СЊ Р°РєС‚РёРІРЅР°СЏ РїРѕРґРїРёСЃРєР° (`GET /shop/api/subscriptions/current` 200) в†’ РєР°СЂС‚РѕС‡РєРё РЅРµС‚.
4. **UTM** вЂ” `utm_campaign=subscription_offer`, `utm_content=<channel>_v1` (`banner_v1` / `lk_v1` / `push_v1`), `offer_channel в€€ Subscription::OFFER_CHANNELS` (`banner lk push`). РљРѕРЅСЃС‚Р°РЅС‚Р° РІРµСЂСЃРёРё РєСЂРµР°С‚РёРІР° вЂ” РѕРґРЅР°, РІ `subscriptionOffer.js`.
5. **`offer_opened` / `push_opened`** вЂ” РЅРѕРІС‹Р№ `POST /shop/api/subscription_offer/opened` (`channel`, `utm_*`); frontend С€Р»С‘С‚ С‡РµСЂРµР· `navigator.sendBeacon`, fallback `fetch(..., { keepalive: true })` Р±РµР· `await` РїРµСЂРµРґ РЅР°РІРёРіР°С†РёРµР№.
6. **Idempotency push** вЂ” `OfferPresentationService#mark_shown` РІРѕР·РІСЂР°С‰Р°РµС‚ `true` С‚РѕР»СЊРєРѕ РїСЂРё С„Р°РєС‚РёС‡РµСЃРєРѕРј РїРµСЂРµС…РѕРґРµ (РїРѕРґ row-lock `with_state`); РЅР° РїРµСЂРµС…РѕРґ СЃРѕР·РґР°С‘С‚СЃСЏ СЂРѕРІРЅРѕ РѕРґРЅРѕ `banner_shown`, РµРіРѕ `id` = idempotency-РєР»СЋС‡ push (`push_notifications.payload.offer_event_id`, РїСЂРѕРІРµСЂРєР° РїРµСЂРµРґ СЃРѕР·РґР°РЅРёРµРј). РџРѕРІС‚РѕСЂРЅС‹Р№ `shown` РїРѕСЃР»Рµ 3 Р·Р°РєР°Р·РѕРІ в†’ РЅРѕРІРѕРµ СЃРѕР±С‹С‚РёРµ в†’ РЅРѕРІС‹Р№ push. РљРѕР»РѕРЅРєРё РІ `subscription_offer_states` РЅРµ РґРѕР±Р°РІР»СЏРµРј.
7. **`OfferPushNotifier`** вЂ” РєР°Рє `Shop::OrderStatusPushNotifier`: `PushNotification` (`notification_type: "subscription_offer"`) + `Shop::SendPushNotificationJob` в†’ `FcmClient`; С‚РѕР»СЊРєРѕ РїСЂРё `push_enabled_at` Рё `push_token`; `rescue StandardError` в†’ log. `push_sent` РїРёС€РµС‚ job РїРѕСЃР»Рµ СѓСЃРїРµС€РЅРѕР№ РґРѕСЃС‚Р°РІРєРё. Р’С‹Р·РѕРІ вЂ” `after_commit`-Р±РµР·РѕРїР°СЃРЅРѕ (enqueue РїРѕСЃР»Рµ С‚СЂР°РЅР·Р°РєС†РёРё СЃРѕСЃС‚РѕСЏРЅРёСЏ).
8. **Deep link push** вЂ” `data.offer_url` РІ payload; РІ `firebase_sw/show.js.erb` РІРµС‚РєР° `notificationclick`: `offer_url` в†’ `openClient(offer_url)` **РґРѕ** `if (!orderId) return` (order-РІРµС‚РєРё РЅРµ С‚СЂРѕРіР°РµРј).
9. **РђС‚СЂРёР±СѓС†РёСЏ РїРѕРєСѓРїРєРё** вЂ” РІ `Subscriptions::PaymentFulfillment` (РµРґРёРЅР°СЏ С‚РѕС‡РєР° Р°РєС‚РёРІР°С†РёРё, РєР°Рє `mark_purchased` РІ TASK_95): РµСЃР»Рё UTM РЅРµ РїСЂРёС€Р»Рё РІ РїРѕРєСѓРїРєРµ вЂ” Р±РµСЂС‘Рј РёР· РїРѕСЃР»РµРґРЅРµРіРѕ `offer_opened` РіРѕСЃС‚СЏ; `subscription_purchased` РїРёС€РµС‚СЃСЏ `rescue`-Р±РµР·РѕРїР°СЃРЅРѕ, РїРѕРєСѓРїРєР° РЅРµ РѕС‚РєР°С‚С‹РІР°РµС‚СЃСЏ. `PurchaseService` РЅРµ С‚СЂРѕРіР°РµРј.
10. **`marketing_events`** вЂ” Р±РµР· RLS (РєР°Рє `subscriptions` / `subscription_offer_states`, customer-scoped), `point_id` = tenant С‚РѕС‡РєРё; Р·Р°РїРёСЃСЊ С‚РѕР»СЊРєРѕ С‡РµСЂРµР· `Subscriptions::MarketingEventLogger` (never raises). РРЅРґРµРєСЃС‹: `(point_id, occurred_at)`, `(customer_id, event_type, occurred_at)`.
11. **РћС‚С‡С‘С‚ РІРѕСЂРѕРЅРєРё** вЂ” `Subscriptions::OfferFunnelReport` (group by `event_type, channel` Р·Р° `from..to`, С„РёР»СЊС‚СЂ `point_id = Current.tenant_id`) + JSON `GET /manager/subscription_offer_funnel` (manager namespace, Р±РµР· UI).
12. **РЁР°Р±Р»РѕРЅ push** вЂ” title В«РљРѕС„Рµ РїРѕ РїРѕРґРїРёСЃРєРµВ», body В«РћС„РѕСЂРјРёС‚Рµ РїРѕРґРїРёСЃРєСѓ Рё СЌРєРѕРЅРѕРјСЊС‚Рµ РЅР° РєР°Р¶РґРѕРј Р·Р°РєР°Р·РµВ» (Р·Р°РіР»СѓС€РєР° вЂ” С‚РµРєСЃС‚ РїРѕРґС‚РІРµСЂРґРёС‚СЊ Сѓ Р·Р°РєР°Р·С‡РёРєР°).
13. **В§5 РўР—** вЂ” `npx tsc --noEmit` РЅРµ РїСЂРёРјРµРЅРёРј (Svelte/JS) в†’ `node --test`; E2E-СЂР°РЅРЅРµСЂР° РІ СЂРµРїРѕ РЅРµС‚ в†’ Subtask 35 = Fly MCP browser РЅР° Point A (G7).

## Р¤Р°Р№Р»С‹ (РѕР¶РёРґР°РµРјРѕ)

РџРѕР»РЅС‹Р№ scope (36 Subtask) вЂ” Р±РѕР»СЊС€Рµ 7 РїСѓС‚РµР№; СЃРіСЂСѓРїРїРёСЂРѕРІР°РЅРѕ РїРѕ Р±Р»РѕРєР°Рј.

**Frontend (G1)**
1. `app/frontend/lib/subscriptionOffer.js` вЂ” РЅРѕРІС‹Р№ С‡РёСЃС‚С‹Р№ РјРѕРґСѓР»СЊ: `bannerVisible({ order, profile })`, `lkCardView(profile, subscription)`, `buildOfferLink(channel)`, `markShownOnce/dismiss/markViewed`, `trackOfferOpened` (sendBeacon). Р’РµСЃСЊ С‚РµСЃС‚РёСЂСѓРµРјС‹Р№ РєРѕРґ Р·РґРµСЃСЊ.
2. `app/frontend/components/SubscriptionOfferBanner.svelte` вЂ” РЅРѕРІС‹Р№: Р±Р°РЅРЅРµСЂ, СЃРІР°Р№Рї/РєСЂРµСЃС‚РёРє в†’ Р»РѕРєР°Р»СЊРЅРѕРµ СЃРєСЂС‹С‚РёРµ + dismiss, РєР»РёРє в†’ `trackOfferOpened` + РїРµСЂРµС…РѕРґ.
3. `app/frontend/components/SubscriptionOfferCard.svelte` вЂ” РЅРѕРІС‹Р№: РєР°СЂС‚РѕС‡РєР° Р›Рљ + unread-РёРЅРґРёРєР°С‚РѕСЂ, СЂР°СЃРєСЂС‹С‚РёРµ в†’ viewed (РѕРїС‚РёРјРёСЃС‚РёС‡РЅРѕ), РєР»РёРє в†’ РїРµСЂРµС…РѕРґ.
4. `app/frontend/routes/OrderStatus.svelte` вЂ” С‚РѕР»СЊРєРѕ С‚РѕС‡РєР° РјРѕРЅС‚РёСЂРѕРІР°РЅРёСЏ Р±Р°РЅРЅРµСЂР° РїРѕСЃР»Рµ L340.
5. `app/frontend/routes/Profile.svelte` вЂ” С‚РѕР»СЊРєРѕ РїРѕРґРєР»СЋС‡РµРЅРёРµ РєР°СЂС‚РѕС‡РєРё РїРѕСЃР»Рµ `<PlgBlockSection />`.

**Push (G2)**
6. `app/services/subscriptions/offer_push_notifier.rb` вЂ” РЅРѕРІС‹Р№.
7. `app/services/subscriptions/offer_presentation_service.rb` вЂ” `mark_shown` в†’ bool + side-effect `banner_shown` + notifier (Р±РµР· СЃРјРµРЅС‹ РїСЂР°РІРёР»).
8. `app/views/shop/firebase_sw/show.js.erb` вЂ” РІРµС‚РєР° `offer_url` РІ `notificationclick`.
9. `app/jobs/shop/send_push_notification_job.rb` вЂ” РїРѕСЃР»Рµ СѓСЃРїРµС€РЅРѕР№ РґРѕСЃС‚Р°РІРєРё `subscription_offer` в†’ `push_sent`.

**РђРЅР°Р»РёС‚РёРєР° (G3вЂ“G4)**
10. `db/migrate/2026XXXX_create_marketing_events.rb` + `app/models/marketing_event.rb` вЂ” `enum :event_type` (7 Р·РЅР°С‡РµРЅРёР№, string).
11. `app/services/subscriptions/marketing_event_logger.rb` вЂ” РµРґРёРЅР°СЏ Р±РµР·РѕРїР°СЃРЅР°СЏ Р·Р°РїРёСЃСЊ.
12. `app/controllers/shop/api/subscription_offers_controller.rb` + `config/routes.rb` вЂ” СЃРѕР±С‹С‚РёСЏ РІ dismiss/viewed + `POST subscription_offer/opened`.
13. `app/services/subscriptions/payment_fulfillment.rb` вЂ” `subscription_purchased` + Р°С‚СЂРёР±СѓС†РёСЏ РёР· РїРѕСЃР»РµРґРЅРµРіРѕ `offer_opened`.
14. `app/services/subscriptions/offer_funnel_report.rb` + `app/controllers/manager/subscription_offer_funnel_controller.rb` вЂ” РѕС‚С‡С‘С‚.

**РўРµСЃС‚С‹ (G1вЂ“G4)**
- `test/javascript/subscription_offer_banner_test.mjs` В· `test/javascript/subscription_offer_card_test.mjs`
- `test/services/subscriptions/offer_push_notifier_test.rb`
- `test/models/marketing_event_test.rb` В· `test/integration/shop/api/subscription_offer_marketing_events_test.rb`
- `test/integration/shop/subscription_offer_funnel_test.rb`

**Docs:** `docs/integrations/shop-api.md` (`opened`) В· `docs/integrations/pwa-realtime.md` (offer push) В· `docs/operations/session/COMPONENT_MAP.md` (4 РЅРѕРІС‹С… РєРѕРјРїРѕРЅРµРЅС‚Р°).

Blast-radius (С‚РѕР»СЊРєРѕ С‡С‚РµРЅРёРµ/СЂРµРіСЂРµСЃСЃРёСЏ):
- `app/services/shop/order_status_push_notifier.rb` + `app/services/shop/fcm_client.rb` вЂ” РѕР±СЂР°Р·РµС† Рё РѕР±С‰РёР№ С‚СЂР°РЅСЃРїРѕСЂС‚; РЅРµ РјРµРЅСЏС‚СЊ.
- `app/frontend/lib/orderStatusCtaMachine.js` / `subscriptionOfferCta.js` вЂ” СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ CTA РїРѕРґРїРёСЃРєРё РЅР° СЃС‚Р°С‚СѓСЃРµ; РЅРµ РјРµРЅСЏС‚СЊ (Р±Р°РЅРЅРµСЂ вЂ” РѕС‚РґРµР»СЊРЅС‹Р№ РєР°РЅР°Р»).
- `app/services/subscriptions/purchase_service.rb` вЂ” РІС‹Р·С‹РІР°РµС‚ `PaymentFulfillment`; СЂРµРіСЂРµСЃСЃРёСЏ G5.

## РќРµ Р»РѕРјР°С‚СЊ

- РЎС‚Р°С‚СѓСЃ Р·Р°РєР°Р·Р°: layout `OrderStatus.svelte`, `orderStatusCtaMachine.js`, CTA РЅР° `ready`, С€С‚РѕСЂРєР° `ActiveOrdersAccordion` / `OrderStatusSheet`, Cable-СЃС‚Р°С‚СѓСЃС‹.
- Push Рѕ СЃС‚Р°С‚СѓСЃРµ Р·Р°РєР°Р·Р°: `OrderStatusPushNotifier`, Cascade ready, FCM registration + `push_enabled_at`, `notificationclick` РґР»СЏ `order_id` (chat/tips/cancel).
- РћРїР»Р°С‚Р° РїРѕРґРїРёСЃРєРё: `PurchaseService` / `PaymentFulfillment` РёРґРµРјРїРѕС‚РµРЅС‚РЅРѕСЃС‚СЊ (РїРѕРІС‚РѕСЂРЅС‹Р№ webhook в†’ С‚РѕС‚ Р¶Рµ `Subscription`, Р±РµР· РІС‚РѕСЂРѕРіРѕ `subscription_purchased`), `Payments::TbankAdapter`.
- Р›Рљ: РёСЃС‚РѕСЂРёСЏ + В«РџРѕРІС‚РѕСЂРёС‚СЊВ» (TASK_94), PLG-СЃР»РѕС‚С‹; СЃРѕСЃС‚РѕСЏРЅРёРµ РѕС„С„РµСЂР° TASK_95 (`shown/dismiss/viewed` API, С„Р»Р°РіРё РїСЂРѕС„РёР»СЏ).

## РџСЂРѕРІРµСЂРєР°

```bash
node --test test/javascript/subscription_offer_banner_test.mjs test/javascript/subscription_offer_card_test.mjs test/javascript/order_status_cta_machine_test.mjs test/javascript/order_status_sheet_test.mjs test/javascript/lk_history_repeat_one_click_test.mjs
bin/rails test test/services/subscriptions/offer_push_notifier_test.rb test/models/marketing_event_test.rb test/integration/shop/api/subscription_offer_marketing_events_test.rb test/integration/shop/subscription_offer_funnel_test.rb test/services/subscriptions/ test/integration/shop/api/subscription_offer_state_api_test.rb test/services/shop/order_status_push_notifier_test.rb test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb
```

Fly MCP Point A (G7, РїРѕСЃР»Рµ deploy): СЃС‚Р°С‚СѓСЃ `ready` в†’ Р±Р°РЅРЅРµСЂ В· dismiss В· РєР°СЂС‚РѕС‡РєР° Р›Рљ + unread РіР°СЃРЅРµС‚ В· РїРµСЂРµС…РѕРґ РІ РѕС„РѕСЂРјР»РµРЅРёРµ СЃ UTM В· РІРёС‚СЂРёРЅР°/РєРѕСЂР·РёРЅР°/СЃС‚Р°С‚СѓСЃ PASS.

## DoD

- [x] Subtask 1вЂ“13: Р±Р°РЅРЅРµСЂ + РєР°СЂС‚РѕС‡РєР° Р›Рљ + error-path (G1) вЂ” С†РµР»СЊ РїРµСЂРµС…РѕРґР° `#/profile` РґРѕ billing UI
- [x] Subtask 14вЂ“21: `OfferPushNotifier` + idempotency (G2)
- [x] Subtask 22вЂ“30: `marketing_events` + СЃРѕР±С‹С‚РёСЏ (G3)
- [x] Subtask 31вЂ“33: Р°С‚СЂРёР±СѓС†РёСЏ РїРѕРєСѓРїРєРё + РѕС‚С‡С‘С‚ (G4)
- [x] Subtask 34, 36: unit + СЂРµРіСЂРµСЃСЃРёСЏ (G1, G5вЂ“G6)
- [ ] Subtask 35: E2E РЅР° Fly (G7) вЂ” РїРѕСЃР»Рµ deploy; В«РїРµСЂРµС…РѕРґ РІ РѕС„РѕСЂРјР»РµРЅРёРµВ» вЂ” РїРѕСЃР»Рµ billing UI
- [x] Docs integrations + COMPONENT_MAP

---

# todo вЂ” TASK_95: РЎРѕСЃС‚РѕСЏРЅРёРµ РѕС„С„РµСЂР° РїРѕРґРїРёСЃРєРё РЅР° РіРѕСЃС‚СЏ

| РџРѕР»Рµ | Р—РЅР°С‡РµРЅРёРµ |
|------|----------|
| **ID** | TASK_95 В· CBR #95 |
| **Р”РѕРє** | [TASK-95-РЎРѕСЃС‚РѕСЏРЅРёРµ-РѕС„С„РµСЂР°-РїРѕРґРїРёСЃРєРё-РЅР°-РіРѕСЃС‚СЏ.md](../milestones/veha_2/requirements/customer_tasks/TASK-95-РЎРѕСЃС‚РѕСЏРЅРёРµ-РѕС„С„РµСЂР°-РїРѕРґРїРёСЃРєРё-РЅР°-РіРѕСЃС‚СЏ.md) |
| **Google** | https://docs.google.com/document/d/18f25SUyeTWwixkcDX9XvTedfkd8GzSO6lfjoCTNWzPA/edit?usp=drivesdk |
| **Ledger** | [GATES.md](../milestones/veha_2/artifacts/subscription_offer_guest_state/GATES.md) |
| **РўРёРї** | РЅРѕРІР°СЏ С„РёС‡Р° В· РїРѕР»РЅС‹Р№ SBR |
| **РЎС‚Р°С‚СѓСЃ** | SPEC `[x]` В· Р¶РґС‘С‚ `/sbr` (RED) |

## SBR

- [x] PHASE 0 intake
- [x] /unlazy ledger (G5вЂ“G6 baseline PASS)
- [x] PHASE 1 SPEC
- [x] PHASE 2 RED вЂ” С‚РµСЃС‚С‹ G1вЂ“G4 (`a88558cb`: 32 runs В· 4 F В· 28 E)
- [x] PHASE 2 GREEN вЂ” РєРѕРґ (32/0 В· G1вЂ“G6 reverify PASS В· subscriptions 37/0)
- [x] /regress вЂ” 190/0 (TASK_95 32 В· РїРѕРґРїРёСЃРєРё/РїСЂРѕРјРѕ/РїСЂРѕС„РёР»СЊ 92 В· T-Bank callback 50 В· RLS 16)
- [x] PHASE 3 REVIEW вЂ” bugbot (2 Р±Р°РіР° в†’ fix `bb64f742`) + security С‡РёСЃС‚Рѕ В· Local 194/0 В· Entire В· push/CI
- [ ] deploy РїРѕ Р°РїСЂСѓРІСѓ В· G7 Fly MCP Point A

## Р РµС€РµРЅРёСЏ SPEC (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ вЂ” РїРѕРґС‚РІРµСЂРґРёС‚СЊ РґРѕ RED)

РћС‚РІРµС‚ РЅР° РІРѕРїСЂРѕСЃС‹ РЅРµ РїРѕР»СѓС‡РµРЅ в†’ РІР·СЏС‚С‹ СЂРµРєРѕРјРµРЅРґРѕРІР°РЅРЅС‹Рµ РІР°СЂРёР°РЅС‚С‹:

1. **`profile/config` РёР· РўР— = `GET /shop/api/profile`.** `/shop/api/config` вЂ” tenant-level Р±РµР· РіРѕСЃС‚СЏ; С„Р»Р°РіРё РіРѕСЃС‚СЏ РєР»Р°РґС‘Рј СЂСЏРґРѕРј СЃ `eligible_for_subscription_offer`.
2. **Р”РѕР±Р°РІРёС‚СЊ `POST /shop/api/subscription_offer/shown`.** Р’ РўР— РЅРµС‚ С‚РѕС‡РєРё РґР»СЏ `mark_shown` (Subtask 8 В«Р±Р°РЅРЅРµСЂ РѕС‚СЂРµРЅРґРµСЂРµРЅ frontendВ»), Р±РµР· РЅРµС‘ `dismiss` РЅРµРґРѕСЃС‚РёР¶РёРј. РџСЂРѕР±РµР» РўР— в†’ СЃРѕРѕР±С‰РёС‚СЊ Р·Р°РєР°Р·С‡РёРєСѓ.
3. **`mark_purchased` вЂ” РІ `Subscriptions::PaymentFulfillment`**, Р° РЅРµ РІ `PurchaseService`: fulfillment вЂ” РµРґРёРЅР°СЏ С‚РѕС‡РєР° Р°РєС‚РёРІР°С†РёРё (sync-charge Рё webhook redirect/РЎР‘Рџ). `PurchaseService` РЅРµ С‚СЂРѕРіР°РµРј РІРѕРІСЃРµ.
4. **Р—Р°РІРµСЂС€С‘РЅРЅС‹Рµ Р·Р°РєР°Р·С‹ вЂ” РЅР° С‚РµРєСѓС‰РµР№ С‚РѕС‡РєРµ** (`SubscriptionOfferEligibility#completed_orders_count`, РїРѕРґ RLS). Р‘РµР· РѕР±С…РѕРґР° RLS.

РџСЂРѕС‡РµРµ:
- `subscription_offer_states` вЂ” **Р±РµР· RLS**, РєР°Рє `subscriptions` / `mobile_customers` (РіР»РѕР±Р°Р»СЊРЅС‹Рµ, customer-scoped): В«purchased РЅР° Р»СЋР±РѕР№ С‚РѕС‡РєРµ СЃРµС‚РёВ» СЂР°Р±РѕС‚Р°РµС‚ Р±РµР· РѕР±С…РѕРґР°. Р”РѕСЃС‚СѓРї вЂ” С‚РѕР»СЊРєРѕ РїРѕ `customer_id` РёР· СЃРµСЂРІРµСЂРЅРѕР№ СЃРµСЃСЃРёРё.
- РџСЂРѕРјРѕ 11в‚Ѕ: `SubscriptionOfferEligibility.check` СѓР¶Рµ РІРѕР·РІСЂР°С‰Р°РµС‚ false РїСЂРё `GrowthPromo.available?`; СЃРµСЂРІРёСЃ РІСЃС‘ СЂР°РІРЅРѕ СЏРІРЅРѕ РїСЂРѕРІРµСЂСЏРµС‚ `GrowthPromo.available?` РїРµСЂРІС‹Рј (Subtask 5, СЏРІРЅС‹Р№ РїСЂРёРѕСЂРёС‚РµС‚ РІ С‚РµСЃС‚Р°С…).
- `should_show_push` = `should_show_banner` (СЃРµСЂРІРёСЃ РІРѕР·РІСЂР°С‰Р°РµС‚, РІ API РЅРµ РѕС‚РґР°С‘Рј вЂ” push frontend С‡СѓР¶Р°СЏ Р·Р°РґР°С‡Р°).
- В«Р“РѕСЃС‚СЊ РґРѕСЃС‚РёРі `ready`В» вЂ” backend-С…СѓРєР° РІ СЃС‚Р°С‚СѓСЃ РЅРµ РґРѕР±Р°РІР»СЏРµРј: frontend РЅР° `ready` Р·Р°РїСЂР°С€РёРІР°РµС‚ РїСЂРѕС„РёР»СЊ, С„Р»Р°Рі СѓР¶Рµ РІС‹С‡РёСЃР»РµРЅ (`orderStatusCtaMachine.js` РЅРµ С‚СЂРѕРіР°РµРј).
- В§5 РўР— `npx tsc --noEmit` вЂ” РЅРµ РїСЂРёРјРµРЅРёРј (Rails backend, frontend РЅРµ РјРµРЅСЏРµС‚СЃСЏ) в†’ `bin/rails test`.

## Р¤Р°Р№Р»С‹ (РѕР¶РёРґР°РµРјРѕ)

1. `db/migrate/20260929120000_create_subscription_offer_states.rb` вЂ” С‚Р°Р±Р»РёС†Р°: `customer_id` (uuid, unique index, FK `mobile_customers`), `status` (string, default `not_shown`), `first_shown_at`, `last_dismissed_at`, `completed_orders_count_at_dismissal` (int), `unread_since`, timestamps. Subtask 1.
2. `app/models/subscription_offer_state.rb` вЂ” `enum :status, { not_shown:, shown:, dismissed:, viewed_in_lk:, purchased: }` (string), `for_customer!` = find-or-create СЃ rescue `RecordNotUnique`. Subtask 2вЂ“3.
3. `app/services/subscriptions/offer_presentation_service.rb` вЂ” `call` в†’ `{ should_show_banner:, should_show_push:, has_unread_offer_in_lk: }`; `mark_shown` / `mark_dismissed` / `mark_viewed_in_lk` / `mark_purchased` (РёРґРµРјРїРѕС‚РµРЅС‚РЅС‹Рµ, СЃ Р±Р»РѕРєРёСЂРѕРІРєРѕР№ СЃС‚СЂРѕРєРё). Subtask 4вЂ“17.
4. `app/controllers/shop/api/subscription_offers_controller.rb` вЂ” `shown` / `dismiss` / `viewed`; `require_customer!` РєР°Рє РІ `SubscriptionsController` (401 В«РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏВ»); С‚РѕР»СЊРєРѕ РІС‹Р·РѕРІ СЃРµСЂРІРёСЃР°. Subtask 19вЂ“22.
5. `config/routes.rb` вЂ” 3 POST РІ `shop/api` СЂСЏРґРѕРј СЃ `subscriptions/*`.
6. `app/controllers/shop/api/profile_controller.rb` вЂ” +`should_show_banner`, `has_unread_offer_in_lk` РІ `profile_json` С‡РµСЂРµР· СЃРµСЂРІРёСЃ. Subtask 18.
7. `app/services/subscriptions/payment_fulfillment.rb` вЂ” РїРѕСЃР»Рµ `subscription.save!` в†’ `mark_purchased` (РІ С‚РѕР№ Р¶Рµ С‚СЂР°РЅР·Р°РєС†РёРё РІС‹Р·С‹РІР°СЋС‰РµРіРѕ). Subtask 16.

РўРµСЃС‚С‹ (G1вЂ“G4) Рё docs:
- `test/models/subscription_offer_state_test.rb` В· `test/services/subscriptions/offer_presentation_service_test.rb` В· `test/integration/shop/api/subscription_offer_state_api_test.rb` В· `test/integration/shop/subscription_offer_lifecycle_test.rb`
- `docs/integrations/shop-api.md` В· `docs/integrations/pwa-realtime.md` В· `docs/operations/session/COMPONENT_MAP.md` (Subtask 26вЂ“28)

Blast-radius (СЃРѕСЃРµРґРё, С‚РѕР»СЊРєРѕ С‡С‚РµРЅРёРµ/СЂРµРіСЂРµСЃСЃРёСЏ):
- `app/services/shop/subscription_offer_eligibility.rb` вЂ” РІС…РѕРґ СЃРµСЂРІРёСЃР°; Р·Р°РїСЂРµС‰РµРЅРѕ РјРµРЅСЏС‚СЊ.
- `app/services/payments/growth_promo.rb` вЂ” `available?` С‚РѕР»СЊРєРѕ С‡РёС‚Р°РµРј.
- `app/services/subscriptions/purchase_service.rb` вЂ” РІС‹Р·С‹РІР°РµС‚ `PaymentFulfillment` РІ sync-charge; СЂРµРіСЂРµСЃСЃРёСЏ G6.

## РќРµ Р»РѕРјР°С‚СЊ

- РћРїР»Р°С‚Р° РїРѕРґРїРёСЃРєРё: `PurchaseService` / `PaymentFulfillment` РёРґРµРјРїРѕС‚РµРЅС‚РЅРѕСЃС‚СЊ (РїРѕРІС‚РѕСЂРЅС‹Р№ webhook в†’ С‚РѕС‚ Р¶Рµ `Subscription`, Р±РµР· РІС‚РѕСЂРѕРіРѕ `mark_purchased`-СЌС„С„РµРєС‚Р°), `Payments::TbankAdapter`.
- РџСЂРѕРјРѕ 11в‚Ѕ / `GrowthPromo` / `SubscriptionOfferEligibility` / `subscription_offer_settings` вЂ” Р±РµР· РёР·РјРµРЅРµРЅРёР№ Р»РѕРіРёРєРё.
- РЎС‚Р°С‚СѓСЃ/С‚Р°Р±Р»Рѕ: `orderStatusCtaMachine.js` Рё CTA РЅР° `ready` вЂ” РЅРµ С‚СЂРѕРіР°РµРј; `GET /shop/api/config` вЂ” РєРѕРЅС‚СЂР°РєС‚ Р±РµР· РёР·РјРµРЅРµРЅРёР№.
- `GET /shop/api/profile` вЂ” СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёРµ РїРѕР»СЏ Рё `orders_count` / `eligible_for_subscription_offer` РЅРµ РјРµРЅСЏСЋС‚СЃСЏ; РґРѕР±Р°РІР»СЏСЋС‚СЃСЏ С‚РѕР»СЊРєРѕ 2 РїРѕР»СЏ.

## РџСЂРѕРІРµСЂРєР°

```bash
bin/rails test test/models/subscription_offer_state_test.rb test/services/subscriptions/offer_presentation_service_test.rb test/integration/shop/api/subscription_offer_state_api_test.rb test/integration/shop/subscription_offer_lifecycle_test.rb
bin/rails test test/services/shop/subscription_offer_eligibility_test.rb test/services/payments/growth_promo_test.rb test/integration/shop/api/profile_subscription_offer_test.rb test/services/subscriptions/ test/integration/shop/api/subscriptions_api_test.rb
```

Fly MCP Point A (G7, РїРѕСЃР»Рµ deploy): `GET /shop/api/profile` РѕС‚РґР°С‘С‚ 2 С„Р»Р°РіР° В· `POST subscription_offer/*` Р±РµР· СЃРµСЃСЃРёРё в†’ 401 В· РІРёС‚СЂРёРЅР°/РєРѕСЂР·РёРЅР° PASS.

## DoD

- [x] Subtask 1вЂ“3: С‚Р°Р±Р»РёС†Р° + РјРѕРґРµР»СЊ + РѕРґРЅР° Р·Р°РїРёСЃСЊ РЅР° РіРѕСЃС‚СЏ (G1)
- [x] Subtask 4вЂ“17: СЃРµСЂРІРёСЃ + РїРµСЂРµС…РѕРґС‹ + РїСЂРѕРјРѕ-РїСЂРёРѕСЂРёС‚РµС‚ + 3 Р·Р°РєР°Р·Р° + unread + purchased (G2)
- [x] Subtask 18вЂ“22: РїСЂРѕС„РёР»СЊ + shown/dismiss/viewed + 401 (G3)
- [x] Subtask 23вЂ“24: lifecycle + РїСЂРѕРјРѕ-РїСЂРёРѕСЂРёС‚РµС‚ e2e (G4)
- [x] Subtask 25: СЂРµРіСЂРµСЃСЃРёСЏ G5вЂ“G6
- [x] Subtask 26вЂ“28: docs integrations + COMPONENT_MAP
- [ ] G7 Fly MCP Point A (РїРѕСЃР»Рµ deploy РїРѕ Р°РїСЂСѓРІСѓ)
