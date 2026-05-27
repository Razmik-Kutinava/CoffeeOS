# Локальная разработка (WSL / Linux)

**Назначение:** поднять CoffeeOS на машине разработчика — панели, витрина `/shop`, HMR.  
**Среда:** только **WSL (Linux)**. Rails + Vite + `npm install` — **в одной среде**, не смешивать с нативным Windows.

**Связано:** [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md) (режим URL витрины), [`milestones/veha_1/DEMO_LOGINS.md`](milestones/veha_1/DEMO_LOGINS.md) (логины), [`FLY_DEMO_STAND.md`](FLY_DEMO_STAND.md) (прод на Fly).

---

## Что не трогаем на проде

| Действие локально | Влияние на Fly / prod |
|-------------------|------------------------|
| `bin/rails db:migrate` | только **локальная** БД |
| `bin/rails demo:seed` | только **локальная** БД |
| `npm install` в WSL | только `node_modules` на диске |
| `ruby bin/dev` | только процессы на машине |

Код и секреты Fly **не меняются** от локального сида. На проде тот же **режим B** витрины: `/shop?tenant_id=<uuid>` (см. [`SHOP_URL_MODES.md`](SHOP_URL_MODES.md)).

---

## Требования

- **WSL2** (Ubuntu и т.п.)
- Репозиторий: `/mnt/c/Tools/workarea/CoffeeOS` или `~/projects/CoffeeOS`
- **Ruby 3.4.8** (rbenv / mise — см. `.ruby-version`, `mise.toml`)
- **Node 20+** (`node -v`)
- **PostgreSQL** локально, `DATABASE_URL` или `config/database.yml` → БД `coffeeos_development`
- Гемы: на `/mnt/c/` — `./bin/bundle install` (vendor в `~/.local/share/coffeeos-vendor/…`, см. `config/bundle_env.rb`)

---

## Первый запуск (чистая машина)

Все команды — **внутри WSL**, из корня репозитория:

```bash
cd /mnt/c/Tools/workarea/CoffeeOS

# 1. Ruby-зависимости
./bin/bundle install

# 2. Node (только в WSL — не запускать npm install из PowerShell на том же каталоге)
rm -rf node_modules
npm install

# 3. База
bin/rails db:create    # если БД ещё нет
bin/rails db:migrate
bin/rails demo:seed
bin/rails demo:shop_urls
```

После `demo:seed` в выводе будут **локальные** UUID точек и URL витрин — **сохрани их**, UUID на Fly другие.

---

## Ежедневный запуск

```bash
cd /mnt/c/Tools/workarea/CoffeeOS
ruby bin/dev
```

Поднимает через **foreman** (`Procfile.dev`):

| Процесс | Порт | Назначение |
|---------|------|------------|
| `web` — Rails (Puma) | **3001** | панели, API, оболочка `/shop` |
| `vite` — Vite dev | **3036** | HMR для Svelte-витрины |

Подожди в терминале:

- `Listening on http://127.0.0.1:3001`
- `VITE ... ready`

На `/mnt/c/` первый старт может занять **1–2 минуты** — не прерывать раньше времени.

Остановка: `Ctrl+C`.

### Только Rails (без HMR)

```bash
ruby bin/dev --rails-only
# или
ruby bin/server
```

Витрина возможна после `npm run vite:build` (статика) или при `autoBuild` в `config/vite.json`.

---

## Куда открывать браузер

| URL | Зачем |
|-----|--------|
| **http://127.0.0.1:3001/login** | вход в панели (УК, manager, barista…) |
| **http://127.0.0.1:3001/shop?tenant_id=…** | витрина точки |
| ~~http://localhost:3036~~ | **не открывать** — только HMR, не приложение |

**Важно:** локально только **`http://`**, не `https://`.  
`bin/rails demo:shop_urls` может печатать `https://localhost:3001/...` — для браузера замени на **`http://127.0.0.1:3001/...`**.

Пример после `demo:seed` (актуальные UUID — из **своего** вывода сида):

```
http://127.0.0.1:3001/shop?tenant_id=1cd79e79-44bf-4770-8fd3-1666669af27d   # demo-point-a
http://127.0.0.1:3001/shop?tenant_id=e13476e4-6855-4d70-bc87-e332abdfdc50   # demo-point-b
```

