# MCP — subscription offer rollback verify (Fly v480)

**Дата:** 2026-09-05 · **Point A** · **Результат: PASS**

## DoD

| Check | Result |
|-------|--------|
| УК: offer OFF + CTA tips | PASS |
| `/shop/api/config` `enabled=false` | PASS |
| Ready CTA tips, no subscription | PASS |
| Tips path without errors | PASS (pending adapter) |

## Notes

Deploy `v480` не вернул опасный CTA. Скрины: `uk_offer_off.png`, `ready_cta_tips.png`.
