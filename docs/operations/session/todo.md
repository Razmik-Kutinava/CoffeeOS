# todo — UserCards E2E Point A (2026-08-10)

**Намерение:** Шаг 1 — go UserCards · E2E save_card на Point A → апрув скрин 8925

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| UserCards 3.5 MCP Fly v444 | Local 61/0 · 8925 UI PASS · E2E real PAN ⛔ | Апрув 8925 владельцем · E2E real MIR (отдельный шаг) |

## Файлы (ожидаемо)
- `app/services/payments/tbank_payment_sync.rb`
- `app/services/payments/saved_card_store.rb`
- `app/services/shop/new_card_payment_service.rb`
- `app/controllers/shop/api/user_cards_controller.rb`
- `app/controllers/callbacks/tbank_controller.rb`
- `docs/operations/milestones/veha_2/runbooks/USERCARDS_SAVE_CARD_FLOW.md`
- `docs/operations/ISSUES.md`

## Не ломать
- оплата / 1-клик (one_click + RebillId)
- кнопка «повторить» / frequent
- табло бариста / статусы в PWA
- peek корзины / CartSheet layering / PaymentMethodsSheet 8925

## Проверка
```bash
bundle exec rails test test/integration/shop/shop_usercards_phase1_persist_test.rb \
  test/integration/shop/shop_saved_cards_step3_test.rb \
  test/integration/shop/shop_save_card_false_step6_test.rb \
  test/integration/shop/shop_second_card_step5_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/services/payments/tbank_adapter_test.rb
```
→ **PASS** 61 runs, 0 failures (2026-08-10)

## Чеклист шага
- [x] Local «Проверка» PASS
- [x] Fly diagnose: cards aramfifa / Point A (`usercards_fly_diagnose_2026-08-10.json`)
- [x] MCP скрин PaymentMethodsSheet vs 8925 (`usercards_phase35_mcp_2026-08-10_*`)
- [ ] E2E save_card real PAN — **BLOCKED** (prod отклоняет test PAN; нужна MIR заказчика)
- [ ] Апрув 3.5 — ждёт «ок» владельца/заказчика по скрину

**Evidence 8925:** `docs/operations/milestones/veha_2/artifacts/usercards_save_card/screenshots/usercards_phase35_mcp_2026-08-10_payment_sheet_two_cards.png`
