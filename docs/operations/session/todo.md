# todo — #71 Slice A · CRM sync после оплаты (убрать stub)

| Поле | Значение |
|------|----------|
| **CBR / корень** | #71 Email-сбор после оплаты (Callcheck-флоу) · ST-9 |
| **ТЗ** | [`Email-сбор после оплаты (Callcheck-флоу).md`](../milestones/veha_2/requirements/customer_tasks/Email-сбор%20после%20оплаты%20(Callcheck-флоу).md) |
| **Bridge** | [`shop-api.md`](../../integrations/shop-api.md) § Orders · [`INTEGRATIONS.md`](../../integrations/INTEGRATIONS.md) |
| **Тип** | Feat / hot-path shop · post-pay CRM |
| **Цель** | `SyncContactToCrmJob` → реальный Brevo Contacts upsert (не log-only) |
| **CRM provider** | **Brevo Contacts** (тот же `BREVO_API_KEY`) |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **OUT** | UI email block · receipt job · bounce HMAC · payments · loyalty · Slice B opt-out · gem’ы CRM |

## Решения SPEC

| Тема | Решение |
|------|---------|
| CRM provider | **Brevo Contacts API** (`POST` + `updateEnabled`); не второй провайдер |
| Клиент | **`Shop::CrmContactSync`** (NEW) — отдельно от `BrevoClient` deliver_* |
| API key | тот же **`BREVO_API_KEY`** |
| List | опц. **`BREVO_CRM_LIST_ID`** |
| Kill-switch | опц. **`CRM_SYNC_ENABLED=0`** → no-op + log |
| Missing key / HTTP error | **`raise`** → Solid Queue retry (job не глотает) |
| Idempotency | upsert по email; **без DDL** |
| Identity attrs | `COFFEEOS_CUSTOMER_ID`, `COFFEEOS_ORDER_ID`, `COFFEEOS_TENANT_ID`, `MARKETING_CONSENT`; phone если есть |
| RSpec stub | удалить `spec/jobs/sync_contact_to_crm_job_spec.rb` на GREEN |

## SBR

- [x] **SPEC** (`30353d77` orphan / восстановлен в todo)
- [ ] **RED**
- [ ] **GREEN**
- [ ] **REVIEW**

## Файлы (ожидаемо)

- `app/services/shop/crm_contact_sync.rb` — NEW
- `app/jobs/sync_contact_to_crm_job.rb` — call sync; re-raise
- `test/services/shop/crm_contact_sync_test.rb` — NEW
- `test/jobs/sync_contact_to_crm_job_test.rb` — NEW
- `docs/integrations/shop-api.md` — CRM adapter + ENV
- `docs/integrations/INTEGRATIONS.md` — 1 абзац
- `spec/jobs/sync_contact_to_crm_job_spec.rb` — удалить

### Соседи

- `app/services/shop/brevo_client.rb` — не ломать deliver_*
- `app/models/order_email.rb` — enqueue (регресс)
- `test/integration/shop/api/orders_email_test.rb`
- `test/jobs/send_order_receipt_email_job_test.rb`

## Не ломать

1. Post-pay email save без OTP
2. Receipt через Brevo
3. `marketing_consent=false` → нет enqueue CRM
4. Bounce HMAC + bounced → CRM no-op
5. Оплата / T-Bank / Order status
6. `#77` `email_collected_at`

## Проверка

```bash
ruby bin/rails test test/jobs/sync_contact_to_crm_job_test.rb test/services/shop/crm_contact_sync_test.rb test/jobs/send_order_receipt_email_job_test.rb
ruby bin/rails test test/integration/shop/api/orders_email_test.rb
```