Пароль demo-пользователей: **`demo123456`** — [`milestones/veha_1/DEMO_LOGINS.md`](milestones/veha_1/DEMO_LOGINS.md).

---

## Как витрина понимает «какая точка»

Порядок резолва (`Shop::Concerns::TenantResolution`):

1. `?tenant_id=` в URL  
2. meta `shop-tenant-id` (Rails ставит на `/shop`, если точка найдена)  
3. поддомен `{slug}.localhost` (если `SHOP_BASE_DOMAIN=localhost` + `/etc/hosts`)  
4. `SHOP_DEFAULT_TENANT_ID` в `.env`  
5. dev-fallback: slug `test-cafe` или первая точка в БД  

API: **`GET /shop/api/categories?tenant_id=...`** — без валидной точки **404/422**, меню пустое.

Проверка точки и каталога (development):

```
http://127.0.0.1:3001/shop/api/debug?tenant_id=<uuid>
```

---

## Типичные проблемы

| Симптом | Причина | Решение |
|---------|---------|---------|
| **500 PendingMigrationError** | не прогнаны миграции | `bin/rails db:migrate`, перезапустить `bin/dev` |
| **`/shop/api/categories` 404** | неверный или старый `tenant_id` | `bin/rails demo:seed` + URL из вывода; не брать UUID с Fly из docs |
| **chrome-error / страница не грузится** | сервер не запущен или `https://` | `ruby bin/dev`, открыть **`http://127.0.0.1:3001`** |
| **Пустая витрина, жёлтый баннер** | нет `tenant_id` / точка не в БД | `/shop?tenant_id=...` или `SHOP_DEFAULT_TENANT_ID` в `.env` |
| **CSP: ws://127.0.0.1:3036 blocked** | CSP режет WebSocket Vite | В **development** CSP разрешает ws :3036; после pull — **перезапустить `bin/dev`** |
| **Заказ barista без order_number** | триггер не в schema.rb | `bin/rails db:ensure_triggers` (или `db:migrate`); в test/dev — auto на boot |
| **Vite / rolldown binding** | `npm install` делали в Windows на том же `node_modules` | `rm -rf node_modules && npm install` **только в WSL** |
| **Долго «Booting Puma»** | проект на `/mnt/c/` (медленный I/O) | подождать; опционально клон в `~/projects/` на ext4 |

---

## После pull / новых миграций

```bash
./bin/bundle install          # если изменился Gemfile
npm install                   # если изменился package.json
bin/rails db:migrate
bin/rails demo:seed           # при необходимости обновить demo-данные
ruby bin/dev
```

---

## Сверка с продом (Fly)

| | Локально (сейчас) | Fly demo |
|---|-------------------|----------|
| Режим витрины | **B** — `?tenant_id=` | **B** — `?tenant_id=` |
| `SHOP_BASE_DOMAIN` | обычно не задан | не задан |
| URL пример | `http://127.0.0.1:3001/shop?tenant_id=…` | `https://coffeeos.fly.dev/shop?tenant_id=…` |
| UUID точек | из **`demo:seed` локально** | из **`fly ssh` / demo на Fly** |

UUID из [`DEMO_LOGINS.md`](milestones/veha_1/DEMO_LOGINS.md) (колонка Fly) **не подставлять локально** — они другие.

Команда для URL всех точек текущей БД:

```bash
bin/rails demo:shop_urls
```

---

## Чеклист «локалка работает»

- [ ] WSL, `ruby bin/dev`, в терминале `Listening` + `VITE ready`
- [ ] http://127.0.0.1:3001/login — форма входа
- [ ] `uk@demo.coffeeos.local` / `demo123456` → `/admin`
- [ ] `/shop?tenant_id=<uuid demo-point-a>` — категории и товары
- [ ] `/shop?tenant_id=<uuid demo-point-b>` — другое меню/то же по PTS (проверка изоляции)

---

## История (2026-05-27)

Зафиксирован рабочий цикл после отладки локального подъёма:

1. Откат Windows-специфичных правок в `bin/dev` — снова только **foreman + WSL**.
2. `db:migrate` — снятие `PendingMigrationError`.
3. `demo:seed` + `demo:shop_urls` — точки, меню, локальные URL.
4. `ruby bin/dev` — Rails **:3001** + Vite **:3036** в одной WSL-сессии.
5. Витрина — **`http://127.0.0.1:3001/shop?tenant_id=...`**, UUID из вывода сида, не с Fly.
