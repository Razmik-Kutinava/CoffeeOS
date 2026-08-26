# #69 MCP Point A — Fly v458 — PWA ЛК

**Дата:** 2026-08-26  
**Fly:** **v458** · `deployment-01M0Z4NC76AMSTR2TJ9ZFEZ4F1`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Browser:** Chrome MCP  
**Сессия:** Point A guest `2bc3…4c` (история заказов; **не** OTP/PAN в профиль)  
**Скрины:** `mcp_69_profile_hub.png` · `mcp_69_support_sheet.png` · `mcp_69_settings.png` · `mcp_69_receipt.png` · `mcp_69_about.png`

## Шаги

| # | Шаг | Result |
|---|-----|--------|
| 0.1–0.3 | Fly v458 · `/up` 200 · `/shop` 200 · categories 200 | **PASS** |
| 0.4 | #64–#68 smoke: categories + hash product/back | **PASS** (каталог жив) |
| 1 | Auth: existing session; profile 200 / history 200 | **PASS** |
| 2 | Hub `#/profile`: `shop-lk-home`, avatar/name, chat+settings, PLG, history rows+repeat | **PASS** |
| 3 | ContactSupportSheet Email/Tg; Telegram без PII | **PASS** (см. #70) |
| 4 | Settings: имя, toggle, contacts, о нас, написать нам, ВЫХОД | **PASS** |
| 5 | Receipt `#/order/:id/receipt`: OFD stub + ПОВТОРИТЬ stub | **PASS** |
| 6 | About `#/about`: version/legal/footer | **PASS** (build 3.39.0 / code 32396) |
| 7 | Logout `DELETE /shop/api/session` → `{ok:true,logged_out:true}` → `#/` | **PASS** |
| 8 | Blast: cart sheet + checkout reachable | **PASS** |
| 9 | Fly logs на шагах ЛК: profile/history 200, нет 5xx | **PASS** |
| 9b | Sentry 24h / Neon / УК | **SKIP** (нет UI Sentry в этом прогоне; Neon: migrate `order_emails` в release OK) |

## MCP #69 Point A: **PASS**

Notes: после logout label шапки всё ещё `2bc3…4c` (guest session id) — ожидаемо; сессия shop API сброшена (`logged_out: true`).
