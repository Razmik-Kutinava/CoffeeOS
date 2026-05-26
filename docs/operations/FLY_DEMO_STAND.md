# Fly demo-стенд (develop → coffeeos.fly.dev)

**Назначение:** живое демо и ручной прогон В1/H.3 на стенде **develop**, не на main/prod.

**Режим URL:** **B — Fly demo** (без поддоменов на `*.fly.dev`). Канон поддоменов по slug — **режим A**, см. [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md).

---

## После каждого деплоя (автоматически)

`fly.toml`:

- `release_command`: `bin/rails fly:release` (`db:prepare` + solid migrate + `demo:seed`)
- `SHOP_BASE_DOMAIN` **не задан** — витрина `?tenant_id=` (режим B)
- `DEMO_AUTO_SEED=true` — запасной `demo:seed` при старте Puma

**Чеклист:** [`milestones/veha_1/CHECKLIST.md`](milestones/veha_1/CHECKLIST.md) § H.0.

---

## Ручной прогон (если автосид не сработал)

```bash
fly ssh console -a coffeeos
bin/rails demo:seed
bin/rails demo:shop_urls
```

Пароль и логины: [`milestones/veha_1/DEMO_LOGINS.md`](milestones/veha_1/DEMO_LOGINS.md) (`demo123456`).

---

## Витрины (режим B — тест на Fly)

| Slug (в БД) | URL для демо |
|-------------|--------------|
| `demo-point-a` | `https://coffeeos.fly.dev/shop?tenant_id=<uuid-a>` |
| `demo-point-b` | `https://coffeeos.fly.dev/shop?tenant_id=<uuid-b>` |

UUID:

```bash
fly ssh console -a coffeeos -C 'bin/rails demo:shop_urls'
```

**Не пытаться** `fly certs` на `*.coffeeos.fly.dev` — см. [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md) § «что не работает».

Slug точек в демо **сохранены** (`demo-point-a`, `demo-point-b`) — при переходе на свой домен витрины станут `https://demo-point-a.shop.бренд.ru/shop` без смены slug.

---

## Когда появится свой домен (режим A)

Пошагово: [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md) § «Переход B → A».  
Кратко: DNS wildcard → `fly certs` → `SHOP_BASE_DOMAIN=shop.бренд.ru` → deploy → smoke поддоменов.

---

## Убрать автосид после живого демо

1. В `fly.toml` убрать `demo:seed` из `release_command` (оставить `db:prepare`).
2. `DEMO_AUTO_SEED=false` или удалить.
3. Отметить § H.0 в чеклисте В1.

**main/prod:** не включать `DEMO_AUTO_SEED` и `demo:seed` в release без отдельного решения.
