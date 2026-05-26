# Онбординг организации и точек (Веха 2)

**Зачем документ:** единая модель «из коробки» — что создаёт УК, что получает клиент, какие URL и как привязка к БД без поддомена на каждую роль.

**Чеклист реализации:** [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md). **Инфра URL:** [`INFRA_URLS.md`](INFRA_URLS.md). **Staff:** [`STAFF_ACCESS.md`](STAFF_ACCESS.md).

---

## Цепочка (целевая)

```
Organization (org)
  └── Tenant × N (точка продаж sales_point | кухня production_kitchen)
        ├── FeatureFlag (модули: barista, menu, prep_kitchen, kiosk, …)
        ├── ProductTenantSetting (цены из каталога УК)
        ├── Users + UserRoles (персонал)
        └── Клиентские URL по slug
```

**Код сегодня:** `Platform::TenantOnboarding::Provision` + `CatalogBootstrap` + `TenantModuleFlags.sync!` — вызывается из `Platform::TenantsController` в транзакции.

---

## Что уже работает (В1)

| Шаг | Где | Результат |
|-----|-----|-----------|
| Создать org | `/admin` → organizations | `Organization` |
| Создать точку | `/admin` → tenants | `Tenant` + modules + PTS |
| Модули | Форма tenant | `FeatureFlag` per module |
| Витрина URL | flash после create | `UrlBuilder.shop_url_for` → `{slug}.{SHOP_BASE_DOMAIN}/shop` |
| RLS | Provision | `SET LOCAL app.current_tenant_id` + bootstrap каталога |
| Зайти как менеджер | `open_as_manager` | Сессия manager на точке |

---

## Чего не хватает (В2)

| Пробел | План |
|--------|------|
| Поле **улица/адрес** в форме | **done** — `address` в `_form` (2026-05-26) |
| **Карточка точки** со всеми входами | Новый экран/блок: витрина, киоск (когда есть), `/manager`, `/barista`, `/prep_kitchen`, инструкция «создать staff» |
| **Staff из УК** одним потоком | Расширить или wizard — см. STAFF_ACCESS |
| **Киоск URL** | После реализации KIOSK — в ту же карточку |
| Автоматические **demo users** только для `demo:seed` | Боевая org — ручной/staff flow |

---

## Модель входов (как задумано)

### Клиентские каналы — **поддомен точки** (канон)

| Канал | URL (режим A, прод) | Tenant resolution |
|-------|---------------------|-------------------|
| Витрина | `https://{slug}.{SHOP_BASE_DOMAIN}/shop` | Host → `Tenant.slug` |
| Киоск | `https://{slug}.{SHOP_BASE_DOMAIN}/...` (путь — KIOSK.md) | То же |

**Fly demo (режим B):** `https://coffeeos.fly.dev/shop?tenant_id=…` — slug в БД тот же, поддомен после своего домена. См. [`../../SHOP_URL_MODES.md`](../../SHOP_URL_MODES.md), [`INFRA_URLS.md`](INFRA_URLS.md).

### Операционные панели — **общий хост**

| Роль | Вход | Привязка к точке |
|------|------|------------------|
| УК | `/admin` | Видит все org; `open_as_manager` на tenant |
| franchise / GM / shift | `/manager` + login | `User` / `UserRole` → `tenant_id` |
| barista | `/barista` + login | `user.tenant_id`, `CashShift` |
| prep_kitchen | `/prep_kitchen` + login | tenant цеха |

**Почему не `barista-{slug}.domain`:** меньше DNS/SSL/куки; точка = аккаунт + RLS (см. обсуждение в сессии В2).

---

## Модули точки (`TenantModuleFlags`)

| Код | Смысл | В2 |
|-----|--------|-----|
| `barista` | POS | Работает |
| `menu` | Меню точки | Работает |
| `prep_kitchen` | Цех | Нужен `type: production_kitchen` для цеха |
| `kiosk` | Киоск | Флаг есть; **UI — В2** |
| `qr_offers` | QR / офферы | По продукту |
| `tv_board` | TV | Устройства в manager |

**Оплата** — не модуль: глобально через env + шлюз ([`PAYMENT.md`](PAYMENT.md)).

---

## Пример: новая org «3 точки на улицах»

| Точка | slug (пример) | address (в БД) | Модули |
|-------|---------------|----------------|--------|
| Арбат 12 | `arbat-12` | Москва, ул. Арбат, 12 | barista, menu, kiosk |
| Патриаршие 5 | `patriki-5` | … | то же |
| Цех ЮЗАО | `prep-yuzao` | … | prep_kitchen, `production_kitchen` |

После сохранения карточка должна показать **3 витрины** + ссылки на панели + чеклист «создайте barista-a@…».

---

## Связь с полировкой

Правки заказчика по UI онбординга/карточки — в [`DEMO_FEEDBACK.md`](DEMO_FEEDBACK.md), не возвращать задачи в чеклист В1.
