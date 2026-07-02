# B1.13-S2 — макеты заказчика (иллюстрации)

**Канон раскладки, жестов и порогов:** [`B1_13_shop_nav_profile_header.md`](../../requirements/customer_tasks/B1_13_shop_nav_profile_header.md) § **B1.13-S2-канон** — единственный источник истины.

JSON: [`../b113_s2_screenshot_baseline_2026-06-22.json`](../b113_s2_screenshot_baseline_2026-06-22.json)

**Скрины на диске (4 шт.):**

| # | Файл | Назначение |
|---|------|------------|
| 1 | `b113_s2_customer_01_empty_catalog_and_add.png` | Пустой каталог + add |
| 2 | `b113_s2_customer_02_single_item_popup.png` | 1 товар в поп-апе |
| 3 | `b113_s2_customer_03_peek_compact_vs_expanded.png` | Два кадра поп-апа |
| 4 | `b113_s2_customer_04_expanded_swipe_up.png` | Multi + свайп |

Макеты — **визуальный референс заказчика**, не переопределяют § S2-канон.

## Высоты (ориентир для `cartSheetThresholds.js`)

| Режим | vh |
|-------|-----|
| empty | 12 |
| peek (1 товар) | 28 |
| peek (2+) | 30 |
| expanded (2+) | 44 |
| hidden (чип) | 20 |

## Раскладка 2+ (build prog20)

| Режим | UI | vh | `data-cart-layout` | testid |
|-------|-----|-----|-------------------|--------|
| **peek** | горизонтальный ряд 28vw, scroll 3–4+ | 30 | `horizontal` | `shop-cart-peek-list` |
| **expanded** | вертикальный список + «Удалить», scroll >3 | 44 | `vertical` | `shop-cart-expanded-horizontal` |
| **hidden** | чип | 20 | — | `shop-cart-hidden-chip` |

Имена testid исторические — приёмка по **`data-cart-layout`** и § S2-канон.

**Уточнения (2026-07-01):** после add → **peek**; свайп **hidden→peek→expanded** (по одному шагу); пустая корзина — цель скрыт (Q-rev2); 1 товар + скролл каталога 100px → hidden.

## Bottom bar (канон эпика)

| | Целевое |
|---|---------|
| Вкладки | **Каталог + Избранное** |
| Профиль | только в шапке (S1) |
| Корзина | поп-ап на каталоге, не `#/cart` |
