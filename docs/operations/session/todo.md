# todo — #90 POSTCALL-EXT: return after Callcheck → pay

| Поле | Значение |
|------|----------|
| **ID** | CBR **#90** (Google: TASK_89-POSTCALL-EXT) |
| **Тип** | SBR · EXT #89 — lifecycle return + resume + PaymentMethodsSheet |
| **Приоритет** | high |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` · `@coffeeos-cart-sheet` |
| **ТЗ** | [`TASK-89-POSTCALL-EXT-Возврат в PWA после Callcheck и продолжение оплаты.md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-POSTCALL-EXT-Возврат%20в%20PWA%20после%20Callcheck%20и%20продолжение%20оплаты.md) |
| **Google** | https://docs.google.com/document/d/1w2VKMPaYZdsJcqNkLrpSbJBPuLE-7Sm9giQ8DcJ0Bq0/edit?usp=drivesdk |
| **Артефакты** | [`pwa_callcheck_return_continue_payment/`](../milestones/veha_2/artifacts/pwa_callcheck_return_continue_payment/) |
| **Unlazy** | [`GATES.md`](GATES.md) — G1–G4 baseline met · G5 Fly pending |
| **OUT** | TASK-89-UI-EXT (толщина/сумма/сетка) · SMS.ru backend · linker/session algorithm · PaymentMethodsSheet internals · FlashCall · CartSheet thresholds |

## SBR

- [x] PHASE 0 intake
- [x] PHASE 1 `/spec` — канон в этом todo
- [x] PHASE 2 RED — падающие тесты: copy «вернитесь»; visibility/pageshow ≠ init_callcheck; pending → «Проверяем номер» + poll; confirmed/SMS → openPaymentSheet
- [x] PHASE 2 GREEN — resume poll + copy + handoff сохранён; зона PASS + `--reverify`
- [x] PHASE 3 `/review` — bugbot+security · Entire · push/CI · G5 Fly MCP (после deploy)


## DoD (заказчик + Google)

1. Перед звонком — инструкция: позвонить → **вернуться в PWA** (проверка продолжится).
2. Уход в телефон **не** сбрасывает Callcheck / номер / checkout; **не** создаёт новый `init_callcheck`.
3. Возврат → resume auth flow + check существующей сессии; pending → «Проверяем номер» + polling.
4. confirmed / SMS success → auth TASK_89 → **авто** `PaymentMethodsSheet` (без ручного CTA оплаты).
5. Повторный уход/возврат не делает второй `init_callcheck` / повторную регистрацию.

**Regress:** 2026-09-16 local PASS (rails 26 · node 27 · G1–G4 reverify). Fly MCP G5 — на Review/deploy.

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/lib/phoneAuthCascade.js` | Copy CALLCHECK_HINT «вернитесь в приложение»; label pending «Проверяем номер»; хелперы resume (если нужны) |
| `app/frontend/components/PhoneAuthCodeStep.svelte` | `visibilitychange` / `pageshow`: resume poll без re-init; UI ожидания после возврата |
| `app/frontend/components/PhoneAuthWizard.svelte` | Не сбрасывать `callcheckPayload`/screen на lifecycle; init только по CTA «Продолжить» |
| `test/javascript/shop_phone_auth_cascade_smsru_test.mjs` | RED: copy + resume ≠ init; pending label |
| `test/javascript/phone_auth_wizard_test.mjs` | RED: lifecycle не дергает `init_callcheck` повторно |
| `test/integration/shop/auth_funnel_wizard_ui_test.rb` | Structural: hint «вернитесь» / pending copy в бандле |

**Blast-radius (+соседи, только если RED покажет дыру):**

| Path | Почему |
|------|--------|
| `app/frontend/routes/Checkout.svelte` | Уже `#89` `onWizardVerified` → `openPaymentSheet`; трогать только если handoff сломан после resume |
| `test/integration/shop/silent_refresh_frontend_structural_test.rb` | Регресс handoff post-verify → pay |

## Не ломать

1. Card / Rebill / Charge / SBP init и CTA «+сумма» → pay sheet.
2. Callcheck primary + SMS fallback; **не** возвращать `flash_call` / `/code/call`.
3. Backend `PhoneVerifiedCustomerLinker` / session / refresh_token (#89).
4. TASK-89-UI-EXT (высота sheet / скрытие суммы) и CartSheet thresholds / STATUS_IN_SHEET.

## Проверка

```bash
ruby bin/rails test test/integration/shop/auth_funnel_wizard_ui_test.rb test/integration/shop/silent_refresh_frontend_structural_test.rb test/integration/shop/api/phone_otp_test.rb test/services/shop/phone_verified_customer_linker_test.rb
node --test test/javascript/phone_auth_wizard_test.mjs test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_otp_ui_test.mjs
```

**После GREEN / Review:** Fly MCP Point A (G5) — dial → leave → return → same Callcheck · PaymentMethodsSheet · no second init. Артефакт в `artifacts/pwa_callcheck_return_continue_payment/mcp/`.

**Unlazy:** после GREEN `node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/session/GATES.md`
