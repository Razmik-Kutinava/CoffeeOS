# MCP #80 — Fly v486 note — 2026-09-07

Point A · sha `d81990b4` · **v486**

| Item | Status |
|------|--------|
| `SHOP_OTP_LOG_FALLBACK` | **false** (was blocker for live Callcheck on v482) |
| UI Callcheck / tel / SMS | PASS carried from v482 |
| V live Callcheck | **SKIP** — no owner phone call in this session |
| K desktop soft KB | SKIP (MCP desktop) |

**Fly MCP:** still **PARTIAL** until live call confirms `confirmed` → leave wizard.  
No new code this check — infra only.
