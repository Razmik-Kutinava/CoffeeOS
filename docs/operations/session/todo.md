# todo — #80 Callcheck → leave wizard (verify-first)

| Поле | Значение |
|------|----------|
| **CBR / корень** | #80 · Registration UI/UX + Callcheck cascade |
| **ТЗ** | [`Регистрация PWA UI UX и каскад Callcheck x2 SMS.md`](../milestones/veha_2/requirements/customer_tasks/Регистрация%20PWA%20UI%20UX%20и%20каскад%20Callcheck%20x2%20SMS.md) |
| **Канон** | Callcheck (`init_callcheck` / `check_status`) — **не** FlashCall |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Fly** | v490 · `SHOP_OTP_LOG_FALLBACK` must be **false** |
| **Артефакт** | `…/artifacts/registration_callcheck_cascade_ui_ux/mcp/fly_vNNN_YYYY-MM-DD/` |
| **Режим** | **verify-first**: код **не трогать**, пока Slice V ≠ FAIL |

## Slices

| Slice | Что | Когда | Статус |
|-------|-----|-------|--------|
| **V** | Live verify: звонок → `confirmed` → leave wizard / session | **← СТАРТ** | [ ] |
| **F** | Узкий fix по матрице отказа (RED→GREEN) | только если V = FAIL | [ ] n/a пока |
| **R** | REVIEW + MCP_RESULT PASS | после V PASS или после F | [ ] |

## SBR

- [x] **SPEC** — этот файл
- [ ] **Slice V** live (телефон владельца/агента обязателен; иначе **BLOCKED**)
- [ ] **RED** — только после V FAIL
- [ ] **GREEN** — только после RED
- [ ] **Slice V again** — после GREEN (без live PASS шаг не `done`)
- [ ] **REVIEW** — bugbot + security + Entire + push

## Slice V — DoD (Gherkin)

```
Given гость на /shop?tenant_id=<Point A> открыл вход по телефону
When ввёл +79… → экран Callcheck → tel: / звонок (отвечать не нужно)
And SMS.ru отметил check confirmed
Then GET …/phone_otp/check_status → confirmed (+ refresh_token при customer)
And interpretCallcheckPoll → complete → onVerified
And wizard закрыт / гость вошёл (не «Ждем звонок»)
And повторный вход в той же сессии без нового звонка (базовая проверка)
```

**Out:** `MCP_RESULT.md` (V0–V3) + скрины waiting → after call.  
**FAIL:** network `check_status` + console.  
**Вердикт:** PASS → F не делать · FAIL → Slice F · BLOCKED → стоп (нет телефона / fallback=true / SMS.ru down).

## Матрица отказа (Slice F)

| Симптом | Куда |
|---------|------|
| `check_status` вечно `confirmed:false` | SMS.ru / `SmsRuClient` / status parse / TTL |
| API `confirmed:true`, UI не уходит | `interpretCallcheckPoll` / poll / `onVerified` |
| UI complete, «не вошли» | linker / `MobileSessionIssuer` / cookie |
| 422/500 после звонка | linker / AR / tenant mismatch |
| Только SMS работает | Callcheck path; SMS fallback не ломать |

## Файлы (ожидаемо)

Код читать/править **только** при V FAIL (или для точечного разбора FAIL).

- `app/frontend/lib/phoneAuthCascade.js` — `interpretCallcheckPoll` → `action: "complete"`
- `app/frontend/components/PhoneAuthCodeStep.svelte` — poll `check_status` → `onVerified`
- `app/frontend/components/PhoneAuthWizard.svelte` — `init_callcheck` + закрытие wizard
- `app/controllers/shop/api/phone_otp_controller.rb` — `init_callcheck` / `check_status` API
- `app/services/shop/phone_otp.rb` — Callcheck status → confirmed
- `app/services/shop/phone_verified_customer_linker.rb` — customer + session после confirmed

**Соседи (blast-radius, по FAIL):**

- `app/services/shop/mobile_session_issuer.rb` — `refresh_token` / cookie, если «не вошли»
- `app/services/shop/sms_ru_client.rb` — только parse `callcheck` status, если API не confirmed

## Не ломать

- SMS fallback после ~40с / кнопка SMS
- Rate limits / cooldown Callcheck
- Session ownership shop API + tenant RLS
- Callcheck ≠ FlashCall (`/code/call` запрещён)
- Checkout гостем без auth

## Проверка

```bash
# Local (только если был Slice F):
node --test test/javascript/phone_auth*.mjs test/javascript/*callcheck*.mjs
ruby bin/rails test test/services/shop/phone_otp* test/integration/shop/api/*phone_otp* test/services/shop/phone_verified_customer_linker_test.rb

# Обязательно live Slice V (Point A, fallback=false, реальный звонок)
```

## OUT

- Рефакторинг wizard «с нуля» / FlashCall / email в wizard
- Payments / CartSheet / #71
- Менять default `SHOP_OTP_LOG_FALLBACK` без нужды
- RSpec/Vitest — только Minitest + `node --test`
