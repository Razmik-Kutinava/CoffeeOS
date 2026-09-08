# todo — UserCards / RebillId + #26 M2 (verify-first)

| Поле | Значение |
|------|----------|
| **Режим** | Verify-first hot-path SBR · **Slice C только после FAIL нашего слоя** |
| **CBR / корни** | UserCards · #26 M2 (decline → sheet) |
| **ТЗ** | [`Исправление сохранения карты в UserCards…`](../milestones/veha_2/requirements/customer_tasks/Исправление%20сохранения%20карты%20в%20UserCards%20после%20успешной%20оплаты.md) · [`Главный экран — повторный заказ (невалидный токен)…`](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) · [`Понятные сообщения…`](../milestones/veha_2/requirements/customer_tasks/Понятные%20сообщения%20пользователю%20при%20ошибке%20оплаты.md) |
| **Bridge / plan** | `docs/integrations/tbank.md` · [`MCP_PLAN_STEP5_2026-09-07.md`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/MCP_PLAN_STEP5_2026-09-07.md) |
| **Стек** | `mobile_payment_methods` + `Payments::SavedCardStore` (не отдельная UserCards-таблица) |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly as-is** | v490 · #26 v481 MCP **PARTIAL** (нет saved card у MCP-гостя) |
| **Артефакты** | `…/repeat_order_invalid_token_payment_sheet/mcp/fly_vNNN_YYYY-MM-DD/` |
| **OUT** | SBP 3001 · #78 · смена TbankAdapter · hardcode RebillId · gem’ы оплаты |

## SBR

- [x] **SPEC** — этот файл
- [ ] **P** Preflight — гость + session + (для M2) saved card · корзина ≥10₽
- [ ] **U** UserCards E2E — `save_card=true` → MIR в списке → RebillId (сразу **или** delayed `sync_for_rebill!`)
- [ ] **O** One-click happy — Charge → accepted · NewCardForm не auto-open
- [ ] **M** #26 M2 — decline → sheet open + `payment-method-inline-error` + карта selected
- [ ] **C** Code — **только** при FAIL нашего слоя (не «нет карты у MCP», не чистый ErrorCode банка)
- [ ] **RED** / **GREEN** / **REVIEW** — только если C
- [ ] **deploy** — только апрув владельца (live после fix)

## Файлы (ожидаемо)

*Scope C при FAIL; verify читает те же пути + MCP plan.*

- `app/services/payments/saved_card_store.rb` — persist mask/exp/RebillId · consent `save_card` · upsert
- `app/services/payments/tbank_payment_sync.rb` — `sync_for_rebill!` (delayed RebillId)
- `app/services/shop/one_click_payment_service.rb` — Charge(RebillId) · fail → token-invalid сигнал
- `app/services/shop/new_card_payment_service.rb` — Init/`save_card` → FA path
- `app/frontend/components/PaymentMethodsSheet.svelte` — inline `data-testid="payment-method-inline-error"` · selected
- `app/frontend/lib/shopPayFsm.js` — канон-тексты отказа (без сырого ErrorCode)
- `app/frontend/lib/openRepeatPaymentSheet.js` — шторка остаётся / без auto NewCardForm

### Соседи (blast-radius)

- `app/jobs/payments/tbank_callback_job.rb` — webhook → sync/finalize (idempotency)
- `test/services/payments/tbank_payment_sync_test.rb` · `test/services/payments/saved_card_store_test.rb` — зеркало U/C
- `test/integration/shop/shop_one_click_payment_step4_test.rb` · `test/javascript/repeat_invalid_token_payment_test.mjs` — O/M

## Slices DoD (кратко)

| Slice | PASS | Не путать с FAIL |
|-------|------|------------------|
| **P** | Session guest · `GET /shop/api/user/cards` не пустой **или** готов new_card+save · для M2 известный decline **или** SKIP | — |
| **U** | Карта в `mobile_payment_methods` + `card_token` · GET cards этой сессии | delayed RebillId в окне sync = **PASS + delayed** |
| **O** | Charge OK → order/pay success | bank 119 / rate-limit = **BANK_ERROR** |
| **M** | Sheet open · inline канон · card selected · NewCardForm не auto | нет saved card = **BLOCKED** (как v481), не FAIL #26 |
| **C** | Fix + regress + повтор live U/O/M | — |

**Fail→C матрица (U):** FA OK + webhook RebillId но карты нет → SavedCardStore/flag · webhook без RebillId и sync не довёл → `sync_for_rebill!` · карта в БД / GET пусто → session/merge · `save_card=false` но карта есть → consent · дубль pan+exp → upsert.

## Не ломать

- Webhook idempotency (`TbankCallbackJob` / sync)
- `save_card=false` → карта **не** появляется
- Card hash / antifraud binding (#74/#75)
- Session ownership `GET user/cards` (чужая сессия пусто)
- Min charge ≥10₽ · Receipt на Init где принято
- `isTokenInvalid` = токен **карты**, не auth refresh

## Проверка

```bash
ruby bin/rails test test/services/payments/saved_card_store_test.rb test/services/payments/tbank_payment_sync_test.rb test/services/shop/one_click_payment_service_test.rb test/integration/shop/shop_one_click_payment_step4_test.rb test/controllers/shop/api/user_cards_controller_test.rb
node --test test/javascript/repeat_invalid_token_payment_test.mjs test/javascript/open_repeat_payment_sheet_test.mjs
```

Live (после P): Point A MCP · артефакт `MCP_RESULT.md` (+ скрины M) · PAN/CVV/полные RebillId **не** в артефакты (маска `*5953` ок).