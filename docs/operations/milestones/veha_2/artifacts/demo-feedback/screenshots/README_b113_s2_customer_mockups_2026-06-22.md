# B1.13-S2 — макеты заказчика (поп-ап корзины)

**Задача:** поп-ап 3 состояния · bottom bar **Каталог + Избранное** (2 вкладки) · профиль в шапке (S1) · скролл каталога.

JSON: [`../b113_s2_screenshot_baseline_2026-06-22.json`](../b113_s2_screenshot_baseline_2026-06-22.json) · ответы S2: [`B1_13_shop_nav_profile_header.md`](../../requirements/customer_tasks/B1_13_shop_nav_profile_header.md) § Ответы S2.

**Скрины на диске (4 шт.):**

| # | Файл | Состояние |
|---|------|-----------|
| 1 | `b113_s2_customer_01_empty_catalog_and_add.png` | Плейсхолдер «тут будут твои заказы» + add |
| 2 | `b113_s2_customer_02_single_item_popup.png` | Expanded · 1 товар (~40% экрана) |
| 3 | `b113_s2_customer_03_peek_compact_vs_expanded.png` | Expanded (~36%) ↔ peek (~16%) |
| 4 | `b113_s2_customer_04_expanded_swipe_up.png` | Expanded multi · свайп вверх |

## Пропорции (канон 2026-06-24)

| Состояние | % высоты экрана |
|-----------|-----------------|
| empty | ~12% |
| expanded (1) | ~40% |
| expanded (3+) vertical | ~36% |
| expanded (3+) horizontal | ~42% |
| peek | ~16% |
| hidden (головки) | ~9% |

## Жесты drag-handle (канон прогон 5 — см. B1_13 § S2-prog5)

**1 товар:** expanded (horizontal) ⇄ hidden (головка). Peek нет. Свайп ↑ в expanded — noop.

**2+ товара:** hidden →↑ vertical →↑ horizontal; horizontal →↓ vertical →↓ hidden. Peek — только скролл каталога 100px.

Скролл каталога: **1 товар** 100px → hidden; **2+** 100px → peek, 200px → hidden.

## Сейчас в коде vs макет

| | **Сейчас** | **Макет / S2** |
|---|------------|----------------|
| Низ | 4 вкладки + `#/cart` | 2 вкладки + поп-ап над баром |
| Пусто | — | «тут будут твои заказы» |
| Профиль | шапка (S1) | шапка, не в баре |
