# Fly demo-стенд (develop → coffeeos.fly.dev)

**Назначение:** живое демо и ручной прогон В1/H.3 на стенде **develop**, не на main/prod.

---

## После каждого деплоя (автоматически)

`fly.toml`:

- `release_command`: `bin/rails fly:release` (`db:prepare` + solid migrate + `demo:seed`)
- `SHOP_BASE_DOMAIN=coffeeos.fly.dev`
- `DEMO_AUTO_SEED=true` — запасной `demo:seed` при старте Puma (`bin/docker-entrypoint`)

**Чеклист:** [`milestones/veha_1/CHECKLIST.md`](milestones/veha_1/CHECKLIST.md) § H.0.

---

## Ручной прогон (если автосид не сработал)

```bash
fly ssh console -a coffeeos
bin/rails demo:seed
```

Пароль и логины: [`milestones/veha_1/DEMO_LOGINS.md`](milestones/veha_1/DEMO_LOGINS.md) (`demo123456`).

---

## Витрины (поддомен на точку)

| Точка | URL |
|-------|-----|
| A | https://demo-point-a.coffeeos.fly.dev/shop |
| B | https://demo-point-b.coffeeos.fly.dev/shop |

**Пока нет wildcard-сертификата** (chrome-error на поддомене) — витрина точки A:

`https://coffeeos.fly.dev/shop?tenant_id=8c7f5bc7-f2b4-43f0-991c-5ede0f480b20`

(после `demo:seed` UUID в логе release или `fly ssh` → `rails runner "puts Tenant.find_by!(slug:'demo-point-a').id"`)

**Wildcard TLS (один раз на стенде, обязательно для поддоменов):**

```bash
flyctl auth login
fly certs add "*.coffeeos.fly.dev" -a coffeeos
fly certs list -a coffeeos
```

Дождаться статуса **Ready** (не Issued/пусто). Без cert поддомен в браузере не откроется.

---

## Убрать автосид после живого демо

1. В `fly.toml` удалить `demo:seed` из `release_command` (оставить `db:prepare`).
2. Убрать или `DEMO_AUTO_SEED=false`.
3. Отметить § H.0 в чеклисте В1.

**main/prod:** не включать `DEMO_AUTO_SEED` и `demo:seed` в release без отдельного решения.
