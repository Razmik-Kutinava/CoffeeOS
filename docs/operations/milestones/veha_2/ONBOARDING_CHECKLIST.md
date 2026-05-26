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

- [ ] Экран или блок на tenant#edit / show:
  - [ ] Витрина URL + QR hint
  - [ ] Киоск URL (когда есть)
  - [ ] Ссылки: `/manager`, `/barista`, `/prep_kitchen` (общий хост)
  - [ ] Адрес, slug, org name
  - [ ] Список модулей on/off
  - [ ] Чеклист staff: «создайте barista@…, gm@…»
- [ ] Копирование URL в буфер (nice-to-have)

---

## 5. Staff (минимум для «боевых входов»)

- [ ] GM или barista на **каждую** sales_point — логин работает
- [ ] Документированный пароль/сброс — [`STAFF_ACCESS.md`](STAFF_ACCESS.md)
- [ ] УК `open_as_manager` на каждую точку — OK

---

## 6. Связность (smoke)

- [ ] УК изменил цену PTS → витрина точки показывает новую цену
- [ ] Barista создал заказ → manager видит в смене
- [ ] Prep_kitchen movement — только свой tenant

---

## 7. Инфра

- [ ] `SHOP_BASE_DOMAIN` на стенде — см. [`INFRA_URLS.md`](INFRA_URLS.md)
- [ ] Wildcard DNS `*.domain` → приложение
- [ ] Новые slug не в RESERVED (`www`, `admin`, `api`, …)

---

## Приёмка блока

**Готово**, когда владелец может **без разработчика** завести org + 3 точки с адресами и получить **список URL + кого завести**, а витрина открывается и заказывает (сначала simulate, потом § оплата в главном чеклисте).
