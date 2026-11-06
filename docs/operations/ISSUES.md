# ISSUES

> **Агент на старте:** только `## 🔴 Открыто`. Resolved → [`issues/archive/`](issues/archive/).

## 🔴 Открыто

| ID | Статус | Блокер |
|----|--------|--------|
| Установка service worker пишет старый снимок cookie-сессии (2026-10-28, v518) | 🟡 | SW `cache.addAll(["/shop", …])` → cookie со старым снимком; варианты omit credentials / не писать cookie в PwaController / принять · [MCP v518](milestones/veha_2/artifacts/mcp/fly_v518_2026-10-28/MCP_RESULT.md) |
| Витрина открывается для кухни (2026-10-28) | 🟡 | `with_shop_tenant!` без фильтра типа точки · отдельная задача |
| RLS в production не действует (TASK_119) | 🟡 | `BYPASSRLS` + RLS выкл на orders/payments · backlog [`PRACTICES` V2-TASK-119-RLS-HARDEN](milestones/veha_2/reference/PRACTICES.md) |
| CI: Ruby 3.4.8 vs ubuntu-latest (2026-10-28) | 🟡 | сейчас `ubuntu-24.04`; долг — Ruby 3.4.12 + вернуть `ubuntu-latest` |
| Telegram-алерты не уходят | 🟡 | нет `TELEGRAM_CHAT_ID` на Fly |
| Шапка витрины выше отступа контента (TASK_107) | 🟡 | фиксированный `pt-[4.5rem]` vs растущая шапка · [MEASURE](milestones/veha_2/artifacts/shop_header_profile_id/MEASURE.md) |
| `payment_error_matrix_test.mjs` / Node 22 `navigator.onLine` | 🟡 | фикс теста через `Object.defineProperty`; продукт OK в браузере |
| Устаревшая подсказка «+сумма» на checkout | 🟡 | текст после TASK_106 · мелочь |
| Плашка «Установить CoffeeOS» перекрывает заголовок (v516/v523) | 🟡 | iPhone Safari / product + каталог · отдельная задача |
| Карточка уведомлений / плашка: наблюдения v523 | 🟡 | воронка shown / две карточки / шаги без номеров · [MCP v523](milestones/veha_2/artifacts/mcp/fly_v523_2026-10-29/MCP_RESULT.md) |
| ТВ-колонки без фильтра смены | 🟡 | `BroadcastTvColumnsJob` без смены/времени |
| SBP webhook `RATE_LIMITED` | 🟡 | `NoMethodError` при velocity |
| Флак `shop_usercards_phase1_persist_test` | 🟡 | 1× seed 7965 · чинить отдельно |
| Checkout UX (Фаза 2) | 🟡 | апрув заказчика |
| #47 / #35 PWA статусы | 🟡 | апрув заказчика |
| #79 SBP return + autopay labels | 🟡 | timing WAITING |
| #80 Registration + Callcheck | 🟡 | live ждёт телефон |
| #81 Notifications/Wallet/Push | 🟡 | tips / Wallet без certs |
| EmailVerification tenant-wide | 🟡 | backlog |
| #82 Cascade SMS + sheet stuck | 🟡 | local 2026-11-06 на develop (SMS сразу + карточка ready); прод до deploy старый · Fly MCP после деплоя |
| #71 email after pay remember | 🟡 | апрув заказчика |
| JS legacy fails (TASK_99 /regress baseline) | 🟡 | email_collection / cancel 422 / personal_cabinet [RED] / sticky_cancel / repeat_invalid_token |
| Шторка «Связь с поддержкой» под CartSheet | 🔴 | оба `z-index: 50` · ждём задачу заказчика · [MEASURE](milestones/veha_2/artifacts/active_orders_receipt_display_restore/customer_preview_2026-10-05/MEASURE.md) |
| Product images `/uploads` 404 | 🟡 | эфемерный диск Fly · S3/Tigris или volume |

Детали до 2026-08 → [`issues/archive/ISSUES-resolved-through-2026-08.md`](issues/archive/ISSUES-resolved-through-2026-08.md)  
🟢 снятые с 🔴 при ctx-trim 2026-11-02 → [`issues/archive/ISSUES-resolved-through-2026-10.md`](issues/archive/ISSUES-resolved-through-2026-10.md)

---

## Решено недавно

> Новые resolved — ≤10 строк; при >30 или конце месяца — `/ctx-trim`.

- **2026-11-02 ctx-trim:** 🟢 убраны из 🔴 (storage hotfix v522, PSCE Neon, TASK_120 cookie v518, OTP flake, UserCards/SBP3001/#86–92 и др.) → archive through-2026-10.
- **2026-10-06 — «Персонал» точки показывал УК-аккаунт** · Fix `38f20b60` · prod PASS.
- **2026-10-06 — вход без точки = 500** (RUBY-1Q) · Fix `ca8f5a2e` · prod PASS.
