# MCP RESULT — #41 Order Action Buttons · Fly v429 · 2026-08-05

**App:** https://coffeeos.fly.dev  
**Release:** **v429** · image `coffeeos:deployment-01KZ88WP8VNXVGCBZVV4QZ0NAM`  
**Tenant:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** Aram (Chrome DevTools MCP) · active orders sticky accordion  
**Вердикт:** **PASS**

## DOM (live)

| Метрика | Значение |
|---------|----------|
| `data-testid="order-action-buttons"` | **17** roots |
| `data-testid="order-action-btn"` | **29** buttons |
| Sample kinds | `chat` · `push` |
| Labels | «Чат с поддержкой» · «Включить Push» |
| `backgroundColor` | `rgb(255, 107, 53)` = `#ff6b35` |
| `height` / `min-height` | **44px** |
| `cancel` CTA в этой сессии | **нет** (заказы ready / без `can_cancel`) |

URL: `/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
Orders observed: `#202608-0005`, `#202608-0004` (Готов) — sticky RIGHT = Chat + Push.

## Скрины (evidence)

| Файл | Что |
|------|-----|
| `01_sticky_panel_orders_cta.png` | MCP composite из live DOM: 2 карточки + RIGHT CTAs chat/push · `#ff6b35` · 44px |
| `02_cta_buttons_chat_push.png` | Strip 6 live CTA из DOM (3× chat+push) · rgb(255,107,53) · 44px |

Live viewport (Chrome DevTools `take_screenshot`) в чате сессии: sticky accordion с оранжевыми CTA справа от progress bar + banner «Потеряно соединение…».

## Deploy chain

1. `git push origin develop` — tip includes #41 REVIEW  
2. `fly deploy -a coffeeos --remote-only --depot=false` → **v429**  
3. HTTP `/up` 200 · `/shop` 200  
4. MCP DevTools verify CTA on Aram session

## Gaps / notes

- Cancel CTA + accepted cancel modal — не в этой выборке active (ready-only); покрыто unit/integration + #40 MCP на v428.  
- Cable reconnect banner виден; CTAs всё равно рендерятся.
