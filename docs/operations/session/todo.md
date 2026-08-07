# todo — #26 Repeat order invalid token · PaymentMethodsSheet (SPEC 2026-08-07 + live)

**ТЗ:** [`customer_tasks/Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md`](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md)  
**Артефакты:** [`repeat_order_invalid_token_payment_sheet/`](../milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/) · скрины `01`–`08`  
**Стек:** Svelte · `PaymentMethodsSheet` + `CheckoutPayButton` + `Checkout.svelte`  
**Ограничения ТЗ:** не трогать auth store / refresh; не `legacy/ui`; не новый BottomSheet-менеджер

---

## P0 — Live фидбек заказчика (2026-08-07)

**Дословно:** на карте нет суммы → оплата *5953 → должен открыться вариант сменить карту / форма новой карты → **не открывается**, только текст «не хватает денег»; в исходном макете сценария не было.

| Given | When | Then (ожидание = скрин **05**) | As-is (скрины **04/07/08**) |
|---|---|---|---|
| Карта *5953 без средств (банк: 159,33 ₽) | Пользователь жмёт оплатить | После отказа: inline «Недостаточно средств…» **и** открыта форма «Картой +» (NewCardForm) **или** тап по «Отказ: смените карту» открывает её | Inline + красная CTA «Отказ: смените карту»; *5953 остаётся selected; форма **закрыта** |

### Root cause

`CheckoutPayButton` при `PAY_FSM.CLIENT_ERROR` вызывает **`onPay()`** (повтор charge той же карты), а не `onSelectNewCard()`.  
Текст кнопки обещает «смените карту», поведение — «попробуйте снова той же».

Файлы: `CheckoutPayButton.svelte` · `Checkout.svelte` (`onSelectNewCard` уже есть) · `shopPayFsm.js` (`CLIENT_ERROR` / код `1051` insufficient funds).

---

## Маппинг ТЗ → CoffeeOS

| ТЗ / фидбек | Канон CoffeeOS |
|---|---|
| `PaymentMethodBottomSheet` | `PaymentMethodsSheet.svelte` |
| `isTokenInvalid` | RebillId · `repeatInvalidTokenStore.js` (не auth JWT) |
| «смените карту» / insufficient funds | FSM `CLIENT_ERROR` + `sheetInlineError` → **должен** вести в `selectionMode=new_card` |
| Макет UI | скрин **03** |
| Ожидание после отказа | скрин **05** |

---

## Канон UI

### Макет (скрин 03) — визуал списка

| Элемент | Канон |
|---|---|
| Карта | `Картой *XXXX`, «Картой» orange, рамка selected |
| СБП | disabled / серый + toast `sbpUnavailable()` |
| «Картой +» | `+` справа (не ⌄), оранжевая рамка |
| Idle CTA | оранжевая «Оплатить» |

### После отказа банка (скрины 04→05) — поведение

| Элемент | Канон |
|---|---|
| Inline | «Недостаточно средств на карте» (оставить) |
| CTA / действие | **Открыть NewCardForm** (как 05): `selectionMode=new_card`, сброс FSM → DEFAULT, CTA снова «Оплатить» |
| Не делать | Повторный charge той же карты по тапу «Отказ: смените карту» |

---

## Gaps

| # | Тема | Приоритет | Статус |
|---|---|---|---|
| **G7** | `CLIENT_ERROR` / «Отказ: смените карту» → `onSelectNewCard()` (+ опционально auto при входе в CLIENT_ERROR) | **P0 блокер заказчика** | `[ ]` RED написан · ждут GREEN |
| G1 | Лейбл `Картой *XXXX` vs MIR **** | MUST (макет 03) | `[ ]` |
| G2 | Оранжевый idle Pay | MUST (макет 03) | `[ ]` |
| G3 | «Картой +» без шеврона | MUST (макет 03) | `[ ]` |
| G4 | СБП disabled (конфликт #27) | MUST · Decision D1 | `[ ]` |
| G5/G6 | i18n + тесты под канон | с GREEN | `[ ]` |
| B1–B6 | Peek CTA / sheet / NewCard tap / errors / persist | baseline `[x]` | — |

---

## Decisions

### D4 — G7: когда открывать форму (апрув по умолчанию)

**A (рекомендуем):** тап по CTA в `CLIENT_ERROR` → `onSelectNewCard()` (не `onPay`).  
**B (строже):** при переходе в `CLIENT_ERROR` сразу auto-open NewCardForm (скрин 05 без второго тапа).  
**C:** оба — auto-open + тап по CTA тоже ведёт в new_card.

→ **По умолчанию: D4 = C** (auto при CLIENT_ERROR insufficient/card decline + тап CTA не ретраит ту же карту).

### D1–D3 — визуал макета 03

- D1 СБП disabled · D2 `Картой *XXXX` · D3 оранжевый Pay в sheet — как в SPEC ранее; **после G7** или тем же GREEN-пакетом по апруву.

---

## План BUILD

### RED (сначала G7)

1. Тест: при `CLIENT_ERROR` (insufficient / code 1051) вызов CTA **не** ретраит pay; переключает `selectionMode` → `new_card` / виден NewCardForm.  
2. Тест: auto-open при входе в CLIENT_ERROR (если D4=C).  
3. Коммит `test: … [RED]`

### GREEN

1. `CheckoutPayButton`: `CLIENT_ERROR` → `onChangeCard` / `onRetry`≠pay (новый колбэк)  
2. `Checkout.svelte`: колбэк = `onSelectNewCard` (+ auto при set CLIENT_ERROR)  
3. G1–G4 по апруву (можно вторым коммитом)  
4. Регрессия: `repeat_invalid_token_payment_test` + JS + shop pay FSM  
5. Коммит `feat: … [GREEN]`

### REVIEW / MCP

- Сценарий *5953 insufficient → форма как 05  
- Push/deploy — только по просьбе

---

## Чеклист

| # | Суть | Статус |
|---|---|---|
| 1–6 | Шаги исходного ТЗ (peek/sheet/select/add/errors/close) | baseline + G1–G4 |
| **7** | **Live:** insufficient funds → смена карты / NewCardForm | **G7 `[ ]` P0** |

---

## Exit Criteria

1. G7: после отказа *5953* форма новой карты открывается (скрин 05) — тест зелёный  
2. Тап «Отказ: смените карту» не крутит повторный charge той же карты  
3. (Опционально в том же / следующем шаге) визуал G1–G4 = скрин 03  
4. MCP на Fly — по явной просьбе

---

## Порядок

1. SPEC дополнен (этот файл) — **стоп до апрува на RED**, если владелец хочет править D4  
2. RED G7 → GREEN G7 → (G1–G4) → REVIEW  
3. Push/MCP — только по просьбе
