# Fly v505 — post-deploy MCP (TASK_83 / TASK_84 аудит)

**Date:** 2026-10-01 · **HEAD** `09620222` · **Fly** v505 `deployment-01M3VCBGXRCX2DKT9VRZM8G80V`  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**CI:** [`36841893742`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36841893742) + Semgrep `36841894119` + CodeQL `36841893444` green на `09620222`  
**Deploy:** GitHub Actions [`36842242232`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36842242232) (workflow_dispatch, `develop`)

## Пачка приёмки

| Где | Результат |
|-----|-----------|
| **Migration** | нет |
| **Fly** | web+worker v505 · health fail ~11с на буте Puma → passing · после бута 200 (`/`, `/shop`, `/login`); 5xx/Exception нет (404 `/favicon.ico` — шум) |
| **Sentry** | `is:unresolved lastSeen:-24h` — 1: RUBY-1N N+1 `Payments::StuckPaymentsCheckJob`, firstSeen 14ч назад (до деплоя) — не регресс v505 |
| **Neon / УК** | skip |

## Коммиты с v504 → что проверили

| Фича | Коммиты | Проверка | Статус |
|------|---------|----------|--------|
| TASK_84-RECEIPT-DISPLAY-EXT Патч 1 — чек в видимой части | `959dbea1` `74b0dd48` `0f06a868` | bundle: `aoa__receipt` ×9 | **PASS** bundle; live — skip (нет активного заказа) |
| TASK_83 Патч 1 — убран × | `93f500ee` | bundle: `aoa__dismiss` = **0**; DOM витрины `.aoa__dismiss` = 0 | **PASS** |
| TASK_84-PEEK-ONLY-EXT — только peek | `8b75d868` | bundle: `receipt-open` ×2 | **PASS** bundle; live — skip |
| TASK_84-RECEIPT-ARROW-EXT — стрелка `>`/`v` | `d3f929a8` | bundle: `aoa__receipt-arrow` ×2 | **PASS** bundle; live — skip |
| TASK_SAFE-BOTTOM-MIN — 8px | `1c21dbda` `6309066c` | bundle `max(8px` ×1; DOM: `--shop-safe-bottom` → `8px`, CartSheet bottom = **8px** (desktop, inset 0) | **PASS** — [скрин](point_a_shop.png) |

Live статусной шторки (× нет / стрелка / peek) — skip: у гостя в браузере нет активного заказа; заказ на проде не создавали (оплата T-Bank, профиль заказчика — без OTP/PAN). Глазами — на телефоне заказчика.

## Next

- Апрув заказчика глазами: активный заказ → шторка без ×, «Состав заказа >/v», чек внутри peek; Android — CartSheet на 8px над краем
- RUBY-1N N+1 — backlog
