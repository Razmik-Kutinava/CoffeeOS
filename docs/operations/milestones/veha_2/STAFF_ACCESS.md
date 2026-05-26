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

## Целевое В2

- [ ] В карточке точки УК — таблица «нужные роли» + кнопка «создать GM» / ссылка на staff
- [ ] Опционально: wizard «первая команда точки» после Provision
- [ ] Документировать сброс пароля / invite (если появится)
- [ ] Для новой org — [`DEMO_LOGINS.md`](DEMO_LOGINS.md) вести отдельно от demo-coffeeos

---

## Минимальный набор на точку продаж

| Роль | Зачем |
|------|--------|
| `general_manager` | Меню, staff, склад |
| `shift_manager` | Смена, оперативка |
| `barista` | POS |
| `franchise_manager` | На org (один на сеть) |

Цех: `prep_kitchen_manager` + `prep_kitchen_worker` на `production_kitchen` tenant.

---

## Не путать

- **Клиент витрины** — без User; Shop API key / same-origin
- **Киоск** — device token (план), не staff login
