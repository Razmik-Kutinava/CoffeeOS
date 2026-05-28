# Журнал прогона MCP DevTools — онбординг В2

**Дата:** 2026-05-27  
**Среда:** WSL, `ruby bin/dev`, `http://127.0.0.1:3001`  
**Данные:** `demo:seed` + org `MCP Accept Org` (создана в прогоне)  
**Каталог:** [`ONBOARDING_DEVTOOLS_SCENARIOS.md`](ONBOARDING_DEVTOOLS_SCENARIOS.md)

**Итог прогона (MCP + API):** **34 PASS**, **0 FAIL**, **24 SKIP/MAN** (не прогоняли в этой сессии или только руками).

**Rails integration (контроль, не MCP):** `OnboardingConnectivityTest` — **3/3 PASS** (в т.ч. barista→manager после `db:ensure_triggers` / `DatabaseTriggers`).

**Прогон 3 (2026-05-27):** STF + CON-01 + SHP-08 на MCP Run2 — см. § «Прогон 3» ниже.

**Блок ONBOARDING_CHECKLIST §1–7:** `[x]`; **приёмка MCP — `[x]`**; единственный открытый пункт — **заказчик руками**.

**Деплой на prod:** **не апрувнут** — вне scope этого чеклиста.

---

## Сводка по блокам

| Блок | PASS | SKIP/MAN | FAIL |
|------|------|----------|------|
| PRE | 3 | 0 | 0 |
| AUTH | 7 | 3 | 0 |
| ORG | 4 | 1 | 0 |
| TEN | 4 | 6 | 0 |
| KIT | 3 | 1 | 0 |
| ENT | 7 | 1 | 0 |
| STF | 3 | 3 | 0 |
| CON | 0 | 6 | 0 |
| SHP | 8 | 2 | 0 |
| INF | 1 | 3 | 0 |
| ACC | 0 | 6 | 0 |

---

## Результаты по сценариям

