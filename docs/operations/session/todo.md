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
- [ ] **regress** → `/regress`
- [ ] **REVIEW**

## Файлы

- `app/services/shop/crm_contact_sync.rb`
- `app/jobs/sync_contact_to_crm_job.rb`
- `test/jobs/sync_contact_to_crm_job_test.rb` · `test/services/shop/crm_contact_sync_test.rb`
- `docs/integrations/shop-api.md` · `INTEGRATIONS.md`

## Не ломать

1. Post-pay email без OTP
2. Receipt Brevo
3. consent=false → no CRM enqueue
4. Bounce HMAC / bounced skip
5. Pay / T-Bank
6. `#77` email_collected

## Проверка

```bash
ruby bin/rails test test/jobs/sync_contact_to_crm_job_test.rb test/services/shop/crm_contact_sync_test.rb test/jobs/send_order_receipt_email_job_test.rb
ruby bin/rails test test/integration/shop/api/orders_email_test.rb
```
