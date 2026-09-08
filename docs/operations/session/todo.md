# todo — СБП банк-ограничения: 3001 + Zero-Click AccountToken

| Поле | Значение |
|------|----------|
| **Режим** | ops/bank-first SBR · **не** «переписать оплату» |
| **Primary** | Slice **O** → **B** → **Z** |
| **Conditional** | Slice **C** — только FAIL нашего слоя после O PASS |
| **ТЗ** | #34 · `tbank.md` · ISSUES SBP 3001 |
| **Артефакт O** | `…/tbank_sbp_autopayments_account_token/mcp/fly_v493_2026-09-08/` |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | **v493** |

## Slices

| Slice | DoD | Статус |
|-------|-----|--------|
| **O** Кабинет / 3001 | init без 3001 → payment_url | [x] **PASS** v493 · NSPK `AD1P103…` · order `b87b63ea…` |
| **B** Bind AccountToken | webhook RequestKey → token в БД | [ ] **BLOCKED_UNTIL_BANK** |
| **Z** Zero-Click | `POST …/sbp/charge` | [ ] SKIP до B |
| **C** Code | RED→GREEN | [ ] n/a (O PASS, нет FAIL нашего слоя) |

## SBR

- [x] **SPEC**
- [x] **Verify O** — live init Point A PASS (docs/artifact)
- [ ] **Verify B** — live bind в банке (владелец)
- [ ] **Verify Z**
- [ ] **RED/GREEN/REVIEW** — только если C

## Файлы (ожидаемо) — при C

- `docs/integrations/tbank.md`
- `app/services/payments/sbp_account_token_from_webhook.rb`
- `app/services/payments/sbp_account_token_store.rb`
- `app/services/payments/tbank_sbp_autopay.rb`
- `app/frontend/lib/shopSbpPay.js`
- `test/integration/shop/api/sbp_autopay_charge_test.rb`
- `test/integration/shop/api/sbp_init_save_account_test.rb`
- blast: `app/jobs/payments/tbank_callback_job.rb`

## Не ломать

1. Разовый СБП deep link
2. Card Init/Charge / UserCards
3. Webhook idempotency
4. Min ≥10₽ · mapSbpInitError 3001
5. Soft decline — не удалять AccountToken

## Проверка

```bash
ruby bin/rails test test/integration/shop/api/sbp_autopay_charge_test.rb
ruby bin/rails test test/services/payments/sbp_account_token_store_test.rb test/services/payments/sbp_account_token_from_webhook_test.rb
# Live: sbp/init · bind · sbp/charge
```