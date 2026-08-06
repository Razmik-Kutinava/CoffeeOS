# todo — #44 Product card peek cart (одна шторка, без наложений)

**ТЗ:** [`Карточка товара отображение…`](../milestones/veha_2/requirements/customer_tasks/Карточка%20товара%20отображение%20набранных%20позиций%20и%20функциональность%20в%20режиме%20peek.md)  
**Артефакты:** [`artifacts/product_card_peek_cart/`](../milestones/veha_2/artifacts/product_card_peek_cart/)

## Канон layout (SPEC 2026-08-06)

| Режим | Что внутри **одной** `CartSheet` (стыки, не слои) |
|-------|---------------------------------------------------|
| **peek** | gesture → status → CTA «добавить к заказу» → «уже в заказе» (гориз. ±1 + scroll) → checkout |
| **expanded** | gesture → status → CTA → вертикальный список ± → checkout |
| **hidden** | gesture → status → CTA (компакт) → чипы → checkout |
| **empty** | gesture → status → CTA → placeholder / repeat |

**Запрещено:** второй fixed `ProductCartPeek` + fixed `.bottom-bar` с `bottom: 140px` поверх шторки.

| # | Шаг | Статус |
|---|-----|--------|
| 1 | PHASE 0 intake reopen | `[x]` |
| 2 | PHASE 1 SPEC (этот todo + канон стыков) | `[x]` |
| 3 | RED: тест «один fixed sheet / нет bottom-bar--peek» | `[ ]` |
| 4 | GREEN: CTA в шторке + alias peek testids + убрать дубль | `[ ]` |
| 5 | Обновить product_card_s* под CartSheet | `[ ]` |
| 6 | Регрессия `test/integration/shop/` | `[ ]` |
| 7 | REVIEW: CHANGELOG / HANDOFF / CBR | `[ ]` |
