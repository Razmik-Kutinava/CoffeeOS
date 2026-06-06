# Сценарии MCP DevTools — онбординг В2

**Назначение:** реалистичный прогон «как заказчик» через Chrome DevTools MCP на локалке.  
**Прогон:** [`ONBOARDING_DEVTOOLS_RUN.md`](ONBOARDING_DEVTOOLS_RUN.md).  
**Чеклист:** [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md). **Локальный подъём:** [`../../dev/LOCAL_DEV.md`](../../dev/LOCAL_DEV.md).

**Стенд прогона:** `http://127.0.0.1:3001`, `bin/dev`, после `demo:seed`.  
**Пароль demo:** `demo123456` — [`../veha_1/DEMO_LOGINS.md`](../veha_1/DEMO_LOGINS.md).

**Tenant ID (после `demo:seed`, сверять с выводом):**

| Slug | UUID (пример 2026-05-27) |
|------|---------------------------|
| demo-point-a | `1cd79e79-44bf-4770-8fd3-1666669af27d` |
| demo-point-b | `e13476e4-6855-4d70-bc87-e332abdfdc50` |
| demo-prep-kitchen | `8f942749-689d-4e5a-a991-e8fb6324768f` |

**Легенда:** `MCP` — автоматизация browser MCP; `MAN` — только руками; `API` — curl/JSON без UI.

---

## PRE — подготовка

| ID | Итог (критерий успеха) | Шаги | Канал |
|----|------------------------|------|-------|
| PRE-01 | Сервер жив | GET `/up` → 200 | API |
| PRE-02 | Vite + Rails | `ruby bin/dev`, в логе Listening + VITE ready | MAN |
| PRE-03 | Demo-данные | `demo:seed` без ошибки, Shop A/B URL в выводе | MAN |

---

## AUTH — входы по ролям

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| AUTH-01 | УК в `/admin` | `/login` → uk@demo.coffeeos.local / demo123456 → URL `/admin` | MCP |
| AUTH-02 | Франчайзи в manager | franchise@… → `/manager` | MCP |
| AUTH-03 | GM точки A | gm-a@… → `/manager` | MCP |
| AUTH-04 | Barista A | barista-a@… → `/barista` | MCP |
| AUTH-05 | Barista B | barista-b@… → `/barista` | MCP |
| AUTH-06 | Shift manager A | shift-a@… → `/manager` | MCP |
| AUTH-07 | Prep kitchen manager | pk-manager@… → `/prep_kitchen` | MCP |
| AUTH-08 | Prep kitchen worker | pk-worker@… → `/prep_kitchen` | MCP |
| AUTH-09 | Неверный пароль | login с bad password → остаётся на login, ошибка | MCP |
| AUTH-10 | Logout | Выйти → снова `/login` | MCP |

---

## ORG — §1 организация

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| ORG-01 | Список org | UK → `/admin/organizations` — таблица/ссылки | MCP |
| ORG-02 | Форма новой org | `/admin/organizations/new` — name, slug, submit | MCP |
| ORG-03 | Создание org | name «Accept Org MCP», slug `mcp-accept-org-*` → редирект, org в списке | MCP |
| ORG-04 | Org в дашборде УК | `/admin` — блок организаций содержит новую org | MCP |
| ORG-05 | Дубликат slug org | повтор slug → ошибка валидации | MAN |

---

## TEN — §2 точки продаж (×3)

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| TEN-01 | Форма новой точки | `/admin/tenants/new` — org, name, slug, type, address, modules | MCP |
| TEN-02 | Точка 1 sales_point | org MCP, slug `mcp-point-1`, address, modules barista+menu on, kiosk off → success | MCP |
| TEN-03 | Точка 2 sales_point | slug `mcp-point-2`, другой address | MCP |
| TEN-04 | Точка 3 sales_point | slug `mcp-point-3` | MCP |
| TEN-05 | Меню не пустое | после create → shop URL с tenant_id → категории/товары | MCP |
| TEN-06 | Flash URL после create | redirect/show с URL витрины `?tenant_id=` | MCP |
| TEN-07 | Дубликат slug tenant | тот же slug → ошибка | MAN |
| TEN-08 | RESERVED slug `admin` | slug admin → ошибка, подсказка в форме | MCP |
| TEN-09 | RESERVED slug `api` | slug api → ошибка | MAN |
| TEN-10 | Список точек | `/admin/tenants` — все 3 MCP-точки + demo | MCP |

---

## KIT — §3 заготовочный цех

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| KIT-01 | Создание production_kitchen | type «Кухня», slug `mcp-prep-*`, module prep_kitchen | MCP |
| KIT-02 | Карточка цеха | show tenant — staff prep_kitchen_* ✓ | MCP |
| KIT-03 | Вход pk-manager | login → `/prep_kitchen`, дашборд | MCP |
| KIT-04 | open_as_manager на цех | UK → карточка цеха → «Открыть manager» → `/manager` | MCP |

