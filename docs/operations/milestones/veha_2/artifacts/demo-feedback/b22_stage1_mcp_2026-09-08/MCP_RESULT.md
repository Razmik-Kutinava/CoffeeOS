# MCP — B2.2 stage-1 · Fly v490 · 2026-09-08

**Вердикт: PARTIAL** (B1–B5 + C1–C3 PASS · **B6 FAIL** до redeploy)

| Check | Result |
|-------|--------|
| B1 menu 200 | PASS |
| B2 `#menu-pos-layout` / grid / cart | PASS |
| B3 15 product cards | PASS |
| B4 «Корзина пуста» | PASS |
| B5 `#menu-pay-btn` disabled | PASS |
| B6 search hides empty categories | **FAIL** — Turbo: listener на `DOMContentLoaded` не вешается |
| C1 sidebar Меню+Создать | PASS |
| C2 create-order | PASS |
| C3 board `/barista` | PASS Point A |

**Fix в tip после MCP:** `app/views/barista/menu/index.html.erb` — `turbo:load` + immediate bind. Нужен **второй deploy** для закрытия B6.

Скрины: `barista_menu_after_stage1.png`, `create_order_alive.png`
