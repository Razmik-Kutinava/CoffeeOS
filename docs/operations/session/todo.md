# todo — Долговечные сессии PWA + Silent Refresh

> **ТЗ:** [`customer_tasks/Долговечные сессии PWA и фикс авто-разлогина.md`](../milestones/veha_2/requirements/customer_tasks/Долговечные%20сессии%20PWA%20и%20фикс%20авто-разлогина.md)  
> **Артефакты:** [`artifacts/pwa_durable_sessions_silent_refresh/`](../milestones/veha_2/artifacts/pwa_durable_sessions_silent_refresh/)

## Текущая фаза

**PHASE 3: REVIEW** — GREEN `[x]` · регрессия PASS

---

## Чеклист

### Фаза 0 — docs

- [x] Intake ТЗ + CBR + artifacts
- [x] PHASE 1: SPEC

### Шаг 1 — session_store

- [x] `config/initializers/session_store.rb`: `_coffeeos_session`, 90.days, `same_site: :lax`
- [x] Тест `session_store_config_test`

### Шаг 2 — MobileSession на OTP

- [x] `Shop::MobileSessionIssuer` + вызов из `email_otp#verify`
- [x] Ответ verify содержит `refresh_token`
- [x] Тесты issuer + session_refresh verify

### Шаг 3 — Silent Refresh API

- [x] Route `POST /shop/api/session/refresh`
- [x] `Shop::SessionRefresh` + `session#refresh`
- [x] 200 / 401 / ротация / продление email verification
- [x] Тесты integration

### Шаг 4 — LocalStorage

- [x] Убран hard 24h burn; `shop_refresh_token`; `touchShopLocalStorage`
- [x] Checkout сохраняет token после verify
- [x] `shop_local_storage_test.mjs` PASS

### Шаг 5 — Restore при старте

- [x] `silentRefreshSession.js` + wire в `restoreGuestSession`
- [x] 200 / 401 / сеть → гость без краша
- [x] JS + structural tests PASS

### Exit / регрессия

- [x] Новые тесты: 13 runs / 0 fail (+ JS PASS)
- [x] Регрессия OTP/guest: 18 runs / 0 fail
- [ ] Redeploy Fly + MCP PWA (по апруву)
- [x] PHASE 3: REVIEW ops