---

## ENT — §4 карточка «все входы»

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| ENT-01 | Show demo-point-a | URL витрины с tenant_id, slug, org | MCP |
| ENT-02 | Копировать URL | кнопка «Копировать» — буфер (или alert) | MAN |
| ENT-03 | Модули on/off | список модулей на карточке совпадает с edit | MCP |
| ENT-04 | Staff checklist | GM/barista/shift — ✓ есть на demo A | MCP |
| ENT-05 | Kiosk hint | киоск URL + «UI в разработке» | MCP |
| ENT-06 | Панели /login /manager /barista | ссылки на карточке | MCP |
| ENT-07 | Блок на edit | `/admin/tenants/:id/edit` — partial entry points | MCP |
| ENT-08 | «Создать staff →» | кнопка → manager staff или open_as_manager | MCP |

---

## STF — §5 staff

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| STF-01 | open_as_manager demo A | UK → «Менеджер»/«Открыть manager» → session manager | MCP |
| STF-02 | Список staff | `/manager/staff` — barista-a, gm-a в списке | MCP |
| STF-03 | Создать staff | manager → staff → add email+password+barista → success | MAN |
| STF-04 | Новый staff login | logout → login новым → `/barista` | MAN |
| STF-05 | Staff на каждой sales_point | повторить open_as_manager для B | MCP |
| STF-06 | Документ STAFF_ACCESS | пароль/сброс описаны | MAN |

---

## CON — §6 связность (УК → точки → панели → витрина)

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| CON-01 | Цена в УК → витрина | UK menu → изменить base_price продукта → Publish → shop API/витрина новая цена | MCP/MAN |
| CON-02 | PTS только на точке | цена на A изменилась, B — своя (или общий каталог) | MCP |
| CON-03 | Barista заказ | barista → POS → создать заказ в открытой смене | MAN |
| CON-04 | Manager видит заказ | gm → смена/orders — заказ из CON-03 | MAN |
| CON-05 | RLS заказов | заказ A не виден на B (manager) | MAN |
| CON-06 | Prep movement RLS | movement чужого tenant не confirm | MAN |

---

## SHP — витрина /shop

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| SHP-01 | Витрина A | `/shop?tenant_id=A` — категории/товары (179₽ и т.д.) | MCP |
| SHP-02 | Витрина B | tenant_id B — каталог загружается | MCP |
| SHP-03 | Без tenant_id | `/shop` — баннер SHOP_DEFAULT_TENANT_ID | MCP |
| SHP-04 | API categories A | GET `/shop/api/categories?tenant_id=A` → 200 JSON | API |
| SHP-05 | API без tenant | GET `/shop/api/categories` → 404 (не 500) | API |
| SHP-06 | API debug | GET `/shop/api/debug?tenant_id=A` → tenant + products count | API |
| SHP-07 | Корзина add | категория → quick-add → `#/cart` позиции | MCP |
| SHP-08 | Simulate заказ | корзина → оформить → mock payment → success | MAN |
| SHP-09 | История заказов | профиль/история после заказа | MAN |
| SHP-10 | Изоляция A/B | разные tenant_id — оба работают, данные по PTS | MCP |

---

## INF — §7 инфра URL

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| INF-01 | demo:shop_urls | режим B, URL с `?tenant_id=` | MAN |
| INF-02 | UrlBuilder reserved | slug `www` rejected | MAN |
| INF-03 | Host subdomain | при SHOP_BASE_DOMAIN=localhost + hosts — `{slug}.localhost:3001/shop` | MAN |
| INF-04 | Fly UUID ≠ local | UUID из Fly docs не работают локально → 404 | MAN |

---

## ACC — приёмка (эпик заказчика, MCP частично)

| ID | Итог | Шаги | Канал |
|----|------|------|-------|
| ACC-01 | С нуля: org + 3 точки | ORG-03 + TEN-02..04 + адреса | MCP/MAN |
| ACC-02 | Карточки всех точек | ENT-* на каждой | MCP |
| ACC-03 | Staff минимум | GM или barista login на каждой sales_point | MCP |
| ACC-04 | Витрина каждой точки | SHP-01/02 на всех 3 | MCP |
| ACC-05 | Заказ simulate | SHP-08 на одной точке | MAN |
| ACC-06 | Связность цены | CON-01 | MCP/MAN |

---

**Всего сценариев:** 58 (`PRE` 3 + `AUTH` 10 + `ORG` 5 + `TEN` 10 + `KIT` 4 + `ENT` 8 + `STF` 6 + `CON` 6 + `SHP` 10 + `INF` 4 + `ACC` 6).

**Не закрывает чеклист автоматически** — только журнал прогона. Формальная приёмка заказчиком — отдельно.
