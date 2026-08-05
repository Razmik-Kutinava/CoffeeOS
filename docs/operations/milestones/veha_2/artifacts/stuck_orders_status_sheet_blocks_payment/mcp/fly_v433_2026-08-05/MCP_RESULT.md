# MCP RESULT — #42 Stuck orders status sheet blocks payment · Fly **v433** · 2026-08-05

**App:** https://coffeeos.fly.dev  
**Release:** **v433** · image `coffeeos:deployment-01KZ9913PP55V099F8Y6JQCK5V`  
**Tip:** `ec1e6a65` (push develop)  
**Tenant:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** Cursor IDE browser · Aram `2bc37279-…4c` via `POST /shop/api/session/reconnect` на `#202606-0259`  
**Вердикт:** **PASS**

## Deploy

1. `git push origin develop` — `4481d20b..ec1e6a65` (#42 intake + TTL/peek)
2. `fly deploy -a coffeeos --remote-only --depot=false` → **v433**
3. HTTP `/up` **200** · `/shop?tenant_id=…` **200**

## Server (fly ssh rails runner)

Aram Point A, statuses `accepted`/`preparing` (как `#active`):

| Метрика | Значение |
|---------|----------|
| Всего «sheet-eligible» без TTL | **5** |
| Sample | `#202606-0259` … `#202606-0084` (июнь 2026) |
| `created_at >= 24h.ago` | **0** |
| June внутри окна | **0** |

→ TTL отрезает все зависшие June-заказы.

## API live (после reconnect)

| Вызов | Результат |
|-------|-----------|
| `POST /shop/api/session/reconnect` | **200** `ok` · customer `2bc37279-…` |
| `GET /shop/api/orders/active` | **200** `{"orders":[]}` |

## DOM / UI

| Критерий | Результат |
|----------|-----------|
| `data-testid="shop-order-status-sheet"` | **absent** |
| `#202606-*` в DOM | **[]** |
| CSS `min(22vh, 8.5rem)` в assets | **true** |
| CTA оплаты `+3₽` (cart peek) | **visible** · не перекрыт статусной шторкой |
| Профиль | `2bc3…4c` · адрес Ленин 10 |

## Gaps / notes

- Chrome DevTools MCP (`user-chrome-devtools`) был в `error` — прогон через `cursor-ide-browser`.
- Backlog без изменений: SM filter NULL-shift; payment-row `processing` vs order `accepted`.

## Следующее

- Апрув заказчика «ок» на #42; Арам может снова тестировать оплату на Fly.
