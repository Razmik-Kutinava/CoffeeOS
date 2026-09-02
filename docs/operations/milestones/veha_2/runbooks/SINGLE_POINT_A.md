# Single Point A (prod)

**Цель:** одна боевая точка для заказчика — Demo Coffee Point A, ул. Ленина, 10.

| | |
|--|--|
| **tenant_id** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Shop URL** | https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 |
| **Fly env** | `DEMO_SINGLE_POINT=true`, `SHOP_DEFAULT_TENANT_ID` (см. `fly.toml`) |

## Операции

```bash
# Локально / после деплоя на Fly
DRY_RUN=1 bin/rails platform:prod_single_point
DRY_RUN=0 bin/rails platform:prod_single_point

# Артефакт JSON
OUTPUT_JSON=docs/operations/milestones/veha_2/artifacts/single_point_a/cleanup.json \
  DRY_RUN=0 bin/rails platform:prod_single_point
```

**Release:** `fly:release` при `DEMO_AUTO_SEED` + `DEMO_SINGLE_POINT` вызывает `platform:prod_single_point` (DRY_RUN=0).

**Не DELETE** — только `status: inactive` на лишних `sales_point`. Заказы/карты Point A не трогаются.

**Prep kitchen** остаётся `active` (backend, не витрина).

## Проверка

- `bin/rails test test/services/platform/prod_single_point_cleanup_test.rb`
- Fly MCP Point A 7/7
- `GET /shop/api/tenants` — один switchable sales_point в городе (или switchable=false)
