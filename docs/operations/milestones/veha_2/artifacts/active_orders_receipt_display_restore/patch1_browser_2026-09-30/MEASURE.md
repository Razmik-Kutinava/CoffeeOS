# Патч 1 — доказательство причины (браузер, 2026-09-30)

**Стенд:** local dev `http://localhost:3001/shop?tenant_id=8c7f5bc7-f2b4-43f0-991c-5ede0f480b20` (Demo Coffee Point A, local DB) · viewport 390×844 mobile · корзина пустая.
**Данные:** ответ `GET /shop/api/orders/active` подменён в браузере (формат `ActiveOrdersPresenter`: 2 заказа, у первого 3 позиции) — эндпоинт требует phone-auth сессию. Фронт, CSS и клик — настоящие.
**Путь:** клик «Состав заказа» у первого заказа → `aria-expanded=true`.

## Замер (`getBoundingClientRect`)

| Элемент | top | bottom | height | overflow-y | max-height | scrollHeight |
|---|---|---|---|---|---|---|
| `.aoa__receipt` | 783 | 979 | 196 | auto | 350px | 194 |
| `.oss__panel.embedded.expanded` | 638 | 862 | 224 | auto | 224px | 498 |
| `.cart-sheet` (fixed) | 557 | 844 | 287 | hidden | — | 393 |

**Видимая часть чека: 61px из 196px** (первая позиция; `Total Amount` не виден).

## Вывод

1. Чек **есть в DOM** и рендерится (подтверждает SSR-тесты `ba1ed0e6`).
2. Причина исчезновения — **обрезание**, двумя контейнерами:
   - `.oss__panel.embedded.expanded` `max-height: min(36vh, 14rem)` = 224px (`OrderStatusSheet.svelte:348–350`); чек начинается на 145px ниже верха панели (шапка строки: прогресс + `OrderActionButtons` 2×44px + CTA);
   - `CartSheet` `overflow: hidden`, высота 287px (peek, пустая корзина) — дополнительно режет низ панели (862 > 844).
3. Subtask 11 нарушен: вместо собственного scroll чека прокручивается внешняя `.oss__panel` (scrollHeight 498 > 224).
4. Одной правки `OrderStatusSheet.svelte:344–350` недостаточно: даже без лимита панели её режет `CartSheet` (высота — `CartSheet.svelte:108–127`, `cartSheetThresholds.js`, вне scope патча).

Скрин: [`receipt_clipped_390x844.png`](receipt_clipped_390x844.png)
