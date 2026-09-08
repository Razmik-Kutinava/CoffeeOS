# todo — UserCards / RebillId + #26 M2 (verify-first)

| Поле | Значение |
|------|----------|
| **Режим** | Verify-first hot-path SBR · **Slice C только после FAIL нашего слоя** |
| **CBR / корни** | UserCards · #26 M2 (decline → sheet) |
| **ТЗ** | UserCards · #26 · Понятные сообщения · MCP_PLAN_STEP5 |
| **Bridge / plan** | `docs/integrations/tbank.md` · `MCP_PLAN_STEP5_2026-09-07.md` |
| **Стек** | `mobile_payment_methods` + `Payments::SavedCardStore` |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | **v493** · MCP **PASS** · `…/mcp/fly_v493_2026-09-08/` |
| **OUT** | SBP 3001 · #78 · смена TbankAdapter · hardcode RebillId |

## SBR

- [x] **SPEC**
- [x] **P** Preflight — guest Aram + cards `*5953`/`*8782` · cart ≥10₽
- [x] **U** MIR + RebillId (existing) + Charge proves token · new save_card FA не re-run
- [x] **O** One-click `*5953` → `#202609-0022` · чек
- [x] **M** #26 M2 — invalid RebillId `*0001` → inline «Сбой банка: позже» · sheet open · selected
- [x] **C** — n/a (verify PASS)
- [x] **RED/GREEN/REVIEW** — n/a
- [ ] **deploy** — не нужен

## Файлы (ожидаемо) — C не открывали

- `app/services/payments/saved_card_store.rb`
- `app/services/payments/tbank_payment_sync.rb`
- `app/services/shop/one_click_payment_service.rb`
- `app/services/shop/new_card_payment_service.rb`
- `app/frontend/components/PaymentMethodsSheet.svelte`
- `app/frontend/lib/shopPayFsm.js`
- `app/frontend/lib/openRepeatPaymentSheet.js`

## Не ломать

- Webhook idempotency · `save_card=false` · card hash · session `user/cards` · min 10₽ · `isTokenInvalid` = токен карты

## Проверка

```bash
# Live Point A v493 — см. MCP_RESULT.md
# Local (если C): rails payments/one_click + node repeat_invalid_token
```
