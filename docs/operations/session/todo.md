# todo — #71 Email-сбор после оплаты (Callcheck-флоу)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| /regress PASS | Local green | /review |

**CBR:** #71  
**ТЗ:** [`customer_tasks/Email-сбор после оплаты (Callcheck-флоу).md`](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md)  
**Артефакты:** [`artifacts/email_collection_after_payment/`](../milestones/veha_2/artifacts/email_collection_after_payment/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** задача 3 из трёх (TG #70 → ЛК #69 → **email-after-pay #71**). Не ломать Callcheck, SBP/card pay, ОФД, #64–#70.

## Цель (1 предложение)

Убрать email/OTP-гейт с оплаты (идентификация = Callcheck-телефон); опциональный email на success для копии чека и CRM-согласия без блокировки pay/навигации.

## Gap (Cloud Code `c73308ae` / `18968c05` vs ТЗ)

| Есть | Не закрыто / дыра |
|------|-------------------|
| `POST orders/:id/email`, `Orders::EmailService`, `OrderEmail`, jobs receipt/CRM, bounce stub | Happy-path `PaymentResult`: `status=ok` → `settleSuccess()` сразу уходит с success — email-блок часто не виден |
| `OrderSuccessEmailBlock` + `emailCollection.js` | Checkout: ещё **имя** + PhoneAuth (Callcheck) на UI; email-input/OTP-гейта нет, но state `email`/`emailVerified` и ошибка «подтвердите email» живут |
| `NewCardForm` save_card toggle | CRM job = placeholder; bounce signature = stub |
| RSpec stubs `spec/.../email_spec.rb` + JS `assert.fail` | **Не канон** — нужен Minitest + `node --test`; RSpec gem нет |
| — | `INTEGRATIONS.md` / shop-api — нет секции order email / CRM / bounce |

**Канон тестов:** Minitest `test/` · `node --test test/javascript/*.mjs` (не RSpec/Vitest из ТЗ).

## Acceptance (DoD)

1. На оплате нет email-полей и email-OTP; `canPay` не зависит от email.
2. Callcheck/телефон — единственный identity-гейт (не ломать).
3. Toggle «Сохранить карту» необязателен.
4. После успешной оплаты виден необязательный блок «Куда прислать чек и предложения» + marketing checkbox.
5. Skip/закрытие без email — без ошибки и без повторного обязательного запроса.
6. Inline-валидация на клиенте до сети.
7. `POST /shop/api/orders/:id/email` без OTP; идемпотентность; async receipt job; CRM только при consent.
8. Bounce → email invalid, без навязчивого UI.
9. Prefill / change / clear сохранённого email.
10. Кассовый ОФД-чек независим от email.
11. Runnable тесты + INTEGRATIONS bridge.

## Фазы SBR

- [x] PHASE 0 intake
- [x] PHASE 1 SPEC
- [x] RED `0eeaea77`
- [x] GREEN (slice 1: PaymentResult + `::Orders::EmailService` + Checkout без имени + tests)
- [x] /regress (JS 31/0 · Rails 16/0)
- [x] REVIEW (bugbot+security → fix `94f36822` · push/CI)

## Файлы (ожидаемо)

- `app/frontend/routes/Checkout.svelte` — убрать остатки email-гейта / имя по ТЗ S1; pay без email
- `app/frontend/routes/PaymentResult.svelte` — не уходить с success до показа/skip email-блока на `ok`
- `app/frontend/components/OrderSuccessEmailBlock.svelte` — UI блок + consent + skip
- `app/frontend/lib/emailCollection.js` — validate + POST client
- `app/controllers/shop/api/orders/email_controller.rb` — API
- `app/services/orders/email_service.rb` — save / idempotent / enqueue
- `test/integration/shop/api/orders_email_test.rb` — Minitest (новый канон вместо RSpec stub)
- `test/javascript/email_collection_test.mjs` — заменить `assert.fail` на реальные кейсы

### Blast-radius (+3)

- `app/frontend/components/NewCardForm.svelte` / `lib/shopNewCardForm.js` — save_card toggle
- `app/jobs/send_order_receipt_email_job.rb` · `sync_contact_to_crm_job.rb` · `callbacks/email_bounces_controller.rb`
- `docs/integrations/INTEGRATIONS.md` (+ shop-api / notify секция) — bridge email/CRM

## Не ломать

- Callcheck / `PhoneAuthWizard` / `Shop::PhoneOtp` / SMS fallback
- Основной pay flow SBP/карта / `shopPayFsm` / UserCards RebillId
- Создание заказа + обязательный кассовый чек ОФД (`fiscal_receipts`)
- Auth/session, #69 ЛК, #70 Telegram support

## Проверка

- `node --test test/javascript/email_collection_test.mjs`
- `bin/rails test test/integration/shop/api/orders_email_test.rb`
- Регресс зоны (после GREEN): `bin/rails test test/integration/shop/checkout_acceptance_cbr_test.rb` · `node --test test/javascript/shop_personal_account_lk_test.mjs` (или pay-fsm сосед)

Ручное / Fly MCP Point A — после GREEN + deploy апрув.

## Subtasks (трекер)

- [x] S1 Checkout: нет email/имя/OTP-гейта; pay без email
- [x] S2 Payment flow без email-ошибки (canPay = phone)
- [x] S3 save_card toggle необязателен
- [x] S4 Email-блок на success + «Чек сформирован»
- [x] S5 Marketing checkbox
- [x] S6 Неблокирующий skip
- [x] S7 Inline validate без сети
- [x] S8 API save без OTP (`::Orders::EmailService`)
- [x] S9 CRM только при consent
- [x] S10 Async receipt job
- [x] S11 Bounce → invalid
- [ ] S12 Prefill (есть loadGuestProfile — добить в regress/MCP)
- [x] S13 Change/clear (UI input)
- [x] S14 Idempotent POST
- [ ] S15 ОФД независим (не ломали — smoke в regress)
- [x] S16 FE tests (node:test)
- [x] S17 BE tests (Minitest)
- [x] S18 UX copy
- [x] S19 Full TDD run → /regress PASS
- [ ] S20 Lint (зона) — /review
