# todo — V3-SEC-SHOP-API-KEYS (tenant-scoped shop API keys)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-SHOP-API-KEYS` / `IB-D-09` |
| **Тип** | security / hot-path shop auth |
| **Приоритет** | high |
| **Ветка** | `develop` |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Parked** | `V3-SEC-JOB-TENANT-GUC` GREEN `8f9f5aa2` (свой `/review`) · `V3-SEC-OTP-MERGE` SPEC |

## SBR

- [x] **SPEC** · **RED** `84a85554` · **GREEN** `8f9cd956`
- [x] **regress** — **30/76 PASS**
- [x] **REVIEW** — local PASS · Entire `01M22C4CV16HA4XDFZ4T4ZGQ23` · bugbot/security **usage blocked** · push CI
- [ ] **deploy / secrets** — только апрув владельца

## Проверка

```bash
bin/rails test test/integration/shop/api/authentication_test.rb test/services/shop/api_key_authenticator_test.rb test/lib/shop_api_key_resolver_test.rb test/integration/shop/api/ownership_idor_test.rb
# → 30/76 PASS
```

После deploy (апрув): Fly MCP Point A — 401 without key; A+A 200; A+B 401.
