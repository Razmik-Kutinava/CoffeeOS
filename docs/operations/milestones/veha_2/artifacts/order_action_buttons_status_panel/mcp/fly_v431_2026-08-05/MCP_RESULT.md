# MCP RESULT — #41 Cancel CTA · Fly v431 · 2026-08-05

**App:** https://coffeeos.fly.dev  
**Release:** **v431** · image `coffeeos:deployment-01KZ8J3QC9JAKDRAZZMG16K6KP`  
**Tenant:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** Aram (`2bc37279-…`) · Chrome DevTools MCP  
**Вердикт:** **PASS** (cancel CTA + accepted Confirm Sheet)

## Подготовка данных

- Заказ `#202608-0005` (`b531caa3-eba2-42e2-a641-e6c00ae8729b`) → `accepted` + `guest_can_cancel?=true` (rails runner на web machine).
- **Фикс v431:** `ActiveOrdersPresenter` + `GuestOrderBroadcaster` отдают `can_cancel` (без поля sticky CTA не показывал cancel).

## DOM (live)

| Метрика | Значение |
|---------|----------|
| `data-testid="order-action-buttons"` | **17** roots |
| `data-testid="order-action-btn"` | **34** buttons |
| Cancel CTA `#202608-0005` | kind **cancel** · label «Отменить заказ» · hint «Вернем 100% суммы» |
| `backgroundColor` cancel | `rgb(255, 107, 53)` = `#ff6b35` |
| `height` / `min-height` | **44px** |
| GET `/shop/api/orders/active` | `#202608-0005` → `status: accepted`, `can_cancel: true` |

## Modal (accepted refund copy #40)

| Поле | Значение |
|------|----------|
| Title | «Отменить заказ №#202608-0005?» |
| Body | «Вернём 179 ₽ на карту. Обычно деньги приходят за 1–3 дня.» |
| Confirm | «Да, отменить и вернуть 179 ₽» |
| Dismiss | «Оставить заказ» (нажато — заказ **не** отменён) |

## Deploy chain

1. `feat`: `can_cancel` в `orders/active` + cable payload  
2. `fly deploy` → **v431**  
3. MCP DevTools: sticky cancel CTA → Confirm Sheet

## Связь с v429

Chat+push evidence: [`../fly_v429_2026-08-05/`](../fly_v429_2026-08-05/)  
Cancel gap v429 закрыт на **v431**.
