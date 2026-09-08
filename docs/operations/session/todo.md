# todo — #80 Callcheck → leave wizard (verify-first)

| Поле | Значение |
|------|----------|
| **CBR / корень** | #80 · Registration UI/UX + Callcheck cascade |
| **ТЗ** | [`Регистрация PWA UI UX и каскад Callcheck x2 SMS.md`](../milestones/veha_2/requirements/customer_tasks/Регистрация%20PWA%20UI%20UX%20и%20каскад%20Callcheck%20x2%20SMS.md) |
| **Канон** | Callcheck (`init_callcheck` / `check_status`) — **не** FlashCall |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | **v492** · `SHOP_OTP_LOG_FALLBACK=false` (ssh verified) |
| **Артефакт** | `…/registration_callcheck_cascade_ui_ux/mcp/fly_v492_2026-09-08/` |
| **Режим** | **verify-first**: код **не трогать**, пока Slice V ≠ FAIL |

## Slices

| Slice | Что | Когда | Статус |
|-------|-----|-------|--------|
| **V** | Live verify: звонок → `confirmed` → leave wizard / session | **← СТАРТ** | [ ] **BLOCKED** v492 — нет телефона владельца |
| **F** | Узкий fix по матрице отказа (RED→GREEN) | только если V = FAIL | [ ] n/a (нет FAIL) |
| **R** | REVIEW + MCP_RESULT PASS | после V PASS или после F | [ ] |

## SBR

- [x] **SPEC**
- [ ] **Slice V** live — V0 PASS · V1–V3 **BLOCKED** (нужен `+79…`)
- [ ] **RED** — только после V FAIL
- [ ] **GREEN** — только после RED
- [ ] **Slice V again** — после GREEN
- [ ] **REVIEW**

## Slice V — DoD

V0 UI path ✓ · live call + leave wizard — **без телефона = BLOCKED, не баг**.

## Файлы (ожидаемо)

Только при V FAIL:

- `app/frontend/lib/phoneAuthCascade.js`
- `app/frontend/components/PhoneAuthCodeStep.svelte`
- `app/frontend/components/PhoneAuthWizard.svelte`
- `app/controllers/shop/api/phone_otp_controller.rb`
- `app/services/shop/phone_otp.rb`
- `app/services/shop/phone_verified_customer_linker.rb`

**Соседи:** `mobile_session_issuer.rb` · `sms_ru_client.rb` (parse callcheck)

## Не ломать

- SMS fallback · rate limits · session/RLS · Callcheck≠FlashCall · guest checkout

## Проверка

```bash
node --test test/javascript/phone_auth*.mjs test/javascript/*callcheck*.mjs
ruby bin/rails test test/services/shop/phone_otp* test/integration/shop/api/*phone_otp* test/services/shop/phone_verified_customer_linker_test.rb
# + live Slice V
```
