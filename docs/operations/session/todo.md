# todo — Связка профилей Email ↔ Phone + управление данными в PWA

> **ТЗ:** [`customer_tasks/Связка профилей Email Phone и управление данными пользователя в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Связка%20профилей%20Email%20Phone%20и%20управление%20данными%20пользователя%20в%20PWA.md)  
> **Артефакты:** [`artifacts/profile_email_phone_merge/`](../milestones/veha_2/artifacts/profile_email_phone_merge/)

## Текущая фаза

**PHASE 1: SPEC** — готово · ждём намерение → **PHASE 2 RED**

- [x] PHASE 0: Intake (док + артефакты + CBR)
- [x] PHASE 1: SPEC (as-is / gap / решения)
- [ ] PHASE 2: RED (падающие тесты)
- [ ] PHASE 2: GREEN (реализация + регрессия)
- [ ] PHASE 3: REVIEW (ops + отчёт)
- [ ] Push / Fly deploy / MCP — только по явному апруву

---

## As-is (2026-07-27)

| Зона | Сейчас |
|------|--------|
| `GET /shop/api/profile` | Есть (`ProfileController#show`); JSON: `id`, `name`, `phone`, loyalty-поля — **не** контракт ТЗ |
| `PATCH /shop/api/profile` | **Нет** |
| `POST …/link_email` / `link_phone` | **Нет** |
| `email_verified` / `phone_verified` | Колонок в `mobile_customers` **нет** |
| Soft-delete | `is_active` уже есть в `mobile_customers` |
| Email OTP | Есть (Brevo + `EmailVerifiedCustomerLinker`) — find_or_initialize по email, **без merge** |
| Phone OTP | Есть (SMS/Flash Call + `PhoneVerifiedCustomerLinker`) — при конфликте phone↔email **raises**, merge **запрещён** |
| Unique indexes | `email` UNIQUE WHERE NOT NULL; `phone` UNIQUE **без** WHERE — soft-deleted phone блокирует повтор |
| `Shop::OrderCreator` | Берёт email из params + OTP-verify; автоподстановка phone/email из профиля сессии — **частично/нет** |
| PWA Profile | `Profile.svelte` — меню (заказы/бонусы), **нет** email/phone verified UI, **нет** PATCH имени |
| Checkout autofill | Guest profile / OTP session — **не** полный профиль `mobile_customers` |
| Тесты | Minitest `test/` (не RSpec `spec/`); фронт — grep/integration + JS в `test/` |

## Gap → шаги ТЗ

| Шаг | Gap |
|-----|-----|
| 0 / DDL | Добавить `email_verified`, `phone_verified` (boolean, default false) **или** вывести verified из факта наличия + OTP session — **нужен Migration Gate + `go`**, если DDL |
| 1 | Расширить `GET profile`: контракт ТЗ + **401** без сессии (сейчас отдаёт «Гость» 200) |
| 2 | `PATCH profile` (first_name/last_name) + 422 |
| 3–4 | `POST link_email` + сервис merge (A clean / B soft-merge orders/cards/cart → current; donor `is_active: false`) |
| 5 | `POST link_phone` зеркально; **переписать** конфликтную ветку `PhoneVerifiedCustomerLinker` / общий `Shop::CustomerProfileMerger` |
| 6 | `OrderCreator`: подставлять verified email/phone из `MobileCustomer` сессии |
| 7–8 | UI профиля + OTP-флоу допривязки без reload |
| 9 | Autofill checkout + «Сохранить в профиль» |

## Решения SPEC (зафиксировать до RED)

1. **Тесты:** Minitest — `test/integration/shop/api/profile_*_test.rb`, `test/services/shop/customer_profile_merger_test.rb`, расширить `order_creator_test`; фронт — integration/grep + JS unit по аналогии phone OTP (не Playwright/RSpec из ТЗ).
2. **Merge-сервис:** новый `Shop::CustomerProfileMerger` (или расширить linkers) — одна транзакция: перенос FK (`orders.customer_id`, `mobile_payment_methods`, `mobile_carts`, sessions) → donor soft-deactivate; **без** `destroy`.
3. **Unique phone:** при soft-delete освобождать уникальность — обнулять `phone`/`email` у donor **или** partial unique `WHERE is_active` (DDL → Migration Gate). Предпочтение: **освободить контакт на donor** (`phone`/`email` → nil) + `is_active: false`, чтобы не ломать существующий unique index без DDL индекса.
4. **Verified flags:** без silent-угадывания — колонки `email_verified` / `phone_verified` (DDL) **или** «verified = поле заполнено после успешного OTP link». **Выбор на RED после `go` на миграцию:** предложить DDL boolean + backfill.
5. **Auth 401:** для авторизованных эндпоинтов профиля — 401 если нет `CustomerSession.customer_id` (ломает текущий guest JSON на `GET profile` — согласовать: guest остаётся 200 только для legacy header, а новый контракт — при `Accept`/явном auth; **канон ТЗ: 401** без сессии на profile write/link; GET — 401 без customer_id).
6. **OTP:** переиспользовать существующие Email OTP + Phone OTP; link_* принимает уже verified code / session flag, **не** менять базовую схему OTP.
7. **Hot-path:** `OrderCreator` — минимальный diff; регрессия зоны оплаты обязательна.
8. **Race merge:** `SELECT … FOR UPDATE` на обеих карточках в транзакции; тест на конфликт двух link.

## Чек-лист реализации (из ТЗ)

### Бэкенд
- [ ] **Шаг 0:** DDL / решение verified + unique soft-delete (**Migration Gate `go`**)
- [ ] **Шаг 1:** GET `/shop/api/profile` — контракт ТЗ + 401
- [ ] **Шаг 2:** PATCH `/shop/api/profile` — имя/фамилия, 422
- [ ] **Шаг 3:** POST `link_email` — сценарий A (clean)
- [ ] **Шаг 4:** POST `link_email` — сценарий B (merge + soft-delete)
- [ ] **Шаг 5:** POST `link_phone` — A + B
- [ ] **Шаг 6:** `Shop::OrderCreator` — автоподстановка verified contacts

### Фронтенд
- [ ] **Шаг 7:** Экран профиля — контакты + verified/bind + edit name + toast 500
- [ ] **Шаг 8:** Флоу допривязки OTP без reload
- [ ] **Шаг 9:** Autofill checkout + «Сохранить в профиль»

## Риски

| Риск | Митигация |
|------|-----------|
| Потеря заказов/карт при merge | Транзакция + тесты FK; запрет destroy |
| Unique phone блокирует soft-delete | Освобождать контакт на donor |
| Ломаем guest `GET profile` | Явный 401 по ТЗ; поправить Header/Profile UI |
| Hot-path OrderCreator | Минимальный diff + регрессия §2.3 |
| DDL без апрува | Стоп до `go` на миграцию |
