# todo тАФ #93 TASK_93-B: Checkout identity (phone vs email)

| ╨Я╨╛╨╗╨╡ | ╨Ч╨╜╨░╤З╨╡╨╜╨╕╨╡ |
|------|----------|
| **ID** | CBR **#93** ┬╖ **TASK_93-B** |
| **╨в╨╕╨┐** | SBR ┬╖ hot-path shop checkout / ╨╛╨┐╨╗╨░╤В╨░ / identity |
| **╨б╤В╨░╤В╤Г╤Б** | **SPEC** ┬╖ Next: `/sbr` RED |
| **╨Т╨╡╤В╨║╨░** | `develop` |
| **╨Ъ╨░╨╜╨╛╨╜** | `@spec-build-review` ┬╖ `@coffeeos-commit-ops` ┬╖ `@coffeeos-dev-gates` |
| **╨в╨Ч** | [`TASK-93-B-Checkout-identity.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-B-Checkout-identity.md) |
| **GATES** | [`GATES-block-B.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-B.md) ┬╖ ╨╜╨╡ `session/GATES.md` (╨┐╨░╤А╨░╨╗╨╗╨╡╨╗╤М╨╜╤Л╨╡ A/C/D) |
| **╨ж╨╡╨╗╤М** | UI ┬л╨╝╨╛╨╢╨╜╨╛ ╨┐╨╗╨░╤В╨╕╤В╤М┬╗ тЙб ╨▒╤Н╨║╨╡╨╜╨┤ ╨▒╨╡╨╖ 422 email ╨┐╤А╨╕ `phone_verified`; ╨╛╨┤╨╕╨╜ identity ╨╜╨░ ╨▓╤Б╨╡ pay-╨┐╤Г╤В╨╕ |
| **OUT** | ╤Б╨║╨╗╨░╨┤/webhook (A) ┬╖ SMS host (C) ┬╖ per_page (D) ┬╖ Init race (E) ┬╖ RLS ┬╖ OTP ╨┤╨╗╨╕╨╜╤Л ┬╖ FCM ┬╖ deploy (L) ┬╖ email ╤З╨╡╨║╨░ post-pay (#71) ╨╜╨╡ ╨▒╨╗╨╛╨║╨╕╤А╤Г╨╡╤В Pay |

## ╨Ъ╨░╨╜╨╛╨╜ ╨┐╤А╨╛╨┤╤Г╨║╤В╨░ (╨╖╨░╤Д╨╕╨║╤Б╨╕╤А╨╛╨▓╨░╨╜╨╛ SPEC) тАФ phone-first

| ID | ╨а╨╡╤И╨╡╨╜╨╕╨╡ |
|----|---------|
| **R1** | Session customer ╤Б `phone_verified` тЖТ ╨╝╨╛╨╢╨╜╨╛ ╤Б╨╛╨╖╨┤╨░╨▓╨░╤В╤М ╨╖╨░╨║╨░╨╖ ╨╕ ╨╕╨╜╨╕╤Ж╨╕╨╕╤А╨╛╨▓╨░╤В╤М ╨╛╨┐╨╗╨░╤В╤Г (email ╨╜╨╡ ╨╛╨▒╤П╨╖╨░╤В╨╡╨╗╨╡╨╜) |
| **R2** | Email ╨╜╨╡ ╨╛╨▒╤П╨╖╨░╤В╨╡╨╗╨╡╨╜ ╨┤╨╗╤П Pay; verified email тАФ merge ╨║╨░╨║ ╤Б╨╡╨╣╤З╨░╤Б; ╨╕╨╜╨░╤З╨╡ ╨╖╨░╨║╨░╨╖ ╨╜╨░ phone-customer; email post-pay (#71) ╨╛╨║ |
| **R3** | ╨С╨╡╨╖ `phone_verified` **╨╕** ╨▒╨╡╨╖ `email_verified` тЖТ 422; UI `canPay` false |
| **R4** | ╨Ю╨┤╨╜╨░ ╨┐╤А╨╛╨▓╨╡╤А╨║╨░ identity: orders / new_card / one_click / SBP create order |
| **R5** | UI: `identityReady` тЙб R1тАУR3 (`phoneVerified \|\| emailVerified`), ╨╜╨╡ ┬л╤В╨╡╨╗╨╡╤Д╨╛╨╜ ╨╛╨║ + ╤Б╨║╤А╤Л╤В╤Л╨╣ require email┬╗ |

**╨Э╨╡ email-gate. ╨Э╨╡ ╨│╨╕╨▒╤А╨╕╨┤.** ╨б╨╝╨╡╨╜╨░ ╨║╨░╨╜╨╛╨╜╨░ тАФ ╤В╨╛╨╗╤М╨║╨╛ ╨┤╨╛ RED.

## SBR

- [x] PHASE 0 `/start` тАФ `TASK-93-B-Checkout-identity.md`
- [x] `/unlazy` тАФ `GATES-block-B.md` (G3 baseline met ┬╖ G1/G2 unmet pre-RED ┬╖ G5тЖТL)
- [x] PHASE 1 `/spec` тАФ ╤Н╤В╨╛╤В todo ┬╖ phone-first
- [ ] PHASE 2 RED тАФ T-B2a/c, T-B5a/c ╨║╤А╨░╤Б╨╜╤Л╨╡ ╨╜╨░ HEAD ┬╖ `recurrent_order_creator_test.rb` + `checkout_identity_test.rb` ┬╖ ╨║╨╛╨╝╨╝╨╕╤В `[RED]`
- [ ] PHASE 2 GREEN тАФ ╨╛╨┤╨╜╨░ identity-╨┐╤А╨╛╨▓╨╡╤А╨║╨░ + Checkout sync ┬╖ ╨║╨╛╨╝╨╝╨╕╤В `[GREEN]` ┬╖ T-B2* T-B4* T-B5* PASS
- [ ] `/regress` тАФ G3 zone + ┬з ╨Я╤А╨╛╨▓╨╡╤А╨║╨░
- [ ] PHASE 3 `/review` тАФ ╤В╨░╨▒╨╗╨╕╤Ж╨░ B1тАУB5 PASS ┬╖ push ┬╖ **╨▒╨╡╨╖ deploy**

## ╨д╨░╨╣╨╗╤Л (╨╛╨╢╨╕╨┤╨░╨╡╨╝╨╛)

- `app/services/shop/order_creator.rb` тАФ `find_or_create_customer!`: phone_verified session тЖТ order ╨▒╨╡╨╖ email; email_verified path ╤Б╨╛╤Е╤А╨░╨╜╨╕╤В╤М; neither тЖТ Error
- `app/services/shop/recurrent_order_creator.rb` тАФ `find_customer!`: ╤В╨╛╤В ╨╢╨╡ ╨║╨░╨╜╨╛╨╜ (session phone customer + card ownership)
- `app/frontend/routes/Checkout.svelte` тАФ `identityReady = phoneVerified \|\| emailVerified`; Pay payload ╨▒╨╡╨╖ ╤Д╨╡╨╣╨║╨╛╨▓╨╛╨│╨╛ `emailVerified`; `loadSavedCards` ╨╛╨║ ╨▒╨╡╨╖ `?email=` ╨┐╤А╨╕ session

### Blast-radius (+╤Б╨╛╤Б╨╡╨┤╨╕)

- `app/controllers/shop/api/user_cards_controller.rb` тАФ B4: ╤Г╨╢╨╡ session `customer_id`; ╨╜╨╡ ╤В╤А╨╡╨▒╨╛╨▓╨░╤В╤М email (╤А╨╡╨│╤А╨╡╤Б╤Б T-B4a)
- `app/controllers/shop/api/payments_controller.rb` тАФ new_card/one_click ╨╗╨╛╨▓╤П╤В `OrderCreator::Error`; ╤В╨╡╨║╤Б╤В 422 ╨╝╨╛╨╢╨╡╤В ╤Б╨╝╨╡╨╜╨╕╤В╤М╤Б╤П ╨╜╨░ ┬л╤В╨╡╨╗╨╡╤Д╨╛╨╜ ╨╕╨╗╨╕ email┬╗
- `app/services/shop/checkout_identity.rb` тАФ **╨╛╨┐╤Ж╨╕╨╛╨╜╨░╨╗╤М╨╜╨╛** ╨╜╨░ GREEN, ╨╡╤Б╨╗╨╕ DRY ╨╛╨▒╤Й╨╡╨╣ ╨┐╤А╨╛╨▓╨╡╤А╨║╨╕ (╨╕╨╜╨░╤З╨╡ ╨╛╤Б╤В╨░╨▓╨╕╤В╤М ╨▓ ╨┤╨▓╤Г╤Е creators)

### ╨в╨╡╤Б╤В╤Л (╤Б╨╛╨╖╨┤╨░╤В╤М/╨┤╨╛╨┐╨╛╨╗╨╜╨╕╤В╤М ╨╜╨░ RED)

- `test/services/shop/order_creator_test.rb` тАФ T-B2a/b/c
- `test/services/shop/recurrent_order_creator_test.rb` тАФ **╨╜╨╛╨▓╤Л╨╣** ┬╖ T-B2d
- `test/integration/shop/api/checkout_identity_test.rb` тАФ **╨╜╨╛╨▓╤Л╨╣** ┬╖ T-B4a ┬╖ T-B5aтАжe ┬╖ T-B2e/f ╤З╨╡╤А╨╡╨╖ API

## ╨Э╨╡ ╨╗╨╛╨╝╨░╤В╤М

- Email-verified guest **╨▒╨╡╨╖** phone тАФ ╨┐╨╛-╨┐╤А╨╡╨╢╨╜╨╡╨╝╤Г ╨╝╨╛╨╢╨╡╤В ╨┐╨╗╨░╤В╨╕╤В╤М (R3)
- one_click: ╨║╨░╤А╤В╨░ ╨┐╤А╨╕╨╜╨░╨┤╨╗╨╡╨╢╨╕╤В session customer; ╤З╤Г╨╢╨╛╨╣ RebillId тЖТ 422 ownership (╨╜╨╡ identity)
- Callcheck/SMS linker (#89) тАФ session + `phone_verified` ╨▒╨╡╨╖ ╤А╨╡╨│╤А╨╡╤Б╤Б╨░
- Post-pay email (#71/#91) тАФ email **╨╜╨╡** ╤В╤А╨╡╨▒╤Г╨╡╤В╤Б╤П ╨┤╨╛ Pay
- Amount limits / closed shop / simulate guards тАФ ╨▒╨╡╨╖ ╨╕╨╖╨╝╨╡╨╜╨╡╨╜╨╕╨╣

## ╨Я╤А╨╛╨▓╨╡╤А╨║╨░

```bash
ruby bin/rails test test/services/shop/order_creator_test.rb test/services/shop/recurrent_order_creator_test.rb test/integration/shop/api/checkout_identity_test.rb
```

```bash
ruby bin/rails test test/integration/shop/api/email_otp_checkout_test.rb test/integration/shop/shop_one_click_payment_step4_test.rb test/integration/shop/shop_new_card_payment_step2_test.rb
```

(= GATES-block-B G1+G2 ╨╕ G3)

## ╨Ь╨░╤В╤А╨╕╤Ж╨░ ╨┐╤А╨╕╤С╨╝╨║╨╕ (DoD B)

| ID | Assert |
|----|--------|
| T-B1 | SPEC + ╨╛╨┤╨╜╨░ ╤В╨╛╤З╨║╨░ identity ╨▓ ╨║╨╛╨┤╨╡ = R1тАУR5 |
| T-B2a | phone_verified, email nil тЖТ order, ╨╜╨╡╤В Error email |
| T-B2b | email_verified ╨▒╨╡╨╖ phone тЖТ order |
| T-B2c | neither тЖТ Error/422, order ╨╜╨╡ ╤Б╨╛╨╖╨┤╨░╨╜ |
| T-B2d | one_click phone ╨▒╨╡╨╖ email тЖТ ╨╜╨╡ identity 422 |
| T-B2e | new_card phone ╨▒╨╡╨╖ email тЖТ ╨╜╨╡ identity 422 |
| T-B2f | SBP/orders phone ╨▒╨╡╨╖ email тЖТ ╨╜╨╡ identity 422 |
| T-B3aтАУc | `identityReady` тЙб R1тАУR3; canPay false ╨▒╨╡╨╖ identity |
| T-B4a/b | GET /user/cards phone session 200; loadSavedCards ╨▒╨╡╨╖ ╨╛╨▒╤П╨╖╨░╤В╨╡╨╗╤М╨╜╨╛╨│╨╛ `?email=` |
| T-B5aтАУe | integration ╨┐╨░╨║╨╡╤В (╤Б╨╝. ╨в╨Ч ┬з7) |

## REVIEW-╤В╨░╨▒╨╗╨╕╤Ж╨░ (╨▓╤Б╤В╨░╨▓╨╕╤В╤М ╨▓ `/review`)

```
B1 ╨║╨░╨╜╨╛╨╜ phone-first     PASS (SPEC + ╨║╨╛╨┤)
B2 T-B2a..f              PASS
B3 UI identityReady      PASS
B4 T-B4a T-B4b           PASS
B5 T-B5a..e              PASS
```
