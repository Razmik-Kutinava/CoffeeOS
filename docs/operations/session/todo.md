# todo — Долговечные сессии PWA + Silent Refresh

> **ТЗ:** [`customer_tasks/Долговечные сессии PWA и фикс авто-разлогина.md`](../milestones/veha_2/requirements/customer_tasks/Долговечные%20сессии%20PWA%20и%20фикс%20авто-разлогина.md)  
> **Артефакты:** [`artifacts/pwa_durable_sessions_silent_refresh/`](../milestones/veha_2/artifacts/pwa_durable_sessions_silent_refresh/)

## Текущая фаза

**PHASE 1: SPEC** — импортировано · ждёт намерения → **PHASE 2 RED**

---

## Контекст (as-is → gap)

| # | As-is | Gap |
|---|--------|-----|
| 1 | Нет `session_store.rb`; cookie сессии без TTL | `_coffeeos_session`, `expire_after: 90.days`, `same_site: :lax` |
| 2 | `MobileSession` в schema есть, **не используется**; `/email_otp/verify` → `{ verified, email }` | После OTP + linker — создать `MobileSession`, вернуть `refresh_token` |
| 3 | `POST session/reconnect` только для заказа; refresh **нет** | `POST /shop/api/session/refresh` + ротация токена |
| 4 | `shopLocalStorage.js`: `SHOP_LS_TTL_MS = 24h` **сжигает** данные | Убрать hard burn; ключ `shop_refresh_token` без авто-удаления; скользящий `savedAt` |
| 5 | `restoreGuestSession` → `GET email_otp/status` (нужен email в LS) | Silent refresh по `shop_refresh_token` при старте |

---

## Ограничения (жёсткие)

- **БД:** схема `mobile_sessions` / миграции — **не менять**.
- **Сигнатуры:** `Shop::EmailOtp.verify!(email:, code:)` и `Shop::CustomerSession.set_customer_id!(session, tenant_id, customer_id)` — **не менять** (только вызов / оркестрация вокруг).
- **Не ломать:** checkout, OTP send/verify, `GuestOrderReconnect`, frequent/cards.
- **RLS / tenant:** refresh и issue — через `X-Shop-Tenant` / `Current.tenant_id` как в `Shop::Api::BaseController`; `CustomerSession` — per-tenant bucket.
- **Размер файлов:** новые сервисы ≤120 строк; толстую логику не пихать в controller.

---

## Архитектурные решения SPEC

### A. Где создавать MobileSession (шаг 2)

`EmailOtp.verify!` возвращает только email и **не знает** `customer_id` / session.  
→ **Не** внутри `verify!`.  
→ После существующего флоу в `email_otp#verify`:

1. `EmailOtp.verify!`
2. `EmailVerification.mark_verified!`
3. `EmailVerifiedCustomerLinker.link!` → `customer_id`
4. **новый** `Shop::MobileSessionIssuer.call!(customer_id:)` → запись + `refresh_token`
5. JSON: `{ verified: true, email:, refresh_token: }` (+ существующие поля не ломать)

### B. Продление TTL при refresh (шаг 3)

`MobileSession#update_last_used!` сейчас пишет только `last_used_at`.  
→ В refresh-сервисе (или расширить метод **без** смены схемы): `expires_at = 90.days.from_now` + `last_used_at` + ротация `refresh_token` (deactivate old / create new **или** update + deactivate siblings).  
→ `Shop::EmailVerification.mark_verified!(…, ttl: 90.days)` для того же email/tenant.

### C. LocalStorage (шаг 4)

- Ключ `shop_refresh_token` — **plain** или через helper **без** TTL-burn.
- `readShopLocalStorage` / `writeShopLocalStorage`: убрать жёсткое сжигание по `SHOP_LS_TTL_MS` (24h); оставить `savedAt`; опционально `touchShopLocalStorage(key)` при успешных действиях (скользящий).
- Обновить `test/javascript/shop_local_storage_test.mjs` (сейчас ассертит burn через 24h).

### D. Старт PWA (шаг 5)

