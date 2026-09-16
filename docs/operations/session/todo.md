# todo — #90 POSTCALL-EXT: return after Callcheck → pay

| Поле | Значение |
|------|----------|
| **ID** | CBR **#90** (Google: TASK_89-POSTCALL-EXT) |
| **Тип** | SBR · EXT #89 — lifecycle return + resume + PaymentMethodsSheet |
| **Статус** | **GREEN** 2026-09-16 · ждёт `/regress` → `/review` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-89-POSTCALL-EXT-…md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-POSTCALL-EXT-Возврат%20в%20PWA%20после%20Callcheck%20и%20продолжение%20оплаты.md) |
| **Google** | https://docs.google.com/document/d/1w2VKMPaYZdsJcqNkLrpSbJBPuLE-7Sm9giQ8DcJ0Bq0/edit?usp=drivesdk |
| **Артефакты** | [`pwa_callcheck_return_continue_payment/`](../milestones/veha_2/artifacts/pwa_callcheck_return_continue_payment/) |
| **GATES** | [`GATES.md`](GATES.md) — G1–G4 baseline met · G5 Fly pending |
| **OUT** | #91 UI-EXT · SMS.ru backend · linker/session · PaymentMethodsSheet internals · FlashCall · CartSheet thresholds |

## SBR

- [x] PHASE 0 intake (сохранён; restart)
- [x] PHASE 1 `/spec` — канон в этом todo
- [x] PHASE 2 RED — copy «вернитесь»; visibility/pageshow ≠ init_callcheck; pending → «Проверяем номер» + poll; confirmed/SMS → openPaymentSheet
- [x] PHASE 2 GREEN — resume poll + copy + handoff; зона PASS + unlazy `--reverify`
- [ ] PHASE 3 `/review` — bugbot+security · Entire · push/CI · G5 Fly MCP

## Next

`/regress`

## DoD

1. Перед звонком — инструкция: позвонить → **вернуться в PWA** (проверка продолжится).
2. Уход в телефон **не** сбрасывает Callcheck / номер / checkout; **не** создаёт новый `init_callcheck`.
3. Возврат → resume auth flow; pending → «Проверяем номер» + polling той же сессии.
4. confirmed / SMS success → auth TASK_89 → **авто** `PaymentMethodsSheet`.
5. Повторный уход/возврат ≠ второй `init_callcheck` / повторная регистрация.

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/lib/phoneAuthCascade.js` | Copy CALLCHECK_HINT «вернитесь»; pending «Проверяем номер»; resume-хелперы |
| `app/frontend/components/PhoneAuthCodeStep.svelte` | `visibilitychange` / `pageshow`: resume poll без re-init; UI ожидания |
| `app/frontend/components/PhoneAuthWizard.svelte` | Не сбрасывать payload/screen на lifecycle; init только по CTA |
| `test/javascript/shop_phone_auth_cascade_smsru_test.mjs` | RED: copy + resume ≠ init; pending label |
| `test/javascript/phone_auth_wizard_test.mjs` | RED: lifecycle не дергает `init_callcheck` повторно |
| `test/integration/shop/auth_funnel_wizard_ui_test.rb` | Structural: hint «вернитесь» / pending в бандле |

**Blast-radius (+соседи, только если RED покажет дыру):**

| Path | Почему |
|------|--------|
| `app/frontend/routes/Checkout.svelte` | Уже `#89` `onWizardVerified` → `openPaymentSheet`; трогать только если handoff сломан после resume |
| `test/integration/shop/silent_refresh_frontend_structural_test.rb` | Регресс handoff post-verify → pay |
| `app/frontend/lib/phoneAuthWizard.js` | Опционально: pure resume-хелперы, если Wizard раздуется |

## Не ломать

1. Card / Rebill / Charge / SBP init и CTA «+сумма» → pay sheet.
2. Callcheck primary + SMS fallback; **не** возвращать `flash_call` / `/code/call`.
3. Backend `PhoneVerifiedCustomerLinker` / session / refresh_token (#89).
4. #91 UI-EXT (высота sheet / скрытие суммы) и CartSheet thresholds / STATUS_IN_SHEET.

## Проверка

```bash
ruby bin/rails test test/integration/shop/auth_funnel_wizard_ui_test.rb test/integration/shop/silent_refresh_frontend_structural_test.rb test/integration/shop/api/phone_otp_test.rb test/services/shop/phone_verified_customer_linker_test.rb
node --test test/javascript/phone_auth_wizard_test.mjs test/javascript/shop_phone_auth_cascade_smsru_test.mjs test/javascript/phone_otp_ui_test.mjs
```

**После GREEN / Review:** Fly MCP Point A (G5) — dial → leave → return → same Callcheck · PaymentMethodsSheet · no second init. Артефакт в `artifacts/pwa_callcheck_return_continue_payment/mcp/`.

**Unlazy:** после GREEN `node .agents/skills/unlazy/scripts/gate-check.mjs --reverify docs/operations/session/GATES.md`

## Next

`/sbr`
