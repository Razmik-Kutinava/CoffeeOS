# TASK_93-B — Блок B: Checkout identity (phone vs email)

**ID заказчика:** TASK_93-B · **CBR:** #93 · **Дата intake:** 2026-09-18  
**Зонтик:** TASK_93 / Critical path hardening  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/critical_path_hardening/  
**Сейчас:** SBR только блок B (A не трогать, кроме регресса при пересечении)

---

## Текст заказчика (дословно)

# TASK_93-B — Блок B: Checkout identity (phone vs email)

Зонтик тот же: **TASK_93** / `#93` — Critical path hardening.  
Этот прогон SBR: **только TASK_93-B**. A не трогать (кроме регресса, если пересечётся).

Title чата: `Задача 93 — Critical path hardening (блок B)`.

---

## 1. Зачем

UI пускает оплату по **`phoneVerified`** (`identityReady = phoneVerified`), а бэкенд в `OrderCreator` / `RecurrentOrderCreator` требует **email + email OTP** → 422 «Укажите email» / «Подтвердите email…» после успешного Callcheck. Клиент думает, что можно платить — сервер отказывает.

Сейчас в коде:
- `Checkout.svelte`: `identityReady = phoneVerified`, Pay шлёт `email` в `/orders`
- `OrderCreator#find_or_create_customer!`: blank email / без verify → Error
- `RecurrentOrderCreator#find_customer!`: то же по email
- Карты: `GET /user/cards` уже по session `customer_id` (phone-only ок); UI иногда добавляет `?email=` только если email verified

## 2. Цель блока

**Что UI считает «можно платить», бэкенд принимает без 422.** Один канон identity на все pay-пути.

## 3. Scope / Non-scope

**В scope (B1–B5):**
- Продуктовый канон identity (B1)
- `Shop::OrderCreator`, `Shop::RecurrentOrderCreator`
- Эндпоинты: `POST /shop/api/orders`, `payments/new_card`, `one_click`, `sbp_init` / charge (через create order)
- `Checkout.svelte`: `identityReady` / `canPay` / профиль / payload Pay
- `GET /shop/api/user/cards` + загрузка в Checkout (B4)
- Тесты B5

