# #74 MCP — Card binding unique hash — Fly v459

**Дата:** 2026-08-27  
**Fly:** **v459** (deploy с develop HEAD `0609ae6b`)  
**Deploy:** сделан в этой сессии (апрув владельца)

| Сценарий | Результат | Доказательство |
|----------|-----------|----------------|
| Shop Point A жив | **PASS** | каталог+корзина `01_shop_point_a.png` |
| UserCards JSON без hash/token | **PASS*** | guest `GET /shop/api/user/cards` → 401 `Требуется авторизация`; в теле **нет** `card_hash`/`card_token`. `Shop::SavedCardJson` не сериализует hash/token |
| A: save_card своей карты | **SKIP** | live dual-bind / save_card E2E не гоняли (PAN/OTP safety) |
| B: отказ без утечки | **SKIP** | E2E две учётки + одна карта — не в этой сессии |
| save_card=false | **PASS** | local `shop_save_card_false_step6_test` |
| Local test suite Проверка | **PASS** | `saved_card_store` + step5/6 + tbank callback/adapter (+ fiscal api) **64/0** суммарно по прогонам |
| dry-run duplicates | **PASS** | Fly `mobile_payment_methods:card_hash:dry_run`: `pending_backfill=2`, **0** duplicate groups |
| Schema on Fly | **PASS** | колонка `card_hash` + unique idx `idx_mpm_active_card_hash_unique` = true |

**Local:** PASS  
**Fly MCP:** **PARTIAL** — smoke + schema + dry-run PASS; cross-account E2E SKIP  
**apply backfill:** **не** запускали (нужен апрув)

## Open
- `bin/rails mobile_payment_methods:card_hash:apply` — только с апрувом.
- Live A/B bind одной карты — отдельный test-customer прогон.
