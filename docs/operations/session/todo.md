# todo — #89 PWA auth Callcheck → SMS + post-verify pay

| Поле | Значение |
|------|----------|
| **ID** | CBR **#89** |
| **Тип** | SBR · доп.задача: после Callcheck → session + экран оплаты |
| **Приоритет** | high |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` · `@coffeeos-cart-sheet` |
| **ТЗ** | [`TASK-89-Авторизация-регистрация-PWA-Callcheck-SMS.md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-Авторизация-регистрация-PWA-Callcheck-SMS.md) |
| **Google** | https://docs.google.com/document/d/1wDRuIFxAl1pBSxh305sEidRxj-Kd6vwjytFkOvWn2ZQ/edit?usp=drivesdk |
| **Артефакты** | [`pwa_auth_registration_callcheck_sms/`](../milestones/veha_2/artifacts/pwa_auth_registration_callcheck_sms/) |
| **Unlazy** | [`GATES.md`](GATES.md) — G1–G4 baseline met · G5 Fly pending |
| **OUT** | FlashCall `/code/call` · толщина шторки/CTA сумма (отдельный UX) · полный каскад Callcheck×2 из #80 · смена CartSheet thresholds |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec` — канон в этом todo
- [ ] PHASE 2 RED — падающие тесты: post-verify → `openPaymentSheet` / pay-stack; linker/session контракт
- [ ] PHASE 2 GREEN — `onWizardVerified` открывает оплату; wizard закрыт; зона PASS + `--reverify`
- [ ] PHASE 3 `/review` — bugbot+security · Entire · push/CI · G5 Fly MCP

## DoD (заказчик + Google)

1. Callcheck confirmed → `PhoneVerifiedCustomerLinker` → `MobileCustomer` + session + refresh_token (уже канон; не ломать).
2. После verify wizard скрыт, пользователь в checkout context (`phoneVerified` / contacts).
3. **Доп.задача:** сразу **экран оплаты** (`PaymentMethodsSheet` / pay-stack) — сейчас `onWizardVerified` только ставит флаги, **не** зовёт `openPaymentSheet`.
4. SMS fallback → тот же post-verify handoff.
5. FlashCall не возвращён.

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/routes/Checkout.svelte` | `onWizardVerified`: после `phoneVerified=true` + refresh_token → `openPaymentSheet()` (async; identityReady) |
| `test/integration/shop/silent_refresh_frontend_structural_test.rb` | RED: assert `onWizardVerified` вызывает `openPaymentSheet` (structural) |
| `test/integration/shop/api/phone_otp_test.rb` | Контракт check_status confirmed → refresh_token + customer (регресс) |
| `test/services/shop/phone_verified_customer_linker_test.rb` | Номер в БД / existing vs new (регресс заказчика «есть ли номер») |

**Blast-radius (+соседи, только если RED покажет дыру):**

| Path | Почему |
|------|--------|
| `app/frontend/components/PhoneAuthCodeStep.svelte` | poll `check_status` → `onVerified` (если complete не доезжает после tel:) |
| `app/frontend/lib/cartSheetStore.js` | `openCheckoutPayStack` внутри `openPaymentSheet` |
| `app/controllers/shop/api/phone_otp_controller.rb` | session/linker только если API не отдаёт confirmed/token |

## Не ломать

1. Card / Rebill / Charge / SBP init контракт и существующий CTA «+сумма» → pay sheet.
2. Callcheck primary + SMS fallback; **не** возвращать `flash_call` / `/code/call`.
3. CartSheet thresholds / `STATUS_IN_SHEET` / peek-stack без нужды.
4. Quick Repeat / status sheet / dismiss (#83/#84/#87).

## Проверка

```bash
ruby bin/rails test test/integration/shop/api/phone_otp_test.rb test/services/shop/phone_verified_customer_linker_test.rb test/services/shop/phone_otp_test.rb test/integration/shop/silent_refresh_frontend_structural_test.rb test/integration/shop/auth_funnel_wizard_ui_test.rb
node --test test/javascript/phone_auth_wizard_test.mjs test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_otp_ui_test.mjs
```

**После GREEN / Review:** Fly MCP Point A (G5) — Callcheck → wizard gone → PaymentMethodsSheet; phone в БД. Артефакт в `artifacts/pwa_auth_registration_callcheck_sms/mcp/`.

**Unlazy:** после GREEN `node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/session/GATES.md`
