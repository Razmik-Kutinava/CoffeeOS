# Fly demo-стенд (develop → coffeeos.fly.dev)

**Назначение:** живое демо и ручной прогон В1/H.3 на стенде **develop**, не на main/prod.

**Режим URL:** **B — Fly demo** (без поддоменов на `*.fly.dev`). Канон поддоменов по slug — **режим A**, см. [`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md).

---

## Частые ошибки в терминале

### 1. `fly certs add "*.coffeeos.fly.dev"` → `cannot register certificate`

**Это не баг CoffeeOS.** На зоне `*.fly.dev` Fly **не выдаёт** сертификаты для поддоменов приложения.

**Что делать:** команду **не запускать**. Витрины открывать так:

`https://coffeeos.fly.dev/shop?tenant_id=<uuid>`

UUID — см. ниже § «Узнать URL без SSH».

---

### 2. `fly ssh console` → `tunnel unavailable` / `timed out`

**Приложение при этом может работать** (сайт в браузере открывается). Ошибка — доступ **с твоего ПК** к API/туннелю Fly (сеть, VPN, firewall, провайдер).

**Попробуй по порядку:**

1. Браузер: https://coffeeos.fly.dev/up — зелёная страница = app жив.
2. Повтори через 1–2 мин: `fly ssh console -a coffeeos`
3. Другая сеть (мобильный интернет без VPN) или выключи VPN.
4. `fly auth whoami` — залогинен ли аккаунт.
5. Обнови CLI: `fly version` → при необходимости [установка](https://fly.io/docs/flyctl/install/).
6. **Без SSH** — UUID витрин из логов деплоя (см. ниже) или из УК в браузере.

**SSH не обязателен** для демо, если деплой и `demo:seed` в release прошли успешно.

### 3. `ensure depot builder failed` / `401 Unauthorized` при `fly deploy`

**Симптом:** сборка Dockerfile прошла, push образа падает с `ensure depot builder failed (status 401)` или `401 Unauthorized` от Depot.

**Причина:** удалённый билдер **Depot** (дефолт в новых `flyctl`) — сбой auth/инфра, не баг CoffeeOS.

**Что делать (по порядку):**

1. **Рекомендуемый деплой из репо:** `./bin/fly_deploy.sh` (внутри `--depot=false`).
2. Вручную: `fly deploy -a coffeeos --depot=false`
3. Обновить CLI: `fly version update` (старые версии чаще ловят 401).
4. Если снова 401 на registry: `fly auth docker`, затем повтор.
5. Запасной вариант (нужен локальный Docker): `fly deploy -a coffeeos --local-only`

**Проверка после деплоя:** `/up` → 200; в логах release — `Shop A:` / `Shop B:`.

**Transient warning** `not listening on 0.0.0.0:3000` во время rolling update — обычно Puma ещё поднимается; если `/up` зелёный через 1–2 мин — ок.

---

### 4. `fly:release` / `db:prepare` failed

**Канон БД:** **Neon** проект `coffeeos` — см. [`../dev/INFRA_STACK.md`](../dev/INFRA_STACK.md).

| Ошибка | Действие |
|--------|----------|
| `exceeded the compute time quota` | Neon Launch + spending limit $15 |
| `connection refused` | `fly secrets list` → `DATABASE_URL` |
| release упал, образ собран | `fly ssh console -a coffeeos -C "bin/rails fly:release"` (**по апруву**) |

**Деплой:** только по апруву владельца (лишний deploy = CU-hrs на Neon).

С `2026-06-19`: `bin/docker-entrypoint` не блокирует Puma при временном fail `db:prepare` — `/up` может быть 200, витрина без БД → 500.

---

## После каждого деплоя (автоматически)

`fly.toml`:

- `release_command`: `bin/rails fly:release` (`db:prepare` + solid migrate + `demo:seed`)
- `SHOP_BASE_DOMAIN` **не задан** — витрина `?tenant_id=` (режим B)
- `DEMO_AUTO_SEED=true` — запасной `demo:seed` при старте Puma

В логах release после сида есть строки **`Shop A:`** / **`Shop B:`** / **`Shop C:`** с полным URL.

**Чеклист:** [`../milestones/veha_1/checklists/CHECKLIST.md`](../milestones/veha_1/checklists/CHECKLIST.md) § H.0.

---

## Узнать URL витрин (без SSH)

### A. Логи Fly (удобнее всего)

```bash
fly logs -a coffeeos | grep -E "Shop A:|Shop B:|Точка A:"
```

Или в браузере: [Fly dashboard → coffeeos → Logs](https://fly.io/apps/coffeeos/monitoring), фильтр `Shop A`.

После последнего деплоя ищи:

```
Shop A: https://coffeeos.fly.dev/shop?tenant_id=...
Shop B: https://coffeeos.fly.dev/shop?tenant_id=...
```

### B. УК в браузере

1. https://coffeeos.fly.dev/login  
2. `uk@demo.coffeeos.local` / `demo123456`  
3. Админка → точки → открыть **demo-point-a** → в адресе или карточке скопировать **id** (UUID).  
4. Витрина: `https://coffeeos.fly.dev/shop?tenant_id=<этот-uuid>`

### C. SSH (если туннель заработал)

```bash
fly ssh console -a coffeeos
```

На машине (интерактивно, не `-C`):

```bash
cd /rails
bin/rails demo:shop_urls
```

---

## Ручной прогон (если автосид не сработал)

Только если в логах release **нет** `Shop A:` или витрина пустая — и **SSH доступен**:

```bash
fly ssh console -a coffeeos
cd /rails && bin/rails demo:seed
```

Пароль и логины: [`../milestones/veha_1/reference/DEMO_LOGINS.md`](../milestones/veha_1/reference/DEMO_LOGINS.md) (`demo123456`).

---

## Витрины (режим B)

| Slug | Как открыть |
|------|-------------|
| `demo-point-a` | URL из логов / УК с `tenant_id` |
| `demo-point-b` | то же |

Slug в БД **не меняется** — при своём домене будет `https://demo-point-a.shop.бренд.ru/shop`.

---

## Когда появится свой домен (режим A)

[`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md) § «Переход B → A».

---

## Убрать автосид после живого демо

1. В `fly.toml` убрать `demo:seed` из `release_command`.
2. `DEMO_AUTO_SEED=false`.
3. Отметить § H.0 в чеклисте В1.
