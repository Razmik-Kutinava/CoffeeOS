# B2.1 B2-S1 — звук нового заказа на табло (2026-06-17)

**Задача:** [B2_1_barista_order_board.md](../../requirements/customer_tasks/B2_1_barista_order_board.md) § B2-S1 — **CLOSED OPS**  
**Стенд:** `https://coffeeos.fly.dev/barista` · demo A · `barista-a@demo.coffeeos.local`

## Скрины (MCP post-deploy)

| Файл | Содержание |
|------|------------|
| `01_board_unlocked.png` | Табло после unlock кликом |
| `02_new_order_sound.png` | Новый заказ на табло (live) |
| `03_blocked_banner.png` | Баннер «Звук заблокирован…» |

**Артефакт:** [`b21_s1_sound_post_deploy_2026-06-17.json`](../b21_s1_sound_post_deploy_2026-06-17.json) — **PASS** 9/9 · latency **27 ms**

**Прогон:** `ruby bin/b21_s1_sound_prep_fly.rb` → `node bin/b21_s1_sound_mcp.mjs`
