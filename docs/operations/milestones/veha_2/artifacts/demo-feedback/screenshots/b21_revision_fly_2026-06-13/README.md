# B2.1 ревизия — Fly MCP скрины R4 (2026-06-13)

| Файл | Содержимое |
|------|------------|
| `01_board_6_slots_fly.png` | Табло 2×3, 6 карточек на Fly |
| `02_tap_white_accepted_fly.png` | Карточка accepted (белая) |
| `03_tap_yellow_preparing_fly.png` | Тап → preparing (жёлтая), полный экран |
| `03_tap_yellow_card_fly.png` | Крупно жёлтая карточка |
| `04_tap_ready_gone_fly.png` | Тап → ready, карточка ушла с табло |
| `05_live_before_fly.png` | Табло перед live-заказом (без reload) |
| `06_live_new_order_fly.png` | Новый заказ появился без F5 (~4.4с) |

**Стенд:** `https://coffeeos.fly.dev` · demo A · `barista-a@demo.coffeeos.local`  
**Скрипт:** `ruby bin/acceptance/b21_revision_fly_screenshots.rb` (prep + Playwright)  
**Результат:** `tmp/b21_revision_fly_screenshots.json` — **PASS** 2026-06-13
