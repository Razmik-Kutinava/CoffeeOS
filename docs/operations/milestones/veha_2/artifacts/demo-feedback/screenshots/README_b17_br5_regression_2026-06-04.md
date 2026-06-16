# B1.7 BR-5 — регрессия «второй товар в корзину» (2026-06-04)

**Задача:** [B1_7_checkout_order_screen.md](../../requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-5 регрессия

**Стенд:** `https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3`

## Скрины (положить после repro / fix)

| Файл | Когда |
|------|--------|
| `b17_br5_regression_before_2026-06-04.png` | repro: Товар 1 в корзине, add Товара 2 — нет перехода / индикации |
| `b17_br5_regression_after_2026-06-04.png` | post-fix: `#/cart`, оба товара, баннер «добавлен» |

**Прогон:** `node bin/b17_br5_cart_second_product_mcp.mjs`
