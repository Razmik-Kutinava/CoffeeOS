# Чеклист онбординга УК — «из коробки» (В2)

**Родитель:** [`CHECKLIST.md`](CHECKLIST.md) § A. **Модель:** [`ONBOARDING.md`](ONBOARDING.md).

Отмечать `[x]` по мере **кода + ручной проверки** на чистой org (не `demo-coffeeos`, если нужна проверка «с нуля»).

---

## 1. Организация

- [x] `/admin/organizations/new` — имя, slug org *(проверено 2026-05-26)*
- [x] Org видна в списке и привязана к новым tenants *(проверено 2026-05-26)*

---

## 2. Точка продаж (×3 для приёмочного сценария)

- [x] Создание: org, name, **slug уникальный**, type `sales_point`, city, **address** (поле в форме) *(2026-05-26: добавлено поле address)*
- [x] Модули: `barista`, `menu`, `kiosk` off для сценария «только витрина+QR» *(2026-05-26)*
- [x] Provision без ошибки; rollback при сбое *(rollback: `tenants_controller_test.rb`; provision: onboarding test)*
- [x] Flash / карточка: URL витрины `{slug}.{SHOP_BASE_DOMAIN}/shop` *(при заданном домене; Fly — `?tenant_id=`)*
- [x] Открыть витрину — меню не пустое (PTS + каталог УК) *(2026-05-26)*
- [x] RLS: заказ на точке A не виден на B *(2026-05-26)*

---

## 3. Заготовочный цех (если в scope org)

- [x] Tenant `production_kitchen`, slug отдельный, модуль `prep_kitchen` *(2026-05-26)*
- [x] Вход `/prep_kitchen` после создания staff — УК → open_as_manager → manager/staff → login *(2026-05-26, STAFF_ACCESS)*

---

## 4. Карточка «все входы» (продукт В2)

- [x] Экран или блок на tenant#edit / show *(2026-05-26: `/admin/tenants/:id` + блок на edit)*
  - [x] Витрина URL + QR hint
  - [x] Киоск URL (когда есть; UI — пометка «в разработке»)
  - [x] Ссылки: `/manager`, `/barista`, `/prep_kitchen` (общий хост)
  - [x] Адрес, slug, org name
  - [x] Список модулей on/off
  - [x] Чеклист staff: «создайте barista@…, gm@…»
- [x] Копирование URL в буфер (nice-to-have) *(кнопка «Копировать» на витрине)*

---

## 5. Staff (минимум для «боевых входов»)

- [x] GM или barista на **каждую** sales_point — логин работает *(2026-05-26: УК → open_as_manager → manager/staff → /login)*
- [ ] **shift_manager** (`shift-a`) → `/manager` — **AUTH-06 SKIP, не проверялось в прогонах 1–4**
- [ ] **franchise_manager** (`franchise@`) → `/manager` — **AUTH-02 SKIP**
- [ ] **prep_kitchen_worker** (`pk-worker`) → `/prep_kitchen` — **AUTH-08 SKIP**
- [x] Документированный пароль/сброс — [`STAFF_ACCESS.md`](STAFF_ACCESS.md) *(2026-05-26)*
- [x] УК `open_as_manager` на каждую точку — OK *(2026-05-26, 3 точки в тесте)*

---

## 6. Связность (smoke)

- [x] УК изменил цену PTS → витрина точки показывает новую цену *(2026-05-26: platform menu → PublishProduct → shop API)*
- [x] Barista создал заказ → manager видит в смене *(2026-05-26: manager/shifts/:id + /manager/orders)*
- [x] Prep_kitchen movement — только свой tenant *(2026-05-26: confirm чужого movement не проходит)*

---

## 7. Инфра

- [x] `SHOP_BASE_DOMAIN` на стенде — см. [`INFRA_URLS.md`](INFRA_URLS.md) *(2026-05-26: Fly режим B — без env в fly.toml; режим A — когда свой домен)*
- [x] Wildcard DNS `*.domain` → приложение *(2026-05-26: код резолвит Host→slug; на Fly DNS не нужен; прод — INFRA_URLS § A)*
- [x] Новые slug не в RESERVED (`www`, `admin`, `api`, …) *(2026-05-26: валидация Tenant + UrlBuilder fallback)*

---

## Приёмка блока

**Готово**, когда владелец может **без разработчика** завести org + 3 точки с адресами и получить **список URL + кого завести**, а витрина открывается и заказывает (сначала simulate, потом § оплата в главном чеклисте).

### MCP DevTools (локалка, 2026-05-27) — [`ONBOARDING_DEVTOOLS_RUN.md`](ONBOARDING_DEVTOOLS_RUN.md)

- [x] Прогон выполнен (34/58 PASS, 0 FAIL MCP)
- [x] PRE: сервер `/up`, `demo:seed`, `bin/dev`
- [x] AUTH: вход УК, GM, barista-a, pk-manager → свои панели
- [x] ORG: список, форма, создание org через UI
- [x] TEN: форма новой точки; витрина demo-point-a/b — меню не пустое
- [x] TEN: **3 точки на чистой org** — MCP Run2 (`mcp-point-1..3`, 2026-05-26)
- [x] KIT: карточка цеха, вход pk-manager → `/prep_kitchen`
- [x] ENT: карточка «все входы» (URL, модули, staff ✓, kiosk hint)
- [x] STF: open_as_manager + создание staff на новой org *(2026-05-27: MCP Run2 — barista + GM, login barista → `/barista`)*
- [x] CON: **цена УК → витрина** (CON-01) *(2026-05-27: PublishProduct → vitrina 199₽)*
- [x] CON: barista заказ → manager (integration test PASS после `db:ensure_triggers`)
- [x] SHP: витрина A/B, API categories, корзина quick-add; **product card → product page** (fix Header)
- [x] SHP: **simulate заказ** (SHP-08) *(2026-05-27: #202605-0002, 199₽, accepted; success UI — MAN/MCP quirk)*
- [x] INF: `demo:shop_urls` режим B; Fly UUID локально не подходит

### Формально ещё не закрыто

- [ ] Приёмка **заказчиком** руками (тот же сценарий без разработчика)

### Покрытие тестами

- `test/controllers/platform/tenants_controller_test.rb`
  - `create rolls back tenant if Provision raises an error` — rollback транзакции
  - `create provisions PTS for catalog products` — каталог без demo:seed*
