# todo — #78 slice-5 · Shop API subscriptions

| Поле | Значение |
|------|----------|
| **CBR / корень** | #78 · Subtasks 24–28 |
| **ТЗ** | [`Архитектура подписки — планы биллинг и автосписание.md`](../milestones/veha_2/requirements/customer_tasks/Архитектура%20подписки%20—%20планы%20биллинг%20и%20автосписание.md) |
| **GREEN** | `c4e48db8` · Entire `01M1ZYPHF0EZYHM7C12W5PSPA7` |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | PWA (6) · Usage (2) · Cancel (3) · Renewal (4) · E2E (7) |

## SBR

- [x] **SPEC** (`39544ab0`)
- [x] **RED** (`084f0451`)
- [x] **GREEN** (`c4e48db8`)
- [x] **regress** PASS
- [x] **REVIEW** — bugbot+security fixes (duplicate purchase + inactive PM) · push CI
- [ ] **deploy** — только апрув владельца
- [ ] **Slice 6** — отдельным намерением

## Bugbot / Security

| Severity | Location | Finding | Fix |
|----------|----------|---------|-----|
| high | `subscriptions_controller#create` | duplicate purchase if already active/past_due | 422 `subscription already active` |
| medium | `resolve_payment_method!` | inactive PM accepted | `is_active: true` |

## Проверка

```bash
ruby bin/rails test test/services/subscriptions/ test/integration/shop/api/subscriptions_api_test.rb
# → 13/0 PASS after REVIEW fixes
```
