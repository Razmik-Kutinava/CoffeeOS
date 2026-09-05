# MCP — promo_amount_rub (Fly v480)

**Дата:** 2026-09-05 · **Point A** · **Результат: PASS**

| Step | Result |
|------|--------|
| Baseline `amount_rub=11` | PASS |
| Temp `promo_amount_rub=15` → API 15 | PASS |
| Restore → API 11 | PASS |
| Live charge | SKIP (API достаточно) |
| Offer remains OFF | PASS |
