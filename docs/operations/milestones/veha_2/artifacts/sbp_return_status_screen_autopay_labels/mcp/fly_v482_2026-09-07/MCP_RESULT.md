# MCP #79 — Fly v482 — 2026-09-07

Point A: `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
Release: **v482** · sha `4f980e96`

| ID | Result | Notes |
|----|--------|-------|
| R0 | PASS | shop Point A жив |
| R1 | BLOCKED | `POST /shop/api/payments/sbp/init` → **422** `Discount amount must be greater than or equal to 0` · order `d84096c3…` total 1.79 · waiting UI не достигнут (не баг beginSbpBankRedirect — validation до redirect) |
| R2 | SKIP | нет bank return без R1 |
| R3 | PASS | inline toast **«Сервис временно недоступен»** (не card FSM / «Сбой банка» / «Недостаточно средств») · `03_autopay_service_unavailable.png` |
| R4 | SKIP | 11/8 не платили — init 422 на demo 2₽ + save_sbp |
| R5 | PASS | radio «Картой +» на sheet на месте |

P0 blockers: R1 waiting — blocked by discount validation (triage promo/#75/#76 / sbp_init, **не** переписывать #79 waiting labels).  
Bundle: `payment-waiting-for-bank` + SBP autopay strings present on Fly.

**Local:** skip (CI green)  
**Fly MCP:** **PARTIAL**