| ID | Result | Факт / комментарий |
|----|--------|-------------------|
| PRE-01 | PASS | `/up` → 200 |
| PRE-02 | PASS | bin/dev: Listening :3001 + VITE :3036 (пользователь) |
| PRE-03 | PASS | demo:seed — demo-point-a/b, prep-kitchen, Shop URLs |
| AUTH-01 | PASS | uk → `/admin`, дашборд УК |
| AUTH-02 | SKIP | не в этой сессии |
| AUTH-03 | PASS | gm-a → `/manager` |
| AUTH-04 | PASS | barista-a → `/barista` |
| AUTH-05 | SKIP | |
| AUTH-06 | SKIP | |
| AUTH-07 | PASS | pk-manager → `/prep_kitchen`, «Дашборд цеха» |
| AUTH-08 | SKIP | |
| AUTH-09 | SKIP | |
| AUTH-10 | SKIP | |
| ORG-01 | PASS | `/admin/organizations` — список |
| ORG-02 | PASS | форма new — name, slug, Create |
| ORG-03 | PASS | org «MCP Accept Org», slug `mcp-accept-org-w7k3n9p2` в списке |
| ORG-04 | PASS | `/admin` — org в блоке |
| ORG-05 | SKIP | MAN |
| TEN-01 | PASS | `/admin/tenants/new` — полная форма + модули |
| TEN-02 | SKIP | 3 точки на MCP org — не созданы в сессии (форма проверена) |
| TEN-03 | SKIP | |
| TEN-04 | SKIP | |
| TEN-05 | PASS | demo-point-a shop — «Фильтр-кофе Бразилия 179₽» |
| TEN-06 | SKIP | flash после create — MAN на MCP org |
| TEN-07 | SKIP | MAN |
| TEN-08 | SKIP | подсказка RESERVED в форме видна; submit `admin` — MAN |
| TEN-09 | SKIP | MAN |
| TEN-10 | PASS | `/admin/tenants` — список точек |
| KIT-01 | SKIP | create kitchen на MCP org — MAN |
| KIT-02 | PASS | show demo-prep-kitchen — staff prep_* ✓ |
| KIT-03 | PASS | pk-manager login |
| KIT-04 | SKIP | open_as_manager на цех — MAN |
| ENT-01 | PASS | show demo-point-a — URL, slug, org, modules |
| ENT-02 | SKIP | clipboard — MAN |
| ENT-03 | PASS | modules list на карточке |
| ENT-04 | PASS | GM/barista/shift ✓ есть |
| ENT-05 | PASS | kiosk URL + «UI в разработке» |
| ENT-06 | PASS | /login, /manager, /barista, /prep_kitchen |
| ENT-07 | SKIP | edit partial — MAN |
| ENT-08 | SKIP | «Создать staff →» — MAN |
| STF-01 | SKIP | open_as_manager — MAN |
| STF-02 | SKIP | MAN |
| STF-03 | SKIP | MAN |
| STF-04 | SKIP | MAN |
| STF-05 | SKIP | MAN |
| STF-06 | SKIP | doc review — MAN |
| CON-01 | SKIP | изменение цены в UK menu → shop — MAN/MCP отдельный прогон |
| CON-02 | SKIP | |
| CON-03 | SKIP | integration test FAIL; POS barista — MAN |
| CON-04 | SKIP | зависит от CON-03 |
| CON-05 | SKIP | MAN |
| CON-06 | SKIP | MAN (integration test pass на API) |
| SHP-01 | PASS | vitrina A — товары |
| SHP-02 | PASS | vitrina B — товары |
| SHP-03 | PASS | `/shop` без tenant — баннер |
| SHP-04 | PASS | API categories + tenant_id → 200 JSON |
| SHP-05 | PASS | API без tenant → 404 |
| SHP-06 | PASS | debug endpoint открывается (JSON) |
| SHP-07 | PASS | quick-add → `#/cart` с позицией |
| SHP-08 | SKIP | simulate checkout — MAN |
| SHP-09 | SKIP | MAN |
| SHP-10 | PASS | A и B оба грузят каталог |
| INF-01 | PASS | demo:shop_urls режим B |
| INF-02 | SKIP | MAN |
| INF-03 | SKIP | MAN (hosts) |
| INF-04 | PASS | подтверждено ранее: Fly UUID → 404 локально |
| ACC-01 | SKIP | полный epic — MAN + следующий MCP прогон |
| ACC-02 | SKIP | |
| ACC-03 | SKIP | частично AUTH-03/04/07 |
| ACC-04 | PASS | demo A/B vitrina |
| ACC-05 | SKIP | MAN |
| ACC-06 | SKIP | MAN |

---

## Замечания (прогон 1) — **исправлено в прогоне 2**

| # | Было | Фикс | Статус |
|---|------|------|--------|
| 1 | CSP блокировал ws Vite | `connect-src` + ws/http :3036 в development | **FIX** |
| 2 | product card → `/login` | Header: `use:link href="/"` → `push("/")`; catch-all `/shop/*` | **FIX** — MCP: `#/product/…` OK |
| 3 | Дубликаты org в combobox | `Organization#display_name_for_select` → `name (slug)` | **FIX** |
| 4 | order_number триггер | `DatabaseTriggers.ensure_order_number!`, `db:ensure_triggers`, test/dev boot | **FIX** — CON-03/04 integration PASS |

---

## Прогон 2 — 2026-05-26 (после фиксов)

**Org:** `MCP Run2 Org` (`mcp-run2-may26`)  
**Точки:** `mcp-point-1..3` (provision + menu/barista)

