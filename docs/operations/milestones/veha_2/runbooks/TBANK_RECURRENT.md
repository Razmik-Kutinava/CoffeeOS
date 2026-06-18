# Т-Банк: рекуррентные платежи и привязка карты (B1.12)

**Статус:** R1 в коде + Fly MCP 5/5 (2026-06-18) · R2 — web-iframe + 3DS  
**ТЗ:** [`B1_12_recurrent_payments.md`](../requirements/customer_tasks/B1_12_recurrent_payments.md)  
**Связано:** §2.3 (базовая оплата закрыта) · `Payments::TbankAdapter` · `POST /callbacks/tbank`

---

## Scope CoffeeOS

| Параметр | Значение |
|----------|----------|
| Банк | Т-Банк |
| Канал | Веб-витрина (Svelte) |
| Карт на пользователя | Все храним; **главная** = последняя успешная оплата |
| Рекуррент | Только **card** (СБП — позже, не B1.12) |
| Сохранение | После первой успешной оплаты, без галочки |
| Ошибки R3 | Карта → «Привязать другую» · сеть/инфра → «Повторить» · идемпотентность |
| Храним в БД | `bank_token`, `masked_pan` только |
| Не храним | PAN, CVV/CVC |

---

## Подзадачи

| ID | Что | Зависимости |
|----|-----|-------------|
| **R1** | `user_cards`, webhook → token, API charge by `card_id` | — |
| **R2** | Web-фрейм ввода + 3DS | R1 |
| **R3** | 1 клик, стейт кнопки | R1, R2 |

---

## TODO перед реализацией

- [x] Init с `Recurrent=Y` + `CustomerKey` на первой card-оплате
- [x] Charge по `RebillId` (`TbankAdapter#charge_recurrent`)
- [x] Webhook → `SavedCardStore` (RebillId + Pan)
- [ ] Web-iframe / платёжная форма для кастомизации (R2)
- [ ] Тестовые карты 3DS в sandbox
- [ ] Маппинг кодов ошибок → UI R3 (истёк срок / нет средств / retry / идемпотентность)

---

## Текущий флоу (§2.3, до B1.12)

1. `Shop::OrderCreator` → `TbankAdapter#init_payment` → `payment_url`
2. Редирект гостя на форму Т-Банка
3. `POST /callbacks/tbank` → `PaymentStatusUpdater` → order `accepted`

**B1.12** добавляет сохранение токена и повторное списание без полного редиректа.

---

## Секреты / ENV (существующие)

См. [`FLY_DEMO_STAND.md`](../../demo/FLY_DEMO_STAND.md) · `TBANK_*` · `SHOP_SIMULATE_PAYMENT=0` на стенде.

Новые переменные — зафиксировать здесь после сверки с докой банка.

---

## Приёмка (после кода)

| Артефакт | Подзадача |
|----------|-----------|
| `b112_r1_recurrent_post_deploy_*.json` | R1 |
| `b112_r2_native_card_post_deploy_*.json` | R2 |
| `b112_r3_one_click_post_deploy_*.json` | R3 |

**R1 Fly MCP (2026-06-18):**

```bash
ruby bin/b112_r1_recurrent_prep_fly.rb
node bin/b112_r1_recurrent_mcp.mjs
```

Prep: OTP + seed `MobilePaymentMethod` + curl smoke → `tmp/b112_r1_recurrent_prep.json`.  
MCP: Playwright + session cookies — `saved_cards`, recurrent path (fake RebillId → 422 от банка OK), card init `payment_url`.

Регрессия: `bin/rails test test/integration/shop/api/qa_section_2_3_*` + зона shop.
