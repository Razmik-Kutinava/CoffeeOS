# MCP RESULT — #35 rev Order status compact sheet · Fly **v432** · 2026-08-05

**App:** https://coffeeos.fly.dev  
**Release:** **v432** · image `coffeeos:deployment-01KZ8W88G4HC0YK291M3FM011G`  
**Tip:** `38df5088` (push develop)  
**Tenant:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** Chrome DevTools MCP · guest profile `2bc3…4c`  
**Вердикт:** **PASS** (home + product + scroll >2) · ready→hide live smoke **PARTIAL** (не гоняли бариста→ready)

## Deploy

1. `git push origin develop` — `8ffabc86..38df5088` (11 commits #35 rev)
2. `fly deploy -a coffeeos --remote-only --depot=false` → **v432**
3. HTTP `/up` **200** · `/shop?tenant_id=…` **200**

## DOM live (evaluate_script)

### Home `#/`

| Метрика | Значение |
|---------|----------|
| `data-testid="shop-order-status-sheet"` | **true** |
| `data-status-sheet-mode` | `peek` |
| `data-status-embedded` | `true` |
| Active rows (progress buttons) | **6** (>2) |
| `.oss__panel.scrollable` | **true** |
| `.oss__scroll-hint` | **true** |
| `max-height` / `overflow-y` | `256px` / `auto` |
| Labels | Принят / Оплачен / Готовится / Готов |
| Orders in sheet | `#202608-0005`, `#202606-0259`, `#202606-0257`, `#202606-0094`, `#202606-0085`, `#202606-0084` |
| Cancel CTA count | **6** (все `accepted`/`can_cancel` — **не** `ready`) |
| Cable banner | «Потеряно соединение…» (много подписок, known) |

### Product `#/product/1eea0762-dded-4d03-adb8-d2027232126a` (Кофе-тоник)

| Метрика | Значение |
|---------|----------|
| Title | Кофе-тоник |
| Status sheet on product | **true** · peek · embedded |
| Progress rows | **6** · scrollable + scroll-hint |
| «добавить к заказу» | **true** (можно заказать ещё) |
| Cart peek coexistence | cart lines + status sheet |

## Сверка со скринами заказчика (`screenshots/01–05`)

| Критерий | Эталон | Fly MCP v432 | Вердикт |
|---|---|---|---|
| Sticky на главной | 01 | sheet embedded в CartSheet, peek | **PASS** |
| Карточка товара + статус | 02–03 | sheet на `#/product/…` + add CTA | **PASS** |
| Multi-order scroll >2 | 04–05 | 6 rows, scrollable, hint | **PASS** |
| Нет виджета для `ready` | ТЗ | в sheet только cancelable accepted; ready не в списке | **PASS** (косвенно) |
| Бариста → ready → исчез + push | smoke | не прогоняли POS→ready на live | **PARTIAL** |

## Gaps / notes

- Много «зависших» accepted на Point A → шторка длинная + cable «Потеряно соединение…» (как на v414/v429).
- `GET /orders/active` из `fetch` в DevTools evaluate вернул 401 (cookie/CSRF path); UI sheet наполнен через app `api.js` — OK.
- Live smoke hide-on-ready + ReadyPushJob copy — backlog до прогона бариста panel / MCP follow-up.
- Chrome DevTools `take_screenshot` с `filePath` в artifacts — Access denied MCP; evidence = DOM metrics + session screenshots в чате.

## Следующее

- Апрув заказчика на визуал #35 rev **или** follow-up MCP: barista → `ready` → sheet hide + push.
