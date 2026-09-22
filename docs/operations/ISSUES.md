# ISSUES

> **Агент на старте:** только `## 🔴 Открыто`. Resolved → [`issues/archive/`](issues/archive/).

## 🔴 Открыто

| ID | Статус | Блокер |
|----|--------|--------|
| UserCards / RebillId | 🟢 | v493 MIR RebillId+Charge PASS · new save_card FA не re-run |
| Checkout UX (Фаза 2) | 🟡 | апрув заказчика |
| SBP 3001 | 🟢 | live init ≠3001 · остаток: bind AccountToken (B) |
| #47 / #35 PWA статусы | 🟡 | Fly v481 MCP PASS · апрув заказчика |
| #79 SBP return + autopay labels | 🟡 | timing «1–3 дня» в WAITING + SBP row |
| #86 SBP PWA recovery | 🟢 | CI green · deploy апрув · Fly MCP + device |
| #87 Quick Repeat status | 🟢 | CI green · deploy апрув · Fly MCP G4 |
| #80 Registration + Callcheck | 🟡 | Callcheck×2 в коде · live ждёт телефон |
| #89 PWA auth Callcheck→SMS | 🟢 | CI green · deploy апрув · G5 Fly |
| TASK_89-UI-EXT phone UI | 🟢 | REVIEW CI green · deploy · G5 |
| TASK_89-POSTCALL-EXT | 🟢 | REVIEW CI green · deploy · G5 |
| #81 Notifications/Wallet/Push | 🟡 | tips CTA wired · Wallet скрыт без certs · denied→#90 |
| #90 WebPush after denied | 🟢 | REVIEW CI green · deploy · G5 |
| #91 post-pay → catalog | 🟢 | REVIEW CI green · deploy · G4 |
| #92 background FCM | 🟢 | REVIEW CI green · deploy · G5 |
| EmailVerification tenant-wide | 🟡 | TTL by tenant+email без session bind · backlog |
| #78 subscription cancel/confirm | 🟢 | CancelService+ConfirmPayment в коде · deploy |
| #82 Cascade SMS + sheet stuck | 🟡 | Патч_1 CI green · deploy → Fly MCP |
| #71 email after pay remember | 🟡 | Fly v481 MCP PASS · апрув заказчика |
| TASK_84 receipt display | 🟢 | REVIEW CI green · G5 Fly после deploy |

Детали до 2026-08 → [`issues/archive/ISSUES-resolved-through-2026-08.md`](issues/archive/ISSUES-resolved-through-2026-08.md)

---

## Решено недавно

> Новые resolved с 2026-09 — ≤10 строк; при >30 или конце месяца — `/ctx-trim`.

| ID | Когда | Итог |
|----|-------|------|
| #93 Critical path hardening | 2026-09-18 | Fly v499 · MCP 20/20 PASS · device pay = апрув |
| GH FLY_API_TOKEN | 2026-09-07 | org token · Deploy green |
| Min charge 10₽ | 2026-09-07 | PTS≥10 · Init guard · Fly bump |
| #26 invalid token / pay copy | 2026-09 | v493 MCP PASS · inline «Сбой банка: позже» |
