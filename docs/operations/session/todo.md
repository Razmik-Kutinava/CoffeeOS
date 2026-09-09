# todo — V3-SEC-SHOP-API-KEYS (tenant-scoped shop API keys)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-SHOP-API-KEYS` / `IB-D-09` |
| **Тип** | security / hot-path shop auth |
| **Приоритет** | high (blast radius при утечке) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | Flutter device tokens · Platform CRUD UI · fly deploy без апрува |
| **Parked** | `V3-SEC-OTP-MERGE` `c9733b8b` · `V3-SEC-JOB-TENANT-GUC` `022552d5` — resume после `/review` keys |

## SBR

- [x] **SPEC**
- [x] **RED** — `84a85554`
- [x] **GREEN** — `8f9cd956`
- [x] **regress** — auth+resolver+ownership **30/76 PASS** (2026-09-09)
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI
- [ ] **deploy / secrets** — только апрув владельца

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `config/initializers/shop_api_auth.rb` | header-only + verifier |
| `app/services/shop/api_key_authenticator.rb` | digest + tenant match |
| `app/models/shop_api_key.rb` | модель |
| `db/migrate/20260909120000_create_shop_api_keys.rb` | схема |
| `app/services/rls/guc_context.rb` | `with_shop_api_key_lookup` |
| `docs/product/security/phase_1_rbac_closure/SHOP_API_AUTH.md` | канон |
| `config/initializers/filter_parameter_logging.rb` | filter keys |

## Не ломать

1. Browser CSRF+Referer без API key
2. Ownership IDOR
3. MCP ENV fallback до `SHOP_API_KEY_FALLBACK=0`
4. Public `GET /shop/api/categories`

## Проверка

```bash
bin/rails test test/integration/shop/api/authentication_test.rb test/services/shop/api_key_authenticator_test.rb test/lib/shop_api_key_resolver_test.rb test/integration/shop/api/ownership_idor_test.rb
# → 30 runs, 76 assertions, 0 failures (2026-09-09 regress)
```

После `/review` + deploy (апрув): Fly MCP Point A — без ключа 401; A+A 200; A+B 401.
