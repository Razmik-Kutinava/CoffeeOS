# todo — #71 QA reopen: не спрашивать email повторно после чека

| Поле | Значение |
|------|----------|
| **CBR** | #71 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md) |
| **Тип** | Fix / UX · hot-path post-pay |
| **Цель** | После первого email для чека — не показывать блок снова |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |

## SBR

- [x] **SPEC**
- [x] **RED** (`efc9fe59`)
- [x] **GREEN** (`870df0be`) · Entire `01M1V2FH9A8C7J6X35YF5RQSFE`
- [x] **/regress** — JS 16/0 · rails 10/0
- [x] **REVIEW** — bugbot fix `0c17ee9f` · security OK · push/CI

## Решение

| QA | Решение |
|----|---------|
| Запомнить → не спрашивать | LS receipt-email; hide только если `loadReceiptEmail()` не пуст (не profile) |

## Проверка

- `node --test test/javascript/email_collection_test.mjs`
- `bundle exec rails test test/integration/shop/checkout_acceptance_cbr_test.rb`
