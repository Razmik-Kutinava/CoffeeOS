# Redis for Rack::Attack (TASK_93-I)

Shared rate-limit store across Fly web machines. **Not** app `Rails.cache` (Solid Cache stays).

## Env

| Var | Role |
|-----|------|
| `RACK_ATTACK_REDIS_URL` | Preferred for Attack only |
| `REDIS_URL` | Fallback if Attack-specific unset |

On **production** or when `FLY_APP_NAME` is set: missing URL → **boot fail** (`resolve_cache_store` raises),
except Docker **`SECRET_KEY_BASE_DUMMY=1`** (assets:precompile) → MemoryStore, no raise.

Dev without URL → `MemoryStore` + warn log (per-process limits).

## Fly (TASK_93-L — needs approve)

```bash
# create / attach Upstash or Fly Redis, then:
fly secrets set REDIS_URL='redis://...' -a coffeeos
# or:
fly secrets set RACK_ATTACK_REDIS_URL='redis://...' -a coffeeos
```

Do **not** deploy Redis/secrets from block I without ops approve (block **L**).

## Local / CI

- CI `test` job: Redis service + `REDIS_URL=redis://localhost:6379/0` (T-I1b).
- Local T-I1b: set `REDIS_URL` or skip.

## Verify

```bash
bin/rails test test/integration/rack_attack_store_test.rb test/integration/rack_attack_otp_verify_test.rb
```
