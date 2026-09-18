# ISSUES

> **Агент на старте:** только `## 🔴 Открыто`. Resolved → [`issues/archive/`](issues/archive/).

## 🔴 Открыто

| ID | Статус | Блокер |
|----|--------|--------|
| UserCards / RebillId | 🟢 | v493 live MIR `*5953`/`*8782` RebillId + Charge PASS · new save_card FA не re-run |
| Checkout UX (Фаза 2) | 🟡 | апрув заказчика |
| SBP 3001 | 🟢 | live init v493 ≠3001 · остаток: bind AccountToken (B) |
| #47 / #35 PWA статусы | 🟡 | Fly v481 MCP MUST PASS · ждёт апрув заказчика |
| #79 SBP return + autopay labels | 🟡 | timing «1–3 дня» в WAITING + SBP row · 11/8 SBP live остаётся |
| #86 SBP PWA recovery after bank | 🟢 | CI green `34987062132` · deploy апрув · Fly MCP + device |
| #87 Quick Repeat status composition | 🟢 | CI green `34991136715` · deploy апрув · Fly MCP G4 |
| #80 Registration UI/UX + Callcheck cascade | 🟡 | Callcheck ×2 в коде (40s+40s→SMS) · live Callcheck ждёт телефон |
| #89 TASK_89 PWA auth Callcheck → SMS | 🟢 | CI green `35082473762` · deploy апрув · G5 Fly MCP |
| TASK_89-UI-EXT phone input UI/UX | 🟢 | **REVIEW** CI green `35108357982` · deploy апрув · G5 Fly MCP |
| TASK_89-POSTCALL-EXT return → continue payment | 🟢 | **REVIEW** CI green `35116445356` · deploy апрув · G5 Fly MCP |
| #81 Notifications / Wallet / WebPush gaps | 🟡 | tips CTA wired (#94 path) · Wallet CTA скрыт без certs · denied→#90 |
| #90 TASK_90 WebPush recovery after denied | 🟢 | **REVIEW** CI green `35191890272` · deploy апрув · G5 Fly MCP |
| #91 TASK_91 post-pay auto return → catalog | 🟢 | **REVIEW** CI green `35196766203` · deploy апрув · G4 Fly MCP |
| #92 TASK_92 Production background FCM | 🟢 | **REVIEW** CI green `35198770223` · deploy апрув · G5 Fly MCP |
| #93 TASK_93 Critical path hardening | 🟡 | **D** GREEN · Next: `/regress` · default20 · параллельно A/G/K… · deploy = L |
| #78 subscription cancel/confirm | 🟢 | CancelService + ConfirmPayment GetState в коде · deploy апрув |
| #82 Cascade SMS ready + sheet stuck | 🟡 | **Патч_1** CI green `35234267606` · deploy апрув → Fly MCP |
| GH FLY_API_TOKEN | 🟢 | org token · Deploy green 2026-09-07 |
| Min charge 10₽ | 🟢 | PTS ≥10 · Init guard · Fly bump 48 rows 2026-09-07 |
| #26 invalid token / pay error copy | 🟢 | v493 MCP **PASS** M2 inline «Сбой банка: позже» · артефакт fly_v493 |
| #71 email after pay — remember | 🟡 | Fly v481 MCP PASS · ждёт апрув заказчика |

Детали до 2026-08 → [`issues/archive/ISSUES-resolved-through-2026-08.md`](issues/archive/ISSUES-resolved-through-2026-08.md)

---

## Решено недавно

> Новые resolved с 2026-09 — ≤10 строк; при >30 или конце месяца — `/ctx-trim`.

_Пока пусто (сентябрь 2026)._
