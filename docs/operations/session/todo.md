# todo — #71 Slice A · CRM sync после оплаты (убрать stub)

| Поле | Значение |
|------|----------|
| **CBR** | #71 Email-сбор · ST-9 |
| **CRM provider** | **Brevo Contacts** (`BREVO_API_KEY`) |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | UI email · receipt · bounce HMAC · Slice B · payments |

## SBR

- [x] **SPEC**
- [x] **RED** (`6b3d714b`)
- [x] **GREEN** (`cb1e336d` · Entire `01M1ZZXV23N5BFK4SGDQV0H4KG`)
- [x] **regress** PASS (20/0)
- [x] **REVIEW** — bugbot `retry_on` · security OK · push CI

## Bugbot fix

- `retry_on` Shop::CrmContactSync::Error + StandardError (attempts: 5) — `fecee7e3`

## Проверка

```bash
ruby bin/rails test test/jobs/sync_contact_to_crm_job_test.rb test/services/shop/crm_contact_sync_test.rb test/jobs/send_order_receipt_email_job_test.rb
ruby bin/rails test test/integration/shop/api/orders_email_test.rb
```