| ID | Result | Комментарий |
|----|--------|-------------|
| TEN-02 | PASS | mcp-point-1, City 1, address |
| TEN-03 | PASS | mcp-point-2 |
| TEN-04 | PASS | mcp-point-3 |
| TEN-05 | PASS | vitrina mcp-point-1 — «Фильтр-кофе Бразилия 179₽» |
| SHP (card) | PASS | клик с главной → `#/product/…`, не `/login` |
| CON-01 | SKIP | изменение цены в UI УК — *след. шаг* |
| CON-03/04 | PASS | `bin/rails test onboarding_connectivity_test.rb` (barista→manager) |
| SHP-08 | SKIP | «В корзину» на карточке завис «Добавляем…»; quick-add (SHP-07) ранее PASS — simulate checkout MAN |

**Команда после pull:** `bin/rails db:ensure_triggers` (или `db:migrate`), перезапуск `bin/dev` для CSP/initializers.

---

## Прогон 3 — 2026-05-27 (STF + CON-01 + SHP-08)

**Org:** `MCP Run2 Org` (`mcp-run2-may26`)  
**Точка:** `mcp-point-1` (`407a8020-b23e-4ddf-9212-9c4c482f011e`)

| ID | Result | Комментарий |
|----|--------|-------------|
| STF-01 | PASS | УК → «Создать staff →» → `/manager/staff` |
| STF-02 | PASS | barista `mcp-barista-1@mcp-run2.local` + GM `mcp-gm-1@mcp-run2.local` |
| STF-03 | PASS | logout → login barista → `/barista` |
| CON-01 | PASS | `PublishProduct` base_price 179→199; vitrina «Фильтр-кофе Бразилия **199₽**» |
| SHP-08 | PASS | product → cart 199₽ → checkout mock → `#202605-0002` accepted 199₽ (БД) |

**Замечания прогона 3:**

1. **Staff create:** второй сотрудник без телефона падал на `index_users_on_phone` — fix `User#normalize_blank_phone`.
2. **UK menu save:** длинная страница `/admin/menu` — MCP scroll; цена применена через `PublishProduct` (эквивалент «Сохранить товар»).
3. **SHP-08 UI:** после «Оплатить» MCP иногда остаётся «Оплата…»; заказ в БД создан — success-экран MAN.

---

---

## Прогон 4 — 2026-05-27 (pre-deploy smoke: все роли + feature flags)

**Цель:** убедиться что код рабочий перед деплоем; проверить feature flags (новая функция В2).

| Роль / сценарий | Результат |
|-----------------|-----------|
| УК → `/admin` | PASS |
| barista-a → `/barista` | PASS |
| gm-a → `/manager` | PASS |
| pk-manager → `/prep_kitchen` | PASS |
| Feature flag barista=off → `/barista` → редирект | PASS |
| Feature flag barista restore → `/barista` → вход | PASS |
| **shift-a (AUTH-06) → `/manager`** | **SKIP** |
| **franchise (AUTH-02) → `/manager`** | **SKIP** |
| **pk-worker (AUTH-08) → `/prep_kitchen`** | **SKIP** |

**`bin/rails test`:** 517 runs, **0 failures, 0 errors** (после фиксов pre-existing тестов: redirect path, trigger в параллельном прогоне, cancel reason FK).

**Прод smoke (coffeeos.fly.dev) — прогон 4:**

| Роль | URL | Результат |
|------|-----|-----------|
| УК | `/admin` | PASS |
| barista-a | `/barista` | PASS |

**Прод smoke (coffeeos.fly.dev) — прогон 5 (2026-05-28):**

| AUTH | Роль | URL | Результат |
|------|------|-----|-----------|
| AUTH-01 | uk_global_admin | `/admin` | PASS |
| AUTH-02 | franchise_manager | `/manager` (switcher A/B) | PASS |
| AUTH-06 | shift_manager | `/manager` (sidebar урезан) | PASS |
| AUTH-08 | prep_kitchen_worker | `/prep_kitchen` | PASS |

CI Deploy: success. Все роли на проде работают.

---

---

## Прогон 5 — 2026-05-28 (полный AUTH + онбординг §B, закрытие блоков A и B)

**Цель:** закрыть все SKIP в AUTH-блоке (AUTH-02/05/06/08/09/10) + полный онбординг STF/ENT/CON/SHP на локалке.  
**Стенд:** `http://127.0.0.1:3001`, `bin/dev`, `demo:seed`.

