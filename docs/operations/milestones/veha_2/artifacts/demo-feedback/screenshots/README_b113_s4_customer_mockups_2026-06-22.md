# B1.13-S4 — макеты: модификаторы + горизонтальный скролл

**Канон:** [`B1_13_shop_nav_profile_header.md`](../../requirements/customer_tasks/B1_13_shop_nav_profile_header.md) § **B1.13-S4-канон** + § **S2-канон**.

JSON: [`../b113_s4_screenshot_baseline_2026-06-22.json`](../b113_s4_screenshot_baseline_2026-06-22.json)

| # | Файл | Что (S4) |
|---|------|----------|
| 1 | `b113_s4_customer_horizontal_scroll_peek.png` | **4+ товара** — горизонтальный скролл в **peek** |
| 2 | `b113_s4_customer_horizontal_thumbnails_chip.png` | Иллюстрация ряда миниатюр + **+цена** |
| 3 | `b113_s4_customer_expanded_modifiers_list.png` | vertical list **expanded** (tap → Product для edit) |

**Суть S4 (канон 2026-07-01, уточнения 0b):**

- **В поп-апе** — только ±qty; модификаторы **не** редактируем inline.
- **Tap** — **вся карточка** в peek (1+ и 2+) и expanded; блок **− / +** только для количества.
- Tap → **Product** → «В корзину» → **PATCH** update строки (не add).
- При совпадении комбинации модификаторов — **склеить** qty с существующей строкой.
- **Не tap** для hidden→peek / peek→expanded — только **свайп** (§ S2-канон).
- **Long press — не используем.**
- Скролл карточек — **peek** 4+; индикаторы — S4.
