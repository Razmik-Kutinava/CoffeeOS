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

1. **Рекомендуемый деплой из репо:** `./bin/fly_deploy.sh` (`--remote-only --depot=false`, как CI).
2. Вручную: `fly deploy -a coffeeos --remote-only --depot=false`
3. Обновить CLI: `fly version update` (старые версии чаще ловят 401).
4. Если снова 401 на registry: `fly auth docker`, затем повтор.
5. Запасной вариант (нужен локальный Docker): `fly deploy -a coffeeos --local-only`

**Проверка после деплоя:** `/up` → 200; витрина «Витрины А» открывается (URL ниже).

**Transient warning** `not listening on 0.0.0.0:3000` во время rolling update — обычно Puma ещё поднимается; если `/up` зелёный через 1–2 мин — ок.

---

### 4. WSL: `docker.sock` / `load build context` / `missing hostname`

**Симптомы:**

- `ERROR [internal] load build context` при деплое из `/mnt/c/...`
- `failed to parse daemon host "unix:///var/run/docker.sock": missing hostname`
- `WARN Failed to start remote builder heartbeat`

**Причина:** репо на **Windows mount** (`/mnt/c/`) — медленный upload контекста; плюс `flyctl` пытается трогать локальный Docker (на WSL часто нет daemon или битый `DOCKER_HOST`).

**Что делать:**

1. **`./bin/fly_deploy.sh`** — скрипт сам: `unset DOCKER_HOST`, `--remote-only`, при `/mnt/*` — `git archive` → `~/.cache/coffeeos-fly-deploy` + overlay незакоммиченных файлов.
2. Без staging (если репо уже в `~/CoffeeOS`): `FLY_DEPLOY_NO_STAGE=1 ./bin/fly_deploy.sh`
3. Обновить CLI: `fly version update`
4. Запасной вариант: GitHub Actions → **Deploy to Fly.io** (workflow_dispatch)

---

### 5. `fly:release` / `db:prepare` failed

**Канон БД:** **Neon** проект `coffeeos` — см. [`../dev/INFRA_STACK.md`](../dev/INFRA_STACK.md).

| Ошибка | Действие |
|--------|----------|
| `exceeded the compute time quota` | Neon Launch + spending limit $15 |
| `connection refused` | `fly secrets list` → `DATABASE_URL` |
| `ConcurrentMigrationError` / `db:migrate:queue` lock busy | queue/cache/cable = тот же Neon URL; в `fly:release` пустые migrate skip, lock+marker → WARN skip. Передеплой с фиксом; не руками unlock |
| release упал, образ собран | `fly ssh console -a coffeeos -C "bin/rails fly:release"` (**по апруву**) |

**Деплой:** только по апруву владельца (лишний deploy = CU-hrs на Neon).

С `2026-06-19`: `bin/docker-entrypoint` не блокирует Puma при временном fail `db:prepare` — `/up` может быть 200, витрина без БД → 500.

---

## После каждого деплоя (автоматически)

`fly.toml`:

- `release_command`: `bin/rails fly:release` (`db:prepare` + solid migrate + `demo:seed`)
- `SHOP_BASE_DOMAIN` **не задан** — витрина `?tenant_id=` (режим B)
- `DEMO_AUTO_SEED=false` (с 2026-09-16) — автосид на публичном fly.dev выключен; ручной `demo:seed` по SSH при необходимости

**Чеклист:** [`../milestones/veha_1/checklists/CHECKLIST.md`](../milestones/veha_1/checklists/CHECKLIST.md) § H.0.

---

## Актуальные ссылки (прод, с 2026-10-06 — одна точка)

| Что | URL | Логин |
|-----|-----|-------|
| Вход | https://coffeeos.fly.dev/login | — |
| УК | https://coffeeos.fly.dev/admin | `razmikg1988@gmail.com` |
| Табло бариста | https://coffeeos.fly.dev/barista | `barista-code-black@codeblack.coffee` |
| Витрина «Витрины А» | https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 | гость |

Пароли — у владельца, в репо не пишем. Демо-логины `*@demo.coffeeos.local` точек и `demo123456` удалены 2026-10-06.

## Узнать URL витрин

### A. УК в браузере

1. https://coffeeos.fly.dev/login → вход УК  
2. Админка → точки → открыть **«Витрина А»** → скопировать **id** (UUID).  
3. Витрина: `https://coffeeos.fly.dev/shop?tenant_id=<этот-uuid>`

### B. SSH (если туннель заработал)

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

**На проде не запускать** — прод очищен от демо-данных 2026-10-06 (`DEMO_AUTO_SEED=false`). Только для отдельного demo-стенда, по апруву:

```bash
fly ssh console -a coffeeos
cd /rails && bin/rails demo:seed
```

---

## Витрины (режим B)

| Точка | Slug | Как открыть |
|-------|------|-------------|
| «Витрина А» | `code_black` | https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789 |

Slug в БД **не меняется** — при своём домене витрина по slug, см. режим A ниже.

---

## Когда появится свой домен (режим A)

[`../dev/SHOP_URL_MODES.md`](../dev/SHOP_URL_MODES.md) § «Переход B → A».

---

## Убрать автосид после живого демо

1. В `fly.toml` убрать `demo:seed` из `release_command`.
2. `DEMO_AUTO_SEED=false`.
3. Отметить § H.0 в чеклисте В1.

---


| Secret | Назначение | Обязательно |
|--------|------------|-------------|
| `TBANK_TERMINAL_KEY` | Терминал Т-Банка | да (card) |
| `TBANK_PASSWORD` | Пароль терминала | да |
| `TBANK_RETURN_URL` | Return URL callback | да |
| **`TBANK_RSA_PUBLIC_KEY`** | Публичный RSA ключ терминала для **CardData** (новая карта) | **да для R2** |

**Где взять `TBANK_RSA_PUBLIC_KEY`:** ЛК Т-Бизнес → Магазины → терминал → настройки nonPCI / публичный ключ.  
**Формат:** PEM целиком (`-----BEGIN PUBLIC KEY-----` … `-----END PUBLIC KEY-----`).

```bash
# Пример (по апруву владельца):
fly secrets set TBANK_RSA_PUBLIC_KEY="$(cat path/to/tbank_public.pem)" -a coffeeos
```

**Проверка после deploy:**

```bash
# На витрине с tenant_id — в DevTools Network:
```




```powershell
$env:FLY_BIN = "C:\Users\darks\.fly\bin\flyctl.exe"
```

