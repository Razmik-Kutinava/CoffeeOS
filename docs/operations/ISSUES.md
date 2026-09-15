# ISSUES

> **Агент на старте:** только `## 🔴 Открыто`. Resolved → [`issues/archive/`](issues/archive/).

## 🔴 Открыто

| ID | Статус | Блокер |
|----|--------|--------|
| UserCards / RebillId | 🟢 | v493 live MIR `*5953`/`*8782` RebillId + Charge PASS · new save_card FA не re-run |
| Checkout UX (Фаза 2) | 🟡 | апрув заказчика |
| SBP 3001 | 🟢 | live init v493 ≠3001 · остаток: bind AccountToken (B) |
| #47 / #35 PWA статусы | 🟡 | Fly v481 MCP MUST PASS · ждёт апрув заказчика |
| #79 SBP return + autopay labels | 🟡 | parked · recovery → **#86** · надписи/11·8 остаются |
| #86 SBP PWA recovery after bank | 🟢 | CI green `34987062132` · deploy апрув · Fly MCP + device |
| #87 Quick Repeat status composition | 🟡 | SPEC `[x]` · 7.1 cart block after card autopay · ждёт `/sbr` |
| #80 Registration UI/UX + Callcheck cascade | 🟡 | OTP fallback false · live Callcheck SKIP · ждёт апрув / телефон |
| #81 Notifications / Wallet / WebPush gaps | 🟡 | v482 MCP PASS · ждёт апрув заказчика |
| #82 Cascade SMS ready + sheet stuck | 🟡 | v482 MCP PASS · hide+SMS sent · ждёт апрув заказчика |
| GH FLY_API_TOKEN | 🟢 | org token · Deploy green 2026-09-07 |
| Min charge 10₽ | 🟢 | PTS ≥10 · Init guard · Fly bump 48 rows 2026-09-07 |
| #26 invalid token / pay error copy | 🟢 | v493 MCP **PASS** M2 inline «Сбой банка: позже» · артефакт fly_v493 |
| #71 email after pay — remember | 🟡 | Fly v481 MCP PASS · ждёт апрув заказчика |

Детали до 2026-08 → [`issues/archive/ISSUES-resolved-through-2026-08.md`](issues/archive/ISSUES-resolved-through-2026-08.md)

---

## Решено недавно

> Новые resolved с 2026-09 — ≤10 строк; при >30 или конце месяца — `/ctx-trim`.

_Пока пусто (сентябрь 2026)._
