# B1.7 BR-5 — регрессия «второй товар в корзину» (2026-06-04)

**Задача:** [B1_7_checkout_order_screen.md](../../requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-5 регрессия — **CLOSED** · апрув заказчика **2026-06-18**

**Стенд:** `https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3`

## Скрины

| Файл | Когда |
|------|--------|
| `b17_br5_regression_before_p2_add_2026-06-04.png` | repro: Товар 1 в корзине, add Товара 2 — нет баннера / stale DOM |
| `b17_br5_regression_after_p1_2026-06-04.png` | после первого add |
| `b17_br5_regression_after_2026-06-04.png` | post-fix: `#/cart`, оба товара, баннер «добавлен» |

**Прогоны (post-deploy PASS):**
- `node bin/acceptance/b17_br5_cart_second_product_mcp.mjs` — 7/7
- `node bin/acceptance/b17_br5_catalog_card_flow_mcp.mjs` — 5/5
- `node bin/acceptance/b17_br5_quick_add_category_mcp.mjs`

**Артефакт:** [b17_br5_regression_post_deploy_2026-06-04.json](../b17_br5_regression_post_deploy_2026-06-04.json) · апрув: [b17_br5_customer_approval_2026-06-18.json](../b17_br5_customer_approval_2026-06-18.json)
