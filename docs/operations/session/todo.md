# todo тАФ #69 PWA ╨Ы╨Ъ (╨╗╨╕╤З╨╜╤Л╨╣ ╨║╨░╨▒╨╕╨╜╨╡╤В)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| GREEN slice 1 #69 ╨Ы╨Ъ | hub/settings/about/receipt local PASS | REVIEW / Fly MCP ┬╖ subtask 30 UI polish |

**CBR:** #69  
**╨в╨Ч:** [`customer_tasks/╨Ф╨╛╤А╨░╨▒╨╛╤В╨║╨░ ╨╗╨╕╤З╨╜╨╛╨│╨╛ ╨║╨░╨▒╨╕╨╜╨╡╤В╨░ (╨Ы╨Ъ) ╨▓ PWA.md`](../milestones/veha_2/requirements/customer_tasks/╨Ф╨╛╤А╨░╨▒╨╛╤В╨║╨░%20╨╗╨╕╤З╨╜╨╛╨│╨╛%20╨║╨░╨▒╨╕╨╜╨╡╤В╨░%20(╨Ы╨Ъ)%20╨▓%20PWA.md)  
**╨Р╤А╤В╨╡╤Д╨░╨║╤В╤Л:** [`artifacts/pwa_personal_account_lk/`](../milestones/veha_2/artifacts/pwa_personal_account_lk/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**╨б╨╡╤А╨╕╤П:** ╨╖╨░╨┤╨░╤З╨░ 1 ╨╕╨╖ ╤В╤А╤С╤Е (TG-support, ╨Ы╨Ъ, email-after-pay). ╨Э╨╡ ╨╗╨╛╨╝╨░╤В╤М #64тАУ#68 WebView, CartSheet, checkout, payments.

## ╨ж╨╡╨╗╤М (1 ╨┐╤А╨╡╨┤╨╗╨╛╨╢╨╡╨╜╨╕╨╡)

╨Ч╨░╨▓╨╡╤А╤И╨╕╤В╤М ╤Б╤Ж╨╡╨╜╨░╤А╨╕╨╣ ╨Ы╨Ъ ╨▓ PWA ╨┐╨╛ ╨╝╨░╨║╨╡╤В╤Г: hub ╤Б ╨╕╤Б╤В╨╛╤А╨╕╨╡╨╣ ╨╖╨░╨║╨░╨╖╨╛╨▓, ╤Н╨║╤А╨░╨╜ ╨┤╨╡╤В╨░╨╗╨╡╨╣ (╨▒╨╡╨╖ ╨Ю╨д╨Ф), ╨╜╨░╤Б╤В╤А╨╛╨╣╨║╨╕/╨║╨╛╨╜╤В╨░╨║╤В╤Л, ┬л╨Ю ╨╜╨░╤Б┬╗, bottom sheet ┬л╨Э╨░╨┐╨╕╤Б╨░╤В╤М ╨╜╨░╨╝┬╗, logout тАФ ╨╜╨░ ╤Б╤Г╤Й╨╡╤Б╤В╨▓╤Г╤О╤Й╨╕╤Е shop API ╨▒╨╡╨╖ ╨╜╨╛╨▓╤Л╤Е ╨▓╨╜╨╡╤И╨╜╨╕╤Е ╨╕╨╜╤В╨╡╨│╤А╨░╤Ж╨╕╨╣.

## Acceptance (DoD) тАФ ╨║╨╗╤О╤З╨╡╨▓╨╛╨╡

1. `#/profile` тАФ hub ╨Ы╨Ъ: ╤И╨░╨┐╨║╨░ (╨░╨▓╨░╤В╨░╤А, ╨╕╨╝╤П, chat), 2 PLG-placeholder, ╨╕╤Б╤В╨╛╤А╨╕╤П ╨╖╨░╨║╨░╨╖╨╛╨▓ ╤Б ┬л╨Я╨╛╨▓╤В╨╛╤А╨╕╤В╤М┬╗, empty/error states.
2. `#/profile/settings` тАФ ╨╕╨╝╤П, ╤Г╨▓╨╡╨┤╨╛╨╝╨╗╨╡╨╜╨╕╤П (local prefs ╨┤╨╛ backend API), ╨║╨╛╨╜╤В╨░╨║╤В╤Л OTP, ┬л╨Ю ╨╜╨░╤Б┬╗, ┬л╨Э╨░╨┐╨╕╤Б╨░╤В╤М ╨╜╨░╨╝┬╗, ╨Т╨л╨е╨Ю╨Ф.
3. `#/order/:id/receipt` тАФ ╨┤╨╡╤В╨░╨╗╨╕ ╨╖╨░╨║╨░╨╖╨░ ╨┐╨╛ UX-ref (items/total), stub ╨Ю╨дD-╤В╨╡╨║╤Б╤В, ╨║╨╜╨╛╨┐╨║╨░ ╨Я╨Ю╨Т╨в╨Ю╨а╨Ш╨в╨м ╨▒╨╡╨╖ ╨▒╨╕╨╖╨╜╨╡╤Б-╨╗╨╛╨│╨╕╨║╨╕.
4. `#/about` тАФ ╨▓╨╡╤А╤Б╨╕╤П/build, copy, legal links ╨╕╨╖ config, footer.
5. Bottom sheet email/TG тАФ config URLs, ╨╜╨╡ ╤Е╨░╤А╨┤╨║╨╛╨┤ ╨▓ ╨║╨╛╨╝╨┐╨╛╨╜╨╡╨╜╤В╨╡.
6. `DELETE /shop/api/session` тАФ logout customer session (shop/api, ╨╜╨╡ auth/**).
7. ╨С╨╡╨╖ ╨Ю╨дD API, PLG-╨▒╨╕╨╖╨╜╨╡╤Б-╨╗╨╛╨│╨╕╨║╨╕, subscription/referral, ╨┐╤А╨░╨▓╨╛╨║ checkout/payments.

## ╨д╨░╨╖╤Л SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] RED
- [x] GREEN (slice 1: hub/settings/about/receipt/logout)
- [ ] REVIEW / Fly MCP Point A

## ╨д╨░╨╣╨╗╤Л (hot-path)

- `app/frontend/routes/Profile.svelte` тАФ hub ╨Ы╨Ъ (╨┐╨╡╤А╨╡╨┐╨╕╤Б╨░╤В╤М)
- `app/frontend/routes/AccountSettings.svelte` тАФ **╨╜╨╛╨▓╤Л╨╣** settings
- `app/frontend/routes/AboutUs.svelte` тАФ **╨╜╨╛╨▓╤Л╨╣** ┬л╨Ю ╨╜╨░╤Б┬╗
- `app/frontend/routes/OrderReceipt.svelte` тАФ **╨╜╨╛╨▓╤Л╨╣** ╨┤╨╡╤В╨░╨╗╨╕ ╨╖╨░╨║╨░╨╖╨░
- `app/frontend/lib/shopAboutConfig.js` тАФ **╨╜╨╛╨▓╤Л╨╣** legal/support/version config
- `app/frontend/lib/shopPlgBlocks.js` тАФ **╨╜╨╛╨▓╤Л╨╣** PLG config interface
- `app/frontend/lib/shopAccountOrders.js` тАФ **╨╜╨╛╨▓╤Л╨╣** fetch history helper
- `app/frontend/components/PlgBlockSection.svelte` тАФ **╨╜╨╛╨▓╤Л╨╣**
- `app/frontend/components/ContactSupportSheet.svelte` тАФ **╨╜╨╛╨▓╤Л╨╣**
- `app/frontend/App.svelte` тАФ ╨╝╨░╤А╤И╤А╤Г╤В╤Л `/profile/settings`, `/about`, `/order/:id/receipt`
- `app/controllers/shop/api/orders_controller.rb` тАФ `title`/`order_number` ╨▓ history JSON
- `app/controllers/shop/api/session_controller.rb` тАФ `destroy` logout
- `app/services/shop/customer_session.rb` тАФ `clear!`
- `test/integration/shop/pwa_personal_account_lk_test.rb` тАФ **╨╜╨╛╨▓╤Л╨╣** grep/API contract
- `test/javascript/shop_personal_account_lk_test.mjs` тАФ **╨╜╨╛╨▓╤Л╨╣** config/helpers

### Blast-radius (+3)

- `test/integration/shop/profile_ui_contract_test.rb` тАФ *╨┐╨╛╤З╨╡╨╝╤Г: ╨║╨╛╨╜╤В╨░╨║╤В╤Л ╨┐╨╡╤А╨╡╨╡╤Е╨░╨╗╨╕ ╨▓ AccountSettings*
- `app/frontend/routes/Orders.svelte` тАФ *╨┐╨╛╤З╨╡╨╝╤Г: ╤Б╤В╨░╤А╤Л╨╣ `/orders` ╨╜╨╡ ╨┤╨╛╨╗╨╢╨╡╨╜ ╤А╨╡╨│╤А╨╡╤Б╤Б╨╜╤Г╤В╤М*
- `docs/integrations/shop-api.md` тАФ *╨┐╨╛╤З╨╡╨╝╤Г: history fields + DELETE session*

## ╨Э╨╡ ╨╗╨╛╨╝╨░╤В╤М

- Header ┬л╨Я╤А╨╛╤Д╨╕╨╗╤М тА║ ID┬╗ (B1.13-S1), CartSheet ╨║╨░╨╜╨╛╨╜, checkout autofill profile, OTP link email/phone merge
- `#/order/:id` OrderStatus (╨░╨║╤В╨╕╨▓╨╜╤Л╨╣ ╨╖╨░╨║╨░╨╖) тАФ ╨╛╤В╨┤╨╡╨╗╤М╨╜╤Л╨╣ ╨╛╤В receipt
- WebView #66тАУ#68, tenant RLS, payment/webhook ╨║╨╛╨╜╤В╤А╨░╨║╤В╤Л

## ╨Я╤А╨╛╨▓╨╡╤А╨║╨░

- `bundle exec ruby -Itest test/integration/shop/pwa_personal_account_lk_test.rb test/integration/shop/profile_ui_contract_test.rb test/integration/shop/api/orders_controller_test.rb`
- `node --test test/javascript/shop_personal_account_lk_test.mjs`

Fly MCP Point A тАФ ╨┐╨╛╤Б╨╗╨╡ GREEN + deploy.

## ╨Ю╤В╨║╤А╤Л╤В╤Л╨╡ ╨▓╨╛╨┐╤А╨╛╤Б╤Л (╨╜╨╡ ╨▒╨╗╨╛╨║╨╡╤А slice 1)

- ╨д╨╕╨╜╨░╨╗╤М╨╜╤Л╨╡ Google Docs URL, Telegram bot URL, legal entity тАФ placeholder ╨▓ `shopAboutConfig.js` + `VITE_*` env.
- Backend API notification toggle тАФ interim `localStorage` ╨┤╨╛ ╨╛╤В╨┤╨╡╨╗╤М╨╜╨╛╨│╨╛ ╨║╨╛╨╜╤В╤А╨░╨║╤В╨░.
