# MCP RESULT — #35 D1+D2 expanded stack + meta · Fly **v438** · 2026-08-06

**App:** https://coffeeos.fly.dev  
**Release:** **v438** · image `coffeeos:deployment-01KZBM95ZEVSW9G5GN87EW4RW6`  
**Tip:** `4ca777a4` (push develop)  
**Tenant:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Сессия:** Chrome DevTools MCP  
**Вердикт:** **PASS** (D1 stack + D2 meta product на checkout pay-stack ≈ скрин 06)

## Deploy

1. `git push origin develop` → `4ca777a4`
2. `fly deploy -a coffeeos --remote-only --depot=false` → **v438**
3. HTTP `/up` **200**

## REVIEW (перед push)

- Correctness / Kieran: нет P0
- Fix: empty `cart_expanded` без silent fallback на точку (`99a4941d`)
- Residual (не блокер): stringly `sheetContext` naming

## DOM live

### Home `#/` (peek · скрин 01)

| Метрика | Значение |
|---------|----------|
| `data-cart-sheet-build` | **prog38** |
| `data-cart-status-stack` | **status-above-lines** |
| Status embedded / position | `true` / **relative** |
| Status before cart lines | **true** |
| Meta third | `Demo Coffee Point A` (точка — канон peek) |

### Checkout pay-stack (≈ скрин 06 expanded)

| Метрика | Значение |
|---------|----------|
| `data-checkout-pay-stack` | **true** |
| Meta | `… — #202608-0014 — Фильтр-кофе без кофеина (декаф) Гватемала` |
| Meta = позиция (не точка) | **PASS** |
| Status before lines | **true** |
| Pay methods visible | СБП / Картой / Оплатить |

**Скрин:** viewport MCP (filePath в artifacts denied sandbox) — DOM metrics выше = канон; meta product подтверждена evaluate_script.

## Gaps

- Gesture → `MODE_EXPANDED` через synthetic pointer в MCP нестабилен; критерий D2 закрыт через `payStackActive` (тот же `sheetContext=cart_expanded` по SPEC).
- D5 barista → ready → hide + push — не гоняли.