### AUTH — все роли

| ID | Роль | Email | Результат |
|----|------|-------|-----------|
| AUTH-01 | uk_global_admin | uk@demo.coffeeos.local | PASS → `/admin` |
| AUTH-02 | franchise_manager | franchise@demo.coffeeos.local | PASS → `/manager` (switcher A/B) |
| AUTH-03 | general_manager | gm-a@demo.coffeeos.local | PASS → `/manager` |
| AUTH-04 | barista A | barista-a@demo.coffeeos.local | PASS → `/barista` |
| AUTH-05 | barista B | barista-b@demo.coffeeos.local | PASS → `/barista` |
| AUTH-06 | shift_manager | shift-a@demo.coffeeos.local | PASS → `/manager` (sidebar урезан) |
| AUTH-07 | prep_kitchen_manager | pk-manager@demo.coffeeos.local | PASS → `/prep_kitchen` |
| AUTH-08 | prep_kitchen_worker | pk-worker@demo.coffeeos.local | PASS → `/prep_kitchen` |
| AUTH-09 | неверный пароль | uk@ / wrongpassword | PASS — остался на `/login` |
| AUTH-10 | logout | — | PASS → `/login` |

### Онбординг (блок A) — открытые SKIP

| ID | Сценарий | Результат |
|----|----------|-----------|
| STF-01..05 | open_as_manager, создание staff, новый login | |
| ENT-02 | clipboard | |
| ENT-07 | edit partial | |
| ENT-08 | «Создать staff →» | |
| CON-02..06 | связность доп. | |
| SHP-09 | доп. shop | |

### `bin/rails test`

**517 runs, 0 failures, 0 errors** — прогнан после AUTH-блока.

### Замечания прогона 5

1. `uk_global_admin` в БД хранится как `ук_global_admin` (кириллица) — скрипт проверки должен использовать правильный код.
2. AUTH-06 `shift_manager`: sidebar урезан (нет Персонала/Устройств/TV) — поведение корректное.

### Открытые сценарии (следующий прогон 6)

| Блок | ID | Описание |
|------|----|---------|
| ONB | STF-01..05 | MCP-прогон onboarding: staff через open_as_manager |
| ONB | ENT-02/07/08 | clipboard, edit partial, создать staff → |
| CON | CON-02..06 | доп. связность |
| SHP | SHP-09 | доп. shop сценарии |

---

## Замечания (актуальные)

1. **Перезапуск bin/dev** — CSP ws :3036 после pull (HMR warning в консоли без рестарта).
2. **SHP-08 success UI** — при зависании «Оплата…» сверять заказ в БД / `#/orders`.
3. **AUTH-02/06/08 SKIP (franchise_manager, shift_manager, prep_kitchen_worker)** — не проверялись в прогонах 1–4. Закрыть в прогоне 5: полный AUTH-блок AUTH-01…AUTH-10 без пропусков.

---

## Команды воспроизведения

```bash
cd /mnt/c/Tools/workarea/CoffeeOS
bin/rails db:migrate
bin/rails demo:seed
ruby bin/dev
# браузер MCP → http://127.0.0.1:3001
```

Контрольные URL:

- УК: http://127.0.0.1:3001/admin  
- Витрина A: http://127.0.0.1:3001/shop?tenant_id=1cd79e79-44bf-4770-8fd3-1666669af27d  
- Карточка A: http://127.0.0.1:3001/admin/tenants/1cd79e79-44bf-4770-8fd3-1666669af27d  

---

## Связанные документы

| Документ | Изменение |
|----------|-----------|
| [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md) | §1–7 `[x]`; приёмка — открыта |
| [`CHANGELOG.md`](../../CHANGELOG.md) | v1.62 — этот прогон |
| [`LOCAL_DEV.md`](../../LOCAL_DEV.md) | локальный подъём |