**Вне scope:** склад/webhook (A), SMS host (C), per_page (D), Init race (E), RLS, OTP длины, FCM, deploy (L).  
Email **для чека/фискала** после оплаты (#71) — не блокирует Pay, если выбран phone-first.

## 4. Продуктовое решение B1 (зафиксировать в SPEC до RED)

**Канон для TASK_93-B (рекомендация под TASK_89 phone-first):**

| Правило | Решение |
|---------|---------|
| **R1** | **Phone-first:** достаточно `session` customer с `phone_verified` → можно создавать заказ и инициировать оплату |
| **R2** | Email **не** обязателен для Pay; если есть verified email — привязываем/мержим как сейчас; если нет — заказ на phone-customer, email можно собрать post-pay |
| **R3** | Без phone_verified **и** без email_verified → отказ (422), UI не показывает активный Pay |
| **R4** | Все пути: orders / new_card / one_click / SBP create order — **одна** проверка identity |
| **R5** | UI: `identityReady` ≡ серверный канон R1–R3 (не «телефон ок, email молча обязателен») |

**Альтернатива (не смешивать):** email-gate — UI блокирует Pay до email OTP, бэкенд без изменений. Тогда B2 почти no-op, B3 ломает `identityReady = phoneVerified`.  
**В этом ТЗ принимаем phone-first.** Если на `/spec` выберете email-gate — переписать R1–R5 и матрицу тестов зеркально; не делать гибрид.

## 5. Файлы (ожидаемо) — для `/spec`

```
app/services/shop/order_creator.rb
app/services/shop/recurrent_order_creator.rb
app/controllers/shop/api/orders_controller.rb
app/controllers/shop/api/payments_controller.rb
app/controllers/shop/api/user_cards_controller.rb
app/frontend/routes/Checkout.svelte
app/frontend/lib/shopGuestProfile.js          # если трогаем phone/email flags
app/services/shop/phone_verified_customer_linker.rb  # reference, не ломать
app/services/shop/email_verified_customer_linker.rb

test/services/shop/order_creator_test.rb
test/services/shop/recurrent_order_creator_test.rb   # или создать
test/integration/shop/api/… (orders / payments / cards)
test/integration/shop/checkout_identity_*           # новый, если нет
```

(+1–3 соседа только если SPEC найдёт общий concern `CustomerIdentity` — тогда вынести и дописать путь в todo.)

## 6. Не ломать

1. Email-verified guest без phone — по-прежнему может платить (R3: достаточно одного из verified).  
2. Карта one_click: карта принадлежит customer; без чужих RebillId.  
3. Callcheck/SMS linker (#89) — session customer + phone_verified.  
4. Post-pay email (#71/#91) — не требует email до Pay.  
5. Amount limits / closed shop / simulate guards — без изменений.

## 7. Матрица приёмки B1–B5 ↔ тесты

Блок B закрыт только если **все** T-B* PASS.

### B1 — Канон зафиксирован

| ID | Как проверить | Assert |
|----|---------------|--------|
| **T-B1** | В todo/SPEC + комментарий в сервисе identity (одна точка правды) | Документ R1–R5 = код; нет второго скрытого require email в pay path |

(Отдельный unit не обязателен; закрывается T-B2* + T-B5*.)

### B2 — Одна политика на все pay-сервисы

| ID | Тест (имя) | Arrange | Assert |
|----|------------|---------|--------|
| **T-B2a** | `OrderCreator allows phone_verified customer without email` | session → MobileCustomer `phone_verified`, email nil; cart ok; `OrderCreator#call!` без email / blank email | **нет** Error «Укажите/Подтвердите email»; order создан, `customer_id` = session customer |
| **T-B2b** | `OrderCreator still allows email_verified without phone` | email verified session/OTP; phone нет | order создан |
| **T-B2c** | `OrderCreator rejects when neither phone nor email verified` | guest без verified | Error / 422; order **не** создан |
| **T-B2d** | `RecurrentOrderCreator / one_click phone_verified without email` | phone customer + saved card того же customer; one_click params без email | не 422 email; charge path доходит до adapter (stub T‑Bank) или явный gateway error ≠ identity |
| **T-B2e** | `new_card path phone_verified without email` | integration POST new_card (simulate или stub Init) | не 422 email |
| **T-B2f** | `SBP order create phone_verified without email` | POST `/orders` payment_method sbp **или** sbp_init после create | не 422 email |

Файлы: `order_creator_test.rb`, `recurrent_order_creator_test.rb`, integration `payments_*` / `orders_*`.

### B3 — Checkout.svelte согласован с R1

| ID | Тест | Assert |
|----|------|--------|
| **T-B3a** | (если есть JS/vitest) `identityReady follows phoneVerified` **или** | `identityReady` ≡ «можно платить по канону»; при phone-first **не** требует `emailVerified` для `canPay`/`sheetCanPay` |
| **T-B3b** | Pay payload | при phone-only не шлёт фейковый `emailVerified: true` в профиль как замену серверной проверки; email в body может быть `""` — сервер принимает (T-B2a) |
| **T-B3c** | Нет Pay без identity | `!phoneVerified && !emailVerified` → `canPay` false |

Если JS-тестов нет — **обязательный** integration + ручной чеклист в REVIEW, плюс assert в Svelte через существующий test harness **или** контрактный тест API + code review gate что `identityReady` не расходится с R1. Минимум для DoD: **T-B3c** отражён в UI-коде (grep/assert в review) + T-B5 покрывает сервер; лучше добавить маленький unit на derived, если в проекте уже есть frontend test runner.

Практичный DoD без нового фронт-раннера: в GREEN в отчёте цитата `identityReady` после правки + T-B5a с реального POST как UI.

### B4 — Карты / SBP list при phone-only

| ID | Тест | Assert |
|----|------|--------|
| **T-B4a** | `GET /user/cards` with phone session customer, no email | 200; `cards`/`sbp_accounts` массивы (можно пустые); **не** 401/422 email |
| **T-B4b** | Checkout `loadSavedCards` при phone-only | не очищает карты из-за отсутствия email query; запрос без обязательного `?email=` работает (сервер по session) |

Файл: integration `user_cards` + при необходимости правка `Checkout.svelte` `loadSavedCards` (сейчас q только если email verified — это ок, если session cid есть).

### B5 — Интеграционный пакет (главный DoD)

| ID | Тест | Assert |
|----|------|--------|
| **T-B5a** | phone verified → `POST /orders` (и/или new_card) | 2xx / успешный JSON order; **не** тело с «Подтвердите email» |
| **T-B5b** | email verified path (без phone) → create order | 2xx |
| **T-B5c** | no identity → create order | 422; сообщение про подтверждение телефона **или** email (не только email, если phone-first) |
| **T-B5d** | phone verified → one_click с чужой картой | 422 ownership (регресс безопасности) |
| **T-B5e** | phone verified → one_click со своей картой | не identity 422 |

Желательно один файл:  
`test/integration/shop/api/checkout_identity_test.rb`

## 8. Команды проверки

```bash
bin/rails test \
  test/services/shop/order_creator_test.rb \
  test/services/shop/recurrent_order_creator_test.rb \
  test/integration/shop/api/checkout_identity_test.rb \
  test/integration/shop/api/email_otp_checkout_test.rb \
  test/integration/shop/shop_one_click_payment_step4_test.rb
# + фактические пути payments/cards из SPEC
```

Регресс зоны:

```bash
bin/rails test test/services/shop/order_creator_test.rb \
  test/integration/shop/api/ \
  test/integration/shop/shop_one_click_payment_step4_test.rb \
  test/integration/shop/shop_new_card_payment_step2_test.rb
```

## 9. Definition of Done — Блок B

- [ ] B1: в SPEC/todo явно **phone-first** (или смена на email-gate до RED — не после)
- [ ] T-B2a…f PASS  
- [ ] T-B3* согласованы (код UI = R1)  
- [ ] T-B4a/b PASS  
- [ ] T-B5a…e PASS  
- [ ] Нет 422 «Подтвердите email» при `phone_verified` на orders/new_card/one_click/SBP create  
- [ ] Без identity — по-прежнему отказ  
- [ ] `/regress` зоны shop orders/payments PASS  
- [ ] REVIEW-таблица B1–B5 \| тест ID \| PASS  
- [ ] Deploy не входит (TASK_93-L)

## 10. SBR-цикл для 93-B

| Фаза | Что |
|------|-----|
| `/start` | в док TASK_93 добавить секцию **Блок B** (или `TASK-93-B-…md` EXT); CBR `#93` статус Block B; artifacts `critical_path_hardening/` |
| `/spec` | todo: файлы + Не ломать + Проверка + чеклист B1–B5; **зафиксировать phone-first** |
| `/sbr` RED | T-B2a, T-B2c, T-B5a, T-B5c обязаны быть красными на текущем HEAD |
| `/sbr` GREEN | одна identity-проверка (сервис/concern) + Checkout sync |
| `/regress` | §8 |
| `/review` | таблица PASS; push; **без deploy** |

Ожидаемый RED на текущем коде: **T-B2a / T-B5a** (phone without email → сейчас Error).

## 11. Таблица закрытия (вставить в REVIEW)

```
B1 канон phone-first     PASS (SPEC + код)
B2 T-B2a..f              PASS
B3 UI identityReady      PASS
B4 T-B4a T-B4b           PASS
B5 T-B5a..e              PASS
```

Без этой таблицы блок B не закрыт.

---

## Связь с блоком A

- A чинит «деньги есть — заказа нет».  
- B чинит «UI пустил Pay — сервер 422».  
Порядок: **A → B**. После B демо-оплата phone-first доходит до webhook; склад уже не откатывает (если A закрыт).

---

Ask mode: файлы не пишу. Дальше в Agent: `/start` с текстом **TASK_93-A** и/или **TASK_93-B**, либо оба секциями в одном `TASK-93-…md`.
