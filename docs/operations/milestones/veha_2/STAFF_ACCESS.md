# Доступы персонала на точку (В2)

**Зачем:** после онбординга org клиент должен понимать, **как завести команду** и куда каждая роль входит (без поддомена на роль).

**Связь:** [`ONBOARDING.md`](ONBOARDING.md), [`ONBOARDING_CHECKLIST.md`](ONBOARDING_CHECKLIST.md) § 5.

---

## Как сейчас

| Роль | Кто создаёт | Где вход |
|------|-------------|----------|
| `uk_global_admin` | вручную / seed | `/admin` |
| `franchise_manager` | УК `franchise_owners/new` | `/manager` |
| `general_manager`, `shift_manager`, `barista` | **manager → staff** | `/manager`, `/barista` |
| `prep_kitchen_*` | manager staff после `open_as_manager` на цех *(§3 ONBOARDING 2026-05-26)* или seed | `/prep_kitchen` |

**Привязка к точке:** `users.tenant_id` + `user_roles` (role + tenant). После login — `Current.tenant_id`, RLS.

**Демо:** 9 пользователей — [`../veha_1/DEMO_LOGINS.md`](../veha_1/DEMO_LOGINS.md), пароль `demo123456`.

---

## Пароль и сброс (минимум В2)

| Действие | Где | Поведение |
|----------|-----|-----------|
| Задать пароль | manager → staff → «Добавить» | Поле **Пароль** обязательно при создании; в БД — bcrypt (`password_hash`) |
| Сменить пароль | manager → staff → «Изменить» | Поле **Новый пароль** — если **пусто**, старый пароль **не меняется** |
| Self-service / email invite | — | **Нет в В2** — только через менеджера точки |
| Демо-стенд | seed | Единый пароль `demo123456` — см. DEMO_LOGINS |

**Рекомендация для новой org:** задайте пароль при создании staff; передайте сотруднику по защищённому каналу (не в чате с клиентами). Для GM/barista на каждую точку — минимум одна роль с рабочим login (см. чеклист §5).

---

## Путь УК: первая команда на точке

1. УК → `/admin/tenants/:id` (карточка «все входы») или список точек.
2. **«Создать staff →»** (или «Открыть manager») — `open_as_manager` + сессия `manager_tenant_id`.
3. manager → **staff** → «Добавить» — email, пароль, роли (`barista`, `general_manager`, …).
4. Сотрудник выходит из УК → `/login` → попадает на `/barista` или `/manager` по роли.

На **каждую** `sales_point` повторить шаги 2–3 (или franchise_manager создаёт staff на своих точках).

---

## Целевое В2 (хвост)

- [x] В карточке точки УК — чеклист «нужные роли» + `open_as_manager` + «Создать staff →» *(2026-05-26)*
- [x] Wizard «первая команда точки» в карточке УК *(2026-06-02)* — шаблон email/роль/панель + кнопка «Создать staff →»
- [ ] Invite / self-service сброс пароля (если появится)
- [x] Для новой org — шаблон логинов в карточке УК *(2026-06-02, `org.local` как заготовка)*

---

## Минимальный набор на точку продаж

| Роль | Зачем | Панель | Статус В2 |
|------|--------|--------|-----------|
| `uk_global_admin` | УК: org/точки/меню | `/admin` | ✅ AUTH-01 |
| `franchise_manager` | Просмотр своих точек (switcher A/B) | `/manager` | ✅ AUTH-02 |
| `general_manager` | Меню, staff, склад | `/manager` | ✅ AUTH-03 |
| `shift_manager` | Смена, оперативка (урезанный sidebar) | `/manager` | ✅ AUTH-06 |
| `barista` | POS | `/barista` | ✅ AUTH-04/05 |
| `prep_kitchen_manager` | Склад цеха, движения | `/prep_kitchen` | ✅ AUTH-07 |
| `prep_kitchen_worker` | Просмотр остатков/очереди | `/prep_kitchen` | ✅ AUTH-08 |

**Приёмка §5:** на каждую sales_point достаточно **GM или barista** с рабочим `/login`.

Цех: `prep_kitchen_manager` + `prep_kitchen_worker` на `production_kitchen` tenant.

---

## Не путать

- **Клиент витрины** — без User; Shop API key / same-origin
- **Киоск** — device token (план), не staff login
