# B2.1 ревизия — прогон приёмки заказчика (Fly MCP path)

**Дата:** 2026-06-13 · **Стенд:** `https://coffeeos.fly.dev` · demo A  
**Скрипт:** `ruby bin/b21_revision_customer_mcp.rb`  
**Артефакт:** `tmp/b21_revision_customer_mcp.json` — **PASS**

| Файл | Сценарий заказчика |
|------|-------------------|
| `01_board_6_slots_fly.png` | 1.1 — сетка 2×3, 6 слотов |
| `02_tap_white_accepted_fly.png` | 1.2 — белая карточка |
| `03_tap_yellow_*.png` | 1.2 — жёлтая после тапа |
| `04_tap_ready_gone_fly.png` | 1.2 — карточка ушла |
| `05_live_before_fly.png` | 1.3 — до live (без reload) |
| `06_live_new_order_fly.png` | 1.3 — новый заказ ~5с без F5 |
| `07_limit_6_full_board_fly.png` | 1.4 — 7-й заказ не на табло |

**Chrome DevTools MCP:** login через браузер → HTTP 500 на Fly; сценарий выполнен Playwright (тот же UX-путь).
