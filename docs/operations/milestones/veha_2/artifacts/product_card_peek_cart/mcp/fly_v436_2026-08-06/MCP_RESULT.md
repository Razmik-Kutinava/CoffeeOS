# MCP Fly v436 — #44 Product card single sheet

**Дата:** 2026-08-06  
**Fly:** **v436** · `deployment-01KZB42C5176Y6MH07YGFSD0YF`  
**Commit:** `7f7973e1`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Product:** `#/product/d4ff4994-a212-4bfb-8cfb-b6c120f86ced` (Фильтр-кофе Бразилия, линия в корзине)

## Результат: **PASS**

| Check | Result |
|-------|--------|
| `data-cart-sheet-build` | `prog37` |
| Fixed footer | только `shop-cart-sheet` |
| Нет `.product-cart-peek` / `.bottom-bar--peek` | да |
| CTA «добавить к заказу» внутри шторки | да (`shop-product-sheet-cta`) |
| Индикатор | `уже в заказе: 2` |
| Peek aliases ± / list | да |
| ± bump | 2→3, total +358₽→+537₽ |
| Режим | `peek`, `--cart-sheet-h: 48vh` |

## Швы внутри одной шторки

`gesture` → `order-status` → `product-sheet-cta` → `product-peek-list` → cart line → checkout

## Notes

- Высокая картинка товара уходит под шторку (нормальный scroll under fixed sheet).
- При активном заказе + «Потеряно соединение…» шторка плотная, но без второго fixed-слоя.
