# todo — Auth funnel cascade (Flash Call ×2 → Messenger → SMS)

> **ТЗ:** [`customer_tasks/Рефакторинг воронки авторизации PWA Каскад Flash Call Messenger SMS.md`](../milestones/veha_2/requirements/customer_tasks/Рефакторинг%20воронки%20авторизации%20PWA%20Каскад%20Flash%20Call%20Messenger%20SMS.md)  
> **Артефакты:** [`artifacts/auth_funnel_cascade_flash_messenger_sms/`](../milestones/veha_2/artifacts/auth_funnel_cascade_flash_messenger_sms/)  
> **Предшественник:** Phone OTP SMS/Flash Call · Fly v390

## Текущая фаза

**PHASE 2: BUILD** — Шаг 5 (MessengerClient backend) · **GREEN `[x]`** · дальше Шаг 6 (rate limits 20/30/60)

---

## Маппинг путей ТЗ → CoffeeOS

| ТЗ | Канон CoffeeOS | Решение SPEC |
|----|----------------|--------------|
| `POST /shop/api/phone_otp/send` | уже есть | extend channel: `flash_call` \| `messenger` \| `sms` (Шаг 5) |
| `POST /shop/api/phone_otp/verify` | уже есть `{ phone, code }` | reuse |
| RSpec / Vitest paths | `test/` + `test/javascript/*.mjs` | стек Rails Minitest + Node |
| UX Guide | существующие Tailwind-токены checkout (`#ff8c42`, `#2a2a2a`) | без новой дизайн-системы |
| `Shop::MessengerClient` | новый сервис | Шаг 5 |
| Rack::Attack cooldowns 20/30/60 | частично (sms 60) | Шаг 6 |

### Ограничения

- Нет Email / radio channel / кнопки «подтвердить код» в wizard.
- API-ключи мессенджеров — только ENV.
- Checkout.svelte >200 строк — UI wizard вынести в `components/PhoneAuthWizard.svelte` + `lib/phoneAuthWizard.js`.

### File-size

| Файл | План |
|------|------|
| `lib/phoneAuthWizard.js` | **create** ≤80 — screen state, canContinue, send body |
| `components/PhoneAuthWizard.svelte` | **create** ≤120 — Screen 1 (+ stub Screen 2) |
| `lib/phoneOtp.js` | extend mask helpers при необходимости |
| `Checkout.svelte` | заменить email+phone OTP блок на wizard; не раздувать |

**DDL:** не требуется (Шаг 1).

---

## Чеклист

- [x] **Шаг 1:** Очистка UI + Экран 1 (маска, автофокус, «Продолжить», `flash_call`, → Экран 2)
- [x] **Шаг 2:** Экран 2 — 4 ячейки PIN, авто-сабмит verify, «Изменить номер»
- [x] **Шаг 3:** Каскад Flash Call #1 / #2 (таймеры 0–20 / 20–40)
- [x] **Шаг 4:** Messenger + SMS fallback (40–70 / 70+)
- [x] **Шаг 5:** Backend `MessengerClient` + channel messenger + delivery error flag
- [ ] **Шаг 6:** Кулдауны / Rack::Attack 20 / 30 / 60

---

## Тесты / регрессия (Шаг 1)

| Зона | Команда |
|------|---------|
| JS wizard Screen 1 | `node --test test/javascript/phone_auth_wizard_test.mjs` |
| Checkout UI grep | `bin/rails test test/integration/shop/checkout_acceptance_cbr_test.rb` (обновить cbr_01) |
| Phone OTP API | `bin/rails test test/integration/shop/api/phone_otp_test.rb` |

---

## Риски

| Риск | Митигация |
|------|-----------|
| OrderCreator требует email | Шаг 1 не ломает pay для saved email-профилей; phone-only pay — после Шага 2+ |
| cbr_01 требует Email | обновить под phone-first (ТЗ supersede) |
| Checkout монолит 890 строк | только вынос wizard, без полного сплита |