Расширить `restoreGuestSession` (или рядом `silentRefreshSession`):

1. Если есть `shop_refresh_token` → `POST /shop/api/session/refresh`.
2. 200 → сохранить новый токен, `saveGuestProfile` verified, refresh frequent.
3. 401 / сеть / 5xx → удалить токен, UI «Гость», **без краша**.
4. Существующий `email_otp/status` путь — оставить как fallback, если токена нет, но email в profile есть.

### E. Тесты (адаптация ТЗ)

ТЗ пишет RSpec/`spec/` + Jest — **в CoffeeOS канон:**

| Что | Куда |
|-----|------|
| Backend | Minitest `test/services/shop/…`, `test/integration/shop/api/…` |
| Frontend LS | `test/javascript/shop_local_storage_test.mjs` (+ silent refresh helper test при необходимости) |
| Регрессия зоны | email OTP + guest restore + cart sheet zone (таргетные файлы, не полный `shop/` на Windows) |

Критические кейсы из ТЗ:

- TTL: `expires_at` ровно now → 401; `expires_at > now` → 200.
- Ротация: старый token после refresh → 401.
- Сеть/500 на refresh → гость, без exception на фронте.
- LS: данные **не** удаляются через 24h; `shop_refresh_token` живёт.

---

## Чеклист (для RED → GREEN)

### Фаза 0 — docs

- [x] Intake ТЗ + CBR + artifacts
- [x] PHASE 1: SPEC (этот файл)

### Шаг 1 — session_store

- [ ] `config/initializers/session_store.rb`: key `_coffeeos_session`, `expire_after: 90.days`, `same_site: :lax`
- [ ] Тест/structural: initializer существует и параметры совпадают

### Шаг 2 — MobileSession на OTP

- [ ] `Shop::MobileSessionIssuer` (или аналог) + вызов из `email_otp#verify` после linker
- [ ] Ответ verify содержит `refresh_token`
- [ ] Тест: verify создаёт active `MobileSession` на 90 дней

### Шаг 3 — Silent Refresh API

- [ ] Route `POST /shop/api/session/refresh`
- [ ] `Shop::SessionRefresh` (сервис) + action в `session_controller` (или отдельный)
- [ ] 200: set_customer_id!, ротация, продление expires + email verification, профиль
- [ ] 401: невалид / просрочен / inactive
- [ ] Тесты: happy / expired / rotated old token / missing tenant

### Шаг 4 — LocalStorage

- [ ] Убрать hard 24h burn; `shop_refresh_token`; скользящий `savedAt`
- [ ] Wire: после verify сохранять токен; touch при успешных API
- [ ] Обновить `shop_local_storage_test.mjs`

### Шаг 5 — Restore при старте

- [ ] Silent refresh в init (`restoreGuestSession` / рядом)
- [ ] 200 → авторизован; 401/ошибка → гость + clear token
- [ ] Тест JS / structural на вызов refresh и обработку ошибок

### Exit / регрессия

- [ ] Новые тесты зелёные
- [ ] Регрессия: `email_otp_*`, `guest_session_restore`, OTP/cards зона
- [ ] Не сломан checkout / order create
- [ ] PHASE 3: REVIEW + ops (CHANGELOG/HANDOFF)

---

## Риски

| Риск | Митигация |
|------|-----------|
| Смена cookie key → разлогин текущих сессий на Fly | Ожидаемо один раз; cookie key новый `_coffeeos_session` |
| `update_last_used!` не продлевал expires | Явно продлевать в refresh |
| Убрать 24h burn у cart/frequent — «вечный» мусор | Скользящий touch + 90d ceiling опционально в GREEN (не hard 24h) |
| Windows hang полного `test/integration/shop/` | Таргетные файлы по зоне |

---

## Порядок SBR

1. **RED** — падающие тесты шагов 1–5 (батч или по шагам)  
2. **GREEN** — реализация + регрессия  
3. **REVIEW** — ops + отчёт  

Ждёт намерения: «ебашь / сделай / RED / дальше».
