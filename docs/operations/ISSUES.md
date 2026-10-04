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
| JS legacy fails (найдено на TASK_99 /regress) | 🟡 | до TASK_99 те же (`def97615`): `email_collection_test` «identityReady / canPay depend on phoneVerified» 1 fail · `order_action_buttons_cancel_test` «422/500: force preparing» 1 fail · `personal_cabinet_test` 58 — `[RED]` TDD, не баг. Не push-зона |
| RUBY-1N N+1 `StuckPaymentsCheckJob` | 🟢 | **Fly v506 задеплоен** (`0fa72666`) · regress 10:45 был ещё v505 · Sentry → resolved, ждём ~5 ч (traces 5%) · backlog: 4 тестовых pending по 11 ₽ шлют алерт каждые 15 мин · история: | Sentry perf: 2× `SELECT payments WHERE id` на каждый stuck (job `reload` + `rebill_still_needed?` reload при `save_card=false`). Fix `01efc828` (RED `4e5452d7`) · хвост `save_card=true`: rebill-проверка только для succeeded — RED `6f401fb5` → GREEN `1642a746` · Local payments 146/0 + rebill/UserCards 57/0 · Sentry-событие 04.10 09:00 UTC — ещё код v505 · push → CI → deploy апрув → Sentry закроется |
| Product images `/uploads` 404 | 🟡 | `ProductImageStorage` → `public/uploads` на эфемерном диске Fly, volume нет → фото стираются при деплое (v503: 5 ссылок, 1 файл). Нужно решение: S3/Tigris или volume |

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
