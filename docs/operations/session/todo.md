# todo — V3-SEC-OTP-MERGE (OTP → safe profile switch + card step-up)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-OTP-MERGE` |
| **Тип** | security / shop auth / PII + saved cards |
| **Приоритет** | high (impact) · medium (вероятность — только если обошли OTP) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **MVP** | **срез A** (switch + BindingStepUp gate); срез B (`confirm_merge`) — backlog |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | Callcheck/SMS rewrite · MDM · staff RBAC · UI merge-шторка · fly deploy без апрува |
| **Parked elsewhere** | JOB-TENANT REVIEW done · shop API keys REVIEW (deploy апрув) |

## SBR

- [x] **SPEC** — `c9733b8b` (позже parked другим агентом; восстановлен)
- [x] **RED** — `51aa657e` · `test: otp profile switch and card step-up [RED]`
- [x] **GREEN** — `a7839074` · switch + BindingStepUp lock + one_click/SBP gate + docs (fix after race on `3a81f8a9`)
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI
- [ ] **deploy** — только апрув владельца

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/services/shop/phone_verified_customer_linker.rb` | switch на OTP-профиль |
| `app/services/shop/email_verified_customer_linker.rb` | то же |
| `app/services/shop/customer_profile_merger.rb` | `allow_payment_methods` (default false) |
| `app/services/payments/binding_step_up.rb` | session lock/unlock после OTP login |
| `app/services/shop/one_click_payment_service.rb` | блок до step-up |
| `docs/product/security/phase_1_rbac_closure/SHOP_API_AUTH.md` | OTP = login; cards = step-up |

**Соседи:** `sbp_autopay_charge_service.rb` · `phone_otp_controller.rb` · `payments_controller.rb` · `order_creator.rb` (Error#step_up_required)

## Не ломать

1. Легитимный OTP login — история после verify.
2. Rate limits OTP + CSRF browser.
3. Ownership IDOR — зелёный.
4. Binding step-up happy-path (`binding_step_up` unlock) + guest checkout.

## Проверка

```bash
bundle exec rails test test/services/shop/phone_verified_customer_linker_test.rb \
  test/services/shop/email_verified_customer_linker_test.rb \
  test/services/shop/customer_profile_merger_test.rb \
  test/services/payments/binding_step_up_test.rb
bundle exec rails test test/integration/shop/api/ownership_idor_test.rb
```

**Local 2026-09-09:** zone **11/11 PASS** · ownership_idor **11/11 PASS**

## DoD

Украденный OTP ≠ сразу charge сохранённых карт; после BindingStepUp unlock — платит как раньше.
