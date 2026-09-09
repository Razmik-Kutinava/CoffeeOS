# Shop API keys seed — Fly v494

**Status:** **PASS**
**FALLBACK:** still ON (ENV global не выключали)

## Seed
- 17 sales_point keys issued (`seed-2026-09-09`)
- RAW: `config/secrets/shop_api_keys_fly_seed_2026-09-09.json` (gitignored)
- Point A prefix: `sk_c71a9` · Point B prefix: `sk_6bd88`

## Smoke
- PASS A_key_on_A (200, expect 200)
- PASS A_key_on_B (401, expect 401)
- PASS B_key_on_B (200, expect 200)
- PASS B_key_on_A (401, expect 401)
- PASS no_key (401, expect 401)
- PASS query_key_dead (401, expect 401)
- PASS env_fallback_still_on (200, expect 200)
- PASS categories_public (200, expect 200)
