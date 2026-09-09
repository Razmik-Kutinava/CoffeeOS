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

## SBR

- [x] **SPEC** — todo + шапки SESSION/HANDOFF
- [ ] **RED** — падающие тесты tenant mismatch / query forbidden / revoke · `test: … [RED]`
- [ ] **GREEN** — миграция `shop_api_keys` + authenticator + header-only + filter + docs · `feat: … [GREEN]`
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI
- [ ] **deploy / secrets** — только апрув владельца (не в GREEN)

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `config/initializers/shop_api_auth.rb` | gate: header-only + verifier (убрать `params[:api_key]` + ENV-only) |
| `app/services/shop/api_key_authenticator.rb` | digest lookup + tenant match / global_ops + ENV fallback |
| `app/models/shop_api_key.rb` | модель ключей (digest, tenant, rotation) |
| `db/migrate/*_create_shop_api_keys.rb` | схема `shop_api_keys` |
| `lib/shop_api_key_resolver.rb` | MCP/curl: не сломать Point A scripts |
| `docs/product/security/phase_1_rbac_closure/SHOP_API_AUTH.md` | канон auth + ротация + Fly secret schema |
| `config/initializers/filter_parameter_logging.rb` | не логировать `:api_key` / `:shop_api_key` |

**Соседи (blast-radius, hot-path):**

| Path | Почему |
|------|--------|
| `bin/support/shop_api_key.rb` | общий helper для acceptance/MCP — проверить после resolver |
| `test/integration/shop/api/ownership_idor_test.rb` | регрессия ownership IDOR (не ломать) |

**Тесты (зеркало):**

| Path | Зачем |
|------|--------|
| `test/integration/shop/api/authentication_test.rb` | tenant mismatch, query forbidden, rotation, browser OK |
| `test/services/shop/api_key_authenticator_test.rb` | unit digest/scope |
| `test/lib/shop_api_key_resolver_test.rb` | не сломать resolver |

При необходимости +1: `test/models/shop_api_key_test.rb` · rake `shop:api_keys:issue`.

## Не ломать

1. Браузер `/shop`: CSRF+Referer → 200 на сессионные API **без** `X-Shop-Api-Key`; ключ в meta/JS не возвращать.
2. Ownership IDOR: `ownership_idor_test` — зелёный (чужой заказ → 404).
3. MCP/acceptance Point A: ключ + `X-Shop-Tenant` Point A → работает после bootstrap (ENV fallback до seed).
4. `GET /shop/api/categories` public skip auth — без регрессии.

## Проверка

```bash
bin/rails test test/integration/shop/api/authentication_test.rb test/services/shop/api_key_authenticator_test.rb test/lib/shop_api_key_resolver_test.rb
bin/rails test test/integration/shop/api/ownership_idor_test.rb
```

После GREEN (hot-path, **после deploy по апруву**): Fly MCP Point A — без ключа 401; ключ A + tenant A 200; ключ A + tenant B 401.

## RED-сценарии (обязательные)

1. Valid key tenant A + `X-Shop-Tenant=A` → auth OK
2. Valid key tenant A + `X-Shop-Tenant=B` → **401**
3. Header отсутствует, `?api_key=...` даже верный → **401**
4. Revoked / expired / inactive → **401**
5. Browser CSRF+Referer без ключа → OK
6. Wrong key → 401
7. Dual-key: previous ещё active → OK до revoke

## DoD (дыра закрыта)

- Утечка ключа точки A **не** даёт доступ к точке B
- Ключ нельзя передать через URL
- Браузер по-прежнему без ключа
- Ротация: current + previous (или expires/revoked) без даунтайма
- Сырой ключ **не** в БД (только digest); не логировать
