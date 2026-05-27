# Журнал прогона MCP DevTools — онбординг В2

**Дата:** 2026-05-27  
**Среда:** WSL, `ruby bin/dev`, `http://127.0.0.1:3001`  
**Данные:** `demo:seed` + org `MCP Accept Org` (создана в прогоне)  
**Каталог:** [`ONBOARDING_DEVTOOLS_SCENARIOS.md`](ONBOARDING_DEVTOOLS_SCENARIOS.md)

**Итог прогона (MCP + API):** **34 PASS**, **0 FAIL**, **24 SKIP/MAN** (не прогоняли в этой сессии или только руками).

**Rails integration (контроль, не MCP):** 23 runs, **22 PASS**, **1 FAIL** — `OnboardingConnectivityTest#test_barista_order_from_onboarded_tenant_appears_on_manager_shift_view` («barista должен создать заказ в открытой смене»). **→ CON-03/CON-04 требуют ручной проверки или фикса теста.**

**Блок ONBOARDING_CHECKLIST §1–7:** `[x]` по коду; **приёмка MCP — частично `[x]`** (см. чеклист § «Приёмка»); заказчик и деплoy — нет.

**Деплой на prod:** **не апрувнут** — после review этого журнала.

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

## Замечания

1. **CSP WebSocket Vite** (`ws://127.0.0.1:3036`) — предупреждение в консоли; HMR может не работать, **витрина и API не ломаются**.
2. **С product card → /login** при клике с главной витрины — обход через категорию + quick-add (SHP-07).
3. **Дубликаты MCP Accept Org** в combobox — от повторных прогонов; на prod не влияет.
4. **Следующий прогон MCP (готов к запуску):** TEN-02..04 (3 точки на чистой org), **CON-01** (цена УК → витрина), **SHP-08** (simulate), связь всех панелей..

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
