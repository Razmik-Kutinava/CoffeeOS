# #70 MCP Point A — Fly v458

- Date: 2026-08-26
- Fly version: **v458** · image `deployment-01M0Z4NC76AMSTR2TJ9ZFEZ4F1`
- Browser: Chrome MCP (`cursor-ide-browser`)
- Point A: `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`
- Session: existing Point A guest `2bc3…4c` (read-only support flow; **не** писали OTP/PAN в профиль)
- A hub chat → Telegram: **PASS**
- B settings «Написать нам» → Telegram: **PASS** (same URL: **yes**)
- C Email stub: **PASS** (клик `e mail` закрыл sheet без краша; mailto не открыл мусорный Telegram URL)
- D LK regress: **PASS** (hub + история после A/B; logout отдельно в #69)
- E no PII in URL: **PASS**
- iframe/WebApp: **none**
- Notes:
  - Hub URL A: `https://t.me/code_black_support_bot` (tab + screenshot)
  - Settings URL B: `https://t.me/code_black_support_bot` (вторая вкладка, без `?`/`#`)
  - Screens: `mcp_70_hub_sheet.png` · `mcp_70_settings_sheet.png` · `mcp_70_telegram_url.png`

## Fly MCP: **PASS**
