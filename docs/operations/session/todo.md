# todo — Чувствительность свайпа шторки (hit area)

> **ТЗ:** [`customer_tasks/Чувствительность свайпа шторки hit area прямоугольник.md`](../milestones/veha_2/requirements/customer_tasks/Чувствительность%20свайпа%20шторки%20hit%20area%20прямоугольник.md)  
> **Артефакты:** [`artifacts/cart_sheet_gesture_hit_area/`](../milestones/veha_2/artifacts/cart_sheet_gesture_hit_area/README.md)

## Текущая фаза

**PHASE 2: BUILD** (после intake `d5fec5e`) — «ебашь»

### SPEC
- [x] Жалоба: свайп должен чутко реагировать на **весь прямоугольник** полосы (обведена на скрине), не только на «крючок»
- [x] План: увеличить hit-area `shop-cart-sheet-gesture-zone` (`min-h-14`→`min-h-20`); снизить `SWIPE_UP_PX` 32→20; `CART_SHEET_BUILD=prog29`; жест **не** на контент карточек
- [x] Риски: ложные свайпы при тапе по полосе; конфликт со скроллом — зона только полоса

### BUILD
- [x] RED: тест hit-area + порог — `ac69ca4`
- [x] GREEN: `min-h-20` · `SWIPE_UP_PX=20` · `prog29` · регрессия sheet 45/0
- [ ] REVIEW: MCP после deploy владельца · «ок» заказчика

### REVIEW checklist
- [x] Код + тесты зелёные
- [ ] Redeploy Fly + MCP (prog29 в DOM)
- [ ] Вторая правка заказчика — ждёт текста
