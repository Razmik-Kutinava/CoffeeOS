# todo — #93 TASK_93-B: Checkout identity (phone vs email)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-B** |
| **Тип** | SBR · hot-path shop checkout / оплата / identity |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-93-B-Checkout-identity.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-B-Checkout-identity.md) |
| **GATES** | [`GATES-block-B.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-B.md) · не `session/GATES.md` (параллельные A/C/D) |
| **Цель** | UI «можно платить» ≡ бэкенд без 422 email при `phone_verified`; один identity на все pay-пути |
| **OUT** | склад/webhook (A) · SMS host (C) · per_page (D) · Init race (E) · RLS · OTP длины · FCM · deploy (L) · email чека post-pay (#71) не блокирует Pay |

## Канон продукта (зафиксировано SPEC) — phone-first

| ID | Решение |
|----|---------|
| **R1** | Session customer с `phone_verified` → можно создавать заказ и инициировать оплату (email не обязателен) |
| **R2** | Email не обязателен для Pay; verified email — merge как сейчас; иначе заказ на phone-customer; email post-pay (#71) ок |
| **R3** | Без `phone_verified` **и** без `email_verified` → 422; UI `canPay` false |
| **R4** | Одна проверка identity: orders / new_card / one_click / SBP create order |
| **R5** | UI: `identityReady` ≡ R1–R3 (`phoneVerified \|\| emailVerified`), не «телефон ок + скрытый require email» |

**Не email-gate. Не гибрид.** Смена канона — только до RED.

## SBR

- [x] PHASE 0 `/start` — `TASK-93-B-Checkout-identity.md`
- [x] `/unlazy` — `GATES-block-B.md` (G3 baseline met · G1/G2 unmet pre-RED · G5→L)
- [x] PHASE 1 `/spec` — этот todo · phone-first
- [ ] PHASE 2 RED — T-B2a/c, T-B5a/c красные на HEAD · `recurrent_order_creator_test.rb` + `checkout_identity_test.rb` · коммит `[RED]`
- [ ] PHASE 2 GREEN — одна identity-проверка + Checkout sync · коммит `[GREEN]` · T-B2* T-B4* T-B5* PASS
- [ ] `/regress` — G3 zone + § Проверка
- [ ] PHASE 3 `/review` — таблица B1–B5 PASS · push · **без deploy**

## Файлы (ожидаемо)

- `app/services/shop/order_creator.rb` — `find_or_create_customer!`: phone_verified session → order без email; email_verified path сохранить; neither → Error
- `app/services/shop/recurrent_order_creator.rb` — `find_customer!`: тот же канон (session phone customer + card ownership)
- `app/frontend/routes/Checkout.svelte` — `identityReady = phoneVerified \|\| emailVerified`; Pay payload без фейкового `emailVerified`; `loadSavedCards` ок без `?email=` при session

### Blast-radius (+соседи)

- `app/controllers/shop/api/user_cards_controller.rb` — B4: уже session `customer_id`; не требовать email (регресс T-B4a)
- `app/controllers/shop/api/payments_controller.rb` — new_card/one_click ловят `OrderCreator::Error`; текст 422 может смениться на «телефон или email»
- `app/services/shop/checkout_identity.rb` — **опционально** на GREEN, если DRY общей проверки (иначе оставить в двух creators)

### Тесты (создать/дополнить на RED)

- `test/services/shop/order_creator_test.rb` — T-B2a/b/c
- `test/services/shop/recurrent_order_creator_test.rb` — **новый** · T-B2d
- `test/integration/shop/api/checkout_identity_test.rb` — **новый** · T-B4a · T-B5a…e · T-B2e/f через API

## Не ломать

- Email-verified guest **без** phone — по-прежнему может платить (R3)
- one_click: карта принадлежит session customer; чужой RebillId → 422 ownership (не identity)
- Callcheck/SMS linker (#89) — session + `phone_verified` без регресса
- Post-pay email (#71/#91) — email **не** требуется до Pay
- Amount limits / closed shop / simulate guards — без изменений

## Проверка

```bash
ruby bin/rails test test/services/shop/order_creator_test.rb test/services/shop/recurrent_order_creator_test.rb test/integration/shop/api/checkout_identity_test.rb
```

```bash
ruby bin/rails test test/integration/shop/api/email_otp_checkout_test.rb test/integration/shop/shop_one_click_payment_step4_test.rb test/integration/shop/shop_new_card_payment_step2_test.rb
```

(= GATES-block-B G1+G2 и G3)

## Матрица приёмки (DoD B)

| ID | Assert |
|----|--------|
| T-B1 | SPEC + одна точка identity в коде = R1–R5 |
| T-B2a | phone_verified, email nil → order, нет Error email |
| T-B2b | email_verified без phone → order |
| T-B2c | neither → Error/422, order не создан |
| T-B2d | one_click phone без email → не identity 422 |
| T-B2e | new_card phone без email → не identity 422 |
| T-B2f | SBP/orders phone без email → не identity 422 |
| T-B3a–c | `identityReady` ≡ R1–R3; canPay false без identity |
| T-B4a/b | GET /user/cards phone session 200; loadSavedCards без обязательного `?email=` |
| T-B5a–e | integration пакет (см. ТЗ §7) |

## REVIEW-таблица (вставить в `/review`)

```
B1 канон phone-first     PASS (SPEC + код)
B2 T-B2a..f              PASS
B3 UI identityReady      PASS
B4 T-B4a T-B4b           PASS
B5 T-B5a..e              PASS
```
