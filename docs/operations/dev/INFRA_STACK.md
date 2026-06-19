# Инфраструктура CoffeeOS (канон)

**Зачем:** один источник правды — что используем на стенде и что **запрещено** подключать без явного апрува владельца.

---

## Сейчас (демо / develop → Fly)

| Слой | Провайдер | Примечание |
|------|-----------|------------|
| **Приложение** | [Fly.io](https://fly.io) app `coffeeos` | Rails + Svelte в одном образе, `coffeeos.fly.dev` |
| **PostgreSQL** | **Fly Managed Postgres** (`coffeeos-db`, region `ams`) | `DATABASE_URL` через `fly mpg attach` |
| **Очереди / cache / cable** | Тот же Postgres (Solid Queue/Cache/Cable) | один `DATABASE_URL` |
| **Деплой** | GitHub Actions → `fly deploy` на push в `develop` | `release_command`: `bin/rails fly:release` |

Локально: PostgreSQL на машине разработчика (`LOCAL_DEV.md`).

---

## Не используем (без апрува не подключать)

| Сервис | Статус | Комментарий |
|--------|--------|-------------|
| **Supabase** | **Запрещено** | Никогда не был частью архитектуры CoffeeOS; случайный `DATABASE_URL` на внешний хост — убран |
| **Neon** | **Не используем** | Нет записей в репо; не подключать самостоятельно |
| **Render** | **Legacy, не используем** | Старый URL `coffeeos-ii8n.onrender.com` в README — **не деплоить**, не брать `DATABASE_URL` оттуда |
| Любой новый внешний Postgres/BaaS | **Только с апрува** | Сначала обсуждение + запись в этот файл |

**Правило для агента и разработчиков:** менять `DATABASE_URL`, добавлять новые облачные сервисы, MCP-провайдеры БД — **только по явному «go»** от владельца. Стек по умолчанию: **Fly app + Fly MPG**.

---

## Смена БД (если когда-либо понадобится)

1. Апрув владельца.
2. Обновить этот файл + `FLY_DEMO_STAND.md`.
3. `fly secrets unset DATABASE_URL` → `fly mpg attach …` (или иной канонический способ).
4. `fly deploy -a coffeeos` — дождаться зелёного `fly:release`.
5. Smoke: `/up` 200, `/shop?tenant_id=…` 200, `bin/smoke` или зона shop integration.

---

## Связанные доки

- [`FLY_DEMO_STAND.md`](../demo/FLY_DEMO_STAND.md) — деплой и troubleshooting
- [`LOCAL_DEV.md`](LOCAL_DEV.md) — локальная БД
- [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md) — URL витрины
