# B2.1 — табло бариста (скрины)

| Файл | Описание | Стенд |
|------|----------|-------|
| `barista_board_before.png` | Baseline до редизайна (kanban) | Fly 2026-06-10 |
| `stage1_card_accepted_fly.png` | Крит.1–2 — accepted, кнопка 80px | Fly acceptance 2026-06-11 |
| `stage1_card_preparing_fly.png` | Крит.2 — preparing | Fly acceptance |
| `stage1_card_ready_fly.png` | Крит.2 — ready | Fly acceptance |
| `stage1_modifiers_fly.png` | Крит.3 — + СО ЛЬДОМ / БЕЗ Сахар | Fly acceptance |
| `stage2_fifo_accepted.png` | Крит.4 — FIFO в НОВЫЕ | Fly acceptance |
| `stage2_after_status_move.png` | Крит.6 — после ГОТОВИТСЯ (~850ms) | Fly acceptance |
| `stage3_guest_preparing.png` | Крит.7 — WS гостю | Fly Playwright |
| `stage3_guest_ready.png` | Крит.7 — WS ready | Fly Playwright |
| `stage3_push_optional.png` | Крит.8 — FCM notification + pipeline | Fly acceptance |
| `stage4_cancel_overlay.png` | Этап 4 — overlay | Fly acceptance |
| `stage4_cancel_confirmed.png` | Этап 4 — подтверждение отмены | Fly acceptance |
| `barista_board_after.png` | Табло после MVP | Fly MCP |
| `stage5_e2e_vitrina_to_board.png` | Крит.9 — витрина→табло | Fly e2e |
| `stage5_e2e_*.png` | Полный e2e цикл | Fly Playwright |

**Прогон:** `FLY_BIN=flyctl ruby bin/acceptance/b21_acceptance_fly.rb`
