# Инфраструктура CoffeeOS (канон)

**Зачем:** один источник правды — стек стенда, биллинг, **кто и когда может деплоить**.

---

## Сейчас (демо / develop → Fly)

| Слой | Провайдер | Примечание |
|------|-----------|------------|
| **Приложение** | [Fly.io](https://fly.io) app `coffeeos` | Rails + Svelte, `coffeeos.fly.dev` |
| **PostgreSQL** | **[Neon](https://console.neon.tech)** проект `coffeeos`, branch `production`, Frankfurt | `DATABASE_URL` в Fly secrets (pooled connection string) |
| **План Neon** | **Launch** (~$0.106/CU-hr) | Оплата с 2026-06-19; ориентир **~$12/мес** при ~110 CU-hrs |
| **Очереди / cache / cable** | Тот же Neon Postgres | один `DATABASE_URL` |
| **CI deploy** | **Выключен на push** | только `workflow_dispatch` — см. § Деплой |

Локально: PostgreSQL (`LOCAL_DEV.md`).

**Fly Managed Postgres `coffeeos-db`:** удалён 2026-06-19 (был ~$38/мес, ошибочно создан).

---

## Деплой — только по апруву владельца

| Кто | Правило |
|-----|---------|
| **Агент** | `fly deploy`, `fly secrets set`, смена `DATABASE_URL`, новые облака — **только после явного «deploy» / «go»** от владельца |
| **GitHub Actions** | `.github/workflows/deploy.yml` — **только ручной запуск** (`workflow_dispatch`), **не** на каждый push в `develop` |
| **Владелец** | Локально: `./bin/fly_deploy.sh` или `fly deploy -a coffeeos --depot=false` (Depot 401 → см. `FLY_DEMO_STAND.md`) |

**Экономия Neon:** каждый `fly deploy` → `fly:release` → `db:prepare` + `demo:seed` будит compute. Лишние деплои = лишние CU-hrs. Деплой **после зелёных тестов локально**, не «на каждый коммит».

После деплоя: `/up` 200, `/shop?tenant_id=…` 200, `fly logs \| grep "Shop A:"`.

---

## Neon — лимиты расходов (обязательно)

1. [Neon Console → Billing](https://console.neon.tech/app/billing) → **Spending limit** → **$15/мес** → **Enable**.
2. Пока Neon не даёт auto-suspend на org limit — **email alerts** на 80% и 100%. При появлении опции **Suspend projects** — включить.
3. Рекомендуется: **Spending limit $15** + не деплоить без нужды.

Оценка Launch: `CU-hours × $0.106` + storage копейки. Storage сейчас ~0.04 GB.

---

## Запрещено без апрува

| Сервис | Статус |
|--------|--------|
| **Supabase** | Запрещено |
| **Fly MPG / внешний Postgres** | Не использовать; канон — **Neon `coffeeos`** |
| **Render** | Legacy URL в README — не деплоить |
| Любой новый BaaS | Только «go» + запись в этот файл |

---

## Смена DATABASE_URL

1. Апрув владельца.
2. Обновить этот файл + `FLY_DEMO_STAND.md`.
3. `fly secrets set DATABASE_URL=... -a coffeeos`
4. `fly deploy -a coffeeos` (по апруву).
5. Smoke `/up`, `/shop`.

---

## Связанные доки

- [`FLY_DEMO_STAND.md`](../demo/FLY_DEMO_STAND.md)
- [`LOCAL_DEV.md`](LOCAL_DEV.md)
- [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md)
