# MCP #79 — Fly v486 — 2026-09-07

Point A: `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
Release: **v486** · sha `d81990b4` (resume GetQr) · image `deployment-01M1XTQFXH415JDZ7P2AT857BV`  
Prior fixes on tip: `fa1762c8` (cart ≤ promo → no negative discount)

| ID | Result | Notes |
|----|--------|-------|
| R0 | PASS | `/up` 200 · shop Point A |
| R1 | PASS | `POST …/sbp/init` **200** · order `5fcaf3a7…` cart 179 → growth **final 11₽** · NSPK QR · waiting UI `payment-waiting-for-bank` |
| R2 | SKIP | bank return / pay in app — desktop MCP |
| R3 | PASS (v482) | toast «Сервис временно недоступен» — unchanged |
| R4 | PASS (path) | growth bind 11₽ applied (`growth_promo_intent` + discount 168) |
| R5 | PASS (v482) | radio «Картой +» |

**Notes**
- Demo **2₽** + bind: growth skips (cart ≤ promo) → T-Bank **3016** min 10₽ — use cart **> promo** for live Init (or backlog UX).
- Stuck retry OrderId: fixed by resume GetQr when `provider_payment_id` set (`d81990b4`).

Screens: `01_nspk_qr_after_sbp_init.png`, `02_waiting_for_bank.png`

**Local:** CI [34109574092](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34109574092) green  
**GH Deploy:** [34117804689](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34117804689) **green** (org token)  
**Fly MCP:** **PASS** (R1 waiting; R2 bank return skip)
