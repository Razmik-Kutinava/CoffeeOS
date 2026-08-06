# MCP RESULT — #43 Repeat hidden by stale active orders · Fly **v434** · 2026-08-06

**App:** https://coffeeos.fly.dev  
**Release:** **v434** · image `coffeeos:deployment-01KZAVCVTD37NBM7CK9M7MFMFK`  
**Tip:** `c9c5aacd` (push develop)  
**Tenant:** Point A `2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** Aram `2bc37279-…4c` · reconnect + bust frequent cache  
**Вердикт:** **PASS**

## Deploy

1. Push `056bb005..c9c5aacd` (intake + feat TTL + ISSUES)
2. `fly deploy -a coffeeos --remote-only --depot=false` → **v434**
3. `/up` **200**

## Server (fly rails runner)

После `bust_cache!` для Aram:

| Метрика | Значение |
|---------|----------|
| `has_active_order` | **false** |
| `frequent_items` | **3** |
| Names | Декаф Гватемала · Бразилия · Бразилия |

## API live

| Вызов | Результат |
|-------|-----------|
| `POST /session/reconnect` | **200** ok |
| `GET /frequent_products` | **200** `has_active_order:false` · **3** items |

## DOM (Cursor IDE browser)

После reload с кэшем frequent:

| Критерий | Результат |
|----------|-----------|
| Секция «повторить» | **есть** |
| Кнопки «оплатить в 1 клик» | **3** |
| Карточки | Декаф / Бразилия / Бразилия |
| Профиль header | `2bc3…4c` |

## Gaps

- Stale `localStorage` `coffeeos_shop_frequent_v1` с `has_active_order:true` на устройстве Арама — hard refresh или очистка кэша; после reload API отдаёт false.
- Catalog home cards без «+» — by design (tap → product); кнопки повтора — в шторке.

## Следующее

Апрув заказчика «ок»; Араму — hard refresh PWA.
