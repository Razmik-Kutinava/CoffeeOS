# todo — V3-SEC-OTP-MERGE (OTP → safe profile switch + card step-up)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-OTP-MERGE` |
| **Тип** | security / shop auth / PII + saved cards |
| **Приоритет** | high (impact) · medium (вероятность — только если обошли OTP) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **MVP** | **срез A** (switch + BindingStepUp gate); срез B (`confirm_merge`) — backlog без апрува |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | Callcheck/SMS rewrite · MDM fingerprint · staff RBAC / shop API keys · UI merge-шторка · fly deploy без апрува |
| **Parked** | `V3-SEC-SHOP-API-KEYS` — RED уже в tip; GREEN WIP локально — не мешать этому SBR |

## SBR

- [x] **SPEC** — todo + шапки SESSION/HANDOFF
- [ ] **RED** — падающие тесты switch + step-up · `test: otp profile switch and card step-up [RED]`
- [ ] **GREEN** — linkers switch + BindingStepUp gate + docs · `feat: harden otp login merge vs saved cards [GREEN]`
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI
- [ ] **deploy** — только апрув владельца (не в GREEN)

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/services/shop/phone_verified_customer_linker.rb` | switch на OTP-профиль вместо absorb donor→session |
| `app/services/shop/email_verified_customer_linker.rb` | то же для email OTP |
| `app/services/shop/customer_profile_merger.rb` | не тащить `MobilePaymentMethod` без явного allow / не звать из linker по умолчанию |
| `app/services/payments/binding_step_up.rb` | после OTP login в профиль с картами — requires_step_up до unlock |
| `app/services/shop/one_click_payment_service.rb` | блок charge до step-up (`step_up_required`) |
| `docs/product/security/phase_1_rbac_closure/SHOP_API_AUTH.md` | абзац: OTP = login; saved cards = step-up |

**Соседи (blast-radius, hot-path):**

| Path | Почему |
|------|--------|
| `app/services/shop/sbp_autopay_charge_service.rb` | тот же gate на списание по сохранённому SBP |
| `app/controllers/shop/api/phone_otp_controller.rb` | точка входа verify → linker (не ломать rate limit / CSRF) |

**Тесты (зеркало):**

| Path | Зачем |
|------|--------|
| `test/services/shop/phone_verified_customer_linker_test.rb` | guest+card donor → session = OTP customer; guest PM count 0 |
| `test/services/shop/email_verified_customer_linker_test.rb` | аналогично (создать, если нет) |
| `test/services/shop/customer_profile_merger_test.rb` | карты не едут без явного allow |
| `test/services/payments/binding_step_up_test.rb` | one-click до step-up → ошибка; после — OK (mock) |

При необходимости +1: `test/integration/shop/api/ownership_idor_test.rb` (регрессия).

## Acceptance (срез A)

1. **AC-1** — после OTP session → существующий verified-профиль B (switch), не «гость A съел B».
2. **AC-2 MVP** — два жирных профиля: **не** auto-merge с переносом PM; switch на OTP-профиль B (данные A не мержить). Срез B confirm_merge — backlog.
3. **AC-3** — после входа в профиль с PM: one_click / sbp_charge / RebillId → блок `step_up_required` до `Payments::BindingStepUp`.
4. **AC-4** — нет второго профиля → create/attach как сейчас.
5. **AC-5** — легитимный OTP + step-up → платит как раньше.
6. **AC-6** — structured log: `session_customer_id`, `otp_customer_id`, `action=switch|merge|blocked`, `payment_methods_moved=0|N` (без OTP/PAN).
7. **AC-7** — короткий абзац в security doc.

## RED-сценарии (обязательные)

1. Session guest + existing phone customer with card → после `link!` session = **phone customer id**.
2. `MobilePaymentMethod` у session-guest после link = **0** (карты у OTP-профиля).
3. One-click до step-up → ошибка / `step_up_required`.
4. После step-up → one-click допускается (mock TBank).
5. Нет второго профиля → create/attach как сейчас.
6. Старый тест «merges phone customer into session…» — **заменить** на switch-контракт.

## Не ломать

1. Легитимный OTP login — история заказов видна после verify.
2. Rate limits `shop/phone_otp_*` / `shop/email_otp` (Rack::Attack) + браузерный CSRF-путь.
3. Ownership IDOR заказов — `ownership_idor_test` зелёный.
4. Binding step-up happy-path для привязки карты (после успешного step-up) + гостевой checkout без OTP.

## Проверка

```bash
bin/rails test test/services/shop/phone_verified_customer_linker_test.rb \
  test/services/shop/email_verified_customer_linker_test.rb \
  test/services/shop/customer_profile_merger_test.rb \
  test/services/payments/binding_step_up_test.rb
bin/rails test test/integration/shop/api/ownership_idor_test.rb
```

После GREEN + deploy (апрув): Fly MCP Point A — OTP login → карты видны → one_click без step-up **отклонён** → после step-up OK (live charge — только по апруву).

## DoD (дыра закрыта)

Даже при украденном OTP: история возможна, **списание с сохранённых карт — только после step-up**. Легитимный пользователь: OTP + step-up → платит как раньше.
