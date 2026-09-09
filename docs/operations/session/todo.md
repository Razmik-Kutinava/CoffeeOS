# todo — V3-SEC-SHOP-API-KEYS (tenant-scoped shop API keys)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-SHOP-API-KEYS` / `IB-D-09` |
| **Тип** | security / hot-path shop auth |
| **Приоритет** | high (blast radius при утечке) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **Доки** | `docs/product/security/phase_1_rbac_closure/SHOP_API_AUTH.md` |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | Flutter device tokens · CSRF browser model · Platform CRUD UI · OAuth/JWT · fly deploy без апрува |
| **Parked** | `V3-SEC-OTP-MERGE` SPEC `c9733b8b` — resume после `/review` этой задачи |

## SBR

- [x] **SPEC** — todo + шапки SESSION/HANDOFF
- [x] **RED** — `84a85554` tenant mismatch / query forbidden / revoke
- [x] **GREEN** — миграция `shop_api_keys` + authenticator + header-only + filter + docs
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI
- [ ] **deploy / secrets** — только апрув владельца (не в GREEN)

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `config/initializers/shop_api_auth.rb` | gate: header-only + verifier |
| `app/services/shop/api_key_authenticator.rb` | digest lookup + tenant match / global_ops + ENV fallback |
| `app/models/shop_api_key.rb` | модель ключей (digest, tenant, rotation) |
| `db/migrate/20260909120000_create_shop_api_keys.rb` | схема `shop_api_keys` |
| `lib/shop_api_key_resolver.rb` | MCP/curl: не сломать Point A scripts |
| `app/services/rls/guc_context.rb` | `with_shop_api_key_lookup` |
| `docs/product/security/phase_1_rbac_closure/SHOP_API_AUTH.md` | канон auth + ротация + Fly secret |
| `config/initializers/filter_parameter_logging.rb` | `:api_key` / `:shop_api_key` |

**Соседи:** `bin/support/shop_api_key.rb` · `lib/tasks/shop_api_keys.rake` · `app/services/shop/api_keys/issue.rb`

**Тесты:** `authentication_test` · `api_key_authenticator_test` · `shop_api_key_resolver_test` · регрессия `ownership_idor_test`

## Не ломать

1. Браузер `/shop`: CSRF+Referer без API key; ключ не в meta/JS
2. Ownership IDOR — зелёный
3. MCP Point A: ENV fallback global_ops до seed + `SHOP_API_KEY_FALLBACK=0`
4. `GET /shop/api/categories` public skip auth

## Проверка

```bash
bin/rails test test/integration/shop/api/authentication_test.rb test/services/shop/api_key_authenticator_test.rb test/lib/shop_api_key_resolver_test.rb
# → 19 runs, 21 assertions, 0 failures (2026-09-09)
bin/rails test test/integration/shop/api/ownership_idor_test.rb
# → 11 runs, 55 assertions, 0 failures
```

После GREEN (hot-path, **после deploy по апруву**): Fly MCP Point A — без ключа 401; ключ A + tenant A 200; ключ A + tenant B 401.

## DoD (дыра закрыта)

- Утечка ключа A **не** даёт доступ к B
- Ключ нельзя передать через URL
- Браузер без ключа
- Ротация current+previous / expires/revoked
- Сырой ключ не в БД (digest only)
