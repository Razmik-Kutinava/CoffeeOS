# todo — #75 Привязка способа оплаты и промо 11₽

| Поле | Значение |
|------|----------|
| **CBR** | #75 |
| **ТЗ** | [`customer_tasks/Привязка способа оплаты и промо 11₽.md`](../milestones/veha_2/requirements/customer_tasks/Привязка%20способа%20оплаты%20и%20промо%2011₽.md) |
| **Артефакты** | [`artifacts/payment_method_binding_promo_11rub/`](../milestones/veha_2/artifacts/payment_method_binding_promo_11rub/) |
| **Предшественник** | #74 `card_hash` + unique active (карта); СБП uniqueness / promo / attempts — net-new |
| **Ветка** | `develop` |

## SBR

- [x] **SPEC** — файлы + Не ломать + Проверка
- [x] **RED** — падающие тесты binding/promo/velocity `[RED]`
- [x] **GREEN** — реализация + регрессия зоны `[GREEN]` (slice 1: hash/SBP unique / attempts / GrowthPromo / TOV)
- [x] **REVIEW fixes** — discount/chk_order_amounts · mark_used! · SBP init pricing · receipt 11₽
- [x] **REVIEW** — bugbot + security HIGH fixed · Entire · push · **CI green**

### Follow-up (после CI / следующий slice)

- [ ] velocity limits (phone/device/IP/BIN) + phone_status enum + step-up OTP
- [x] mark_used! на успешной привязке (SavedCardStore / SbpAccountTokenFromWebhook)
- [ ] Checkout.svelte: прокинуть `promoEligible` / `cartTotalRub` в sheet
- [ ] audit/dedupe существующих SBP дублей
- [ ] matching перевыпущенной карты — out of scope без надёжного признака
- [ ] PII retention для card_binding_attempts (MEDIUM security)

## Файлы (ожидаемо)

1. `app/services/payments/saved_card_store.rb` — card `method_hash`/`card_hash`, `blocked_method_taken`, race → штатный отказ без утечки
2. `app/services/payments/sbp_account_token_store.rb` — стабильный SBP `method_hash` + cross-account unique (как #74 для карт)
3. `app/models/mobile_payment_method.rb` — `method_type` card\|sbp, `method_hash`, partial unique indexes
4. `app/services/shop/order_creator.rb` — eligibility промо до Init; динамическая сумма 11₽ vs полная корзина; единый payment object
5. `app/frontend/components/PaymentMethodsSheet.svelte` — тексты промо/nudge, скрытие блока, TOV СБП, сообщения blocked/step-up/rate-limit
6. `app/models/card_binding_attempt.rb` (**net-new**) + миграция — аудит попыток (`method_type`, `method_hash`, phone, device, ip, bin, `is_growth_event`, …)
7. `app/services/payments/growth_promo.rb` (**net-new**) — eligibility + дедуп промо по phone/`method_hash`; velocity phone/device/IP/BIN (BIN только card)

### Blast-radius (соседи)

- `app/jobs/payments/tbank_callback_job.rb` — после CONFIRMED: persist card/SBP + growth success only on paid
- `app/controllers/shop/api/payments_controller.rb` — API `save_card`/`save_sbp_account` + безопасные ошибки привязки
- `app/frontend/routes/Checkout.svelte` — прокидка чекбокса/суммы в sheet без ломки pay FSM

## Не ломать

- Обычная оплата полной суммы корзины при выключенном чекбоксе / без права на промо
- Существующие сохранённые карты и one-click (RebillId) без повторного growth
- Существующая привязка СБП / `save_sbp_account` / deep-link в банк (без своих текстов поверх банка)
- Callback/webhook Т-Банк + история заказов / возвраты

## Проверка

```bash
bin/rails test test/services/payments/saved_card_store_test.rb test/services/payments/sbp_account_token_store_test.rb
bin/rails test test/services/shop/order_creator_test.rb test/integration/shop/api/qa_section_2_3_payment_cart_test.rb
```

**Local regress 2026-09-04:** PASS — payments+growth 28/70 · order_creator+qa§2.3 23/44 · i18n 4/4  
(После появления тестов #75 — зеркала `growth_promo` / `card_binding_attempt` / JS sheet уже в прогоне.)

## Скоуп (кратко)

| In | Out |
|----|-----|
| Unified binding card+SBP, DB unique `method_hash`, attempts audit, velocity, promo 11₽, PWA тексты | Auth/login rewrite, loyalty, новые внешние webhook, gem’ы оплаты, UI внутри банка |
| `phone_status` enum + OTP step-up на телефон аккаунта | Matching перевыпущенной карты без надёжного признака — явно out / зафиксировать в GREEN |

## Заметки SPEC

- ТЗ `npm test` / `tsc` — формулировка заказчика; канон CoffeeOS = `bin/rails test` (+ JS `.mjs` при UI).
- #74 уже: `card_hash`, partial unique, silent reject. #75: SBP hash, `blocked_method_taken`, attempts, promo amount, UI.
- `payment_type` на модели уже есть — сверить с TZ `method_type` (alias vs rename) в RED/GREEN.
