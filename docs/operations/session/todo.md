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
| CRM provider | **Brevo Contacts API** (`POST/PUT` contact); не второй провайдер |
| Клиент | **`Shop::CrmContactSync`** (NEW) — отдельно от `BrevoClient` deliver_*; HTTP Contacts |
| API key | тот же **`BREVO_API_KEY`**; отдельный `BREVO_CRM_*` — нет |
| List | опц. **`BREVO_CRM_LIST_ID`** — listIds при upsert |
| Kill-switch | опц. **`CRM_SYNC_ENABLED=0`** → no-op + log (staging) |
| Missing key (non-test) | **`raise`** (`Shop::BrevoClient::Error` или свой) → Solid Queue retry |
| CRM HTTP error | **`raise`** из sync → job **не** глотает (сейчас `rescue` — убрать silent swallow) |
| Idempotency | upsert **по email** в Brevo; **без DDL** (`crm_synced_at` не нужен) |
| Identity attrs | `COFFEEOS_CUSTOMER_ID`, `COFFEEOS_ORDER_ID`, `COFFEEOS_TENANT_ID`, `MARKETING_CONSENT`; phone E.164 если есть |
| DDL | **нет** |
| RSpec stub | `spec/jobs/sync_contact_to_crm_job_spec.rb` — **удалить** на GREEN (канон только `test/`) |
| Slice B | bounce → CRM opt-out — **отдельно**, не в A |

## SBR

- [x] **SPEC** (этот файл)
- [ ] **RED** — `test: #71 CRM contact sync … [RED]`
- [ ] **GREEN** — `feat: #71 sync OrderEmail to Brevo CRM … [GREEN]` + regress
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI

## Файлы (ожидаемо)

- `app/services/shop/crm_contact_sync.rb` — NEW: upsert contact Brevo Contacts + attributes/list
- `app/jobs/sync_contact_to_crm_job.rb` — вызов sync; consent/bounce guard; **re-raise** ошибок
- `test/services/shop/crm_contact_sync_test.rb` — NEW: payload, upsert, error/missing key
- `test/jobs/sync_contact_to_crm_job_test.rb` — NEW: enqueue / bounced skip / CRM called / raise
- `docs/integrations/shop-api.md` — CRM больше не placeholder; ENV
- `docs/integrations/INTEGRATIONS.md` — 1 абзац Brevo Contacts adapter
- `spec/jobs/sync_contact_to_crm_job_spec.rb` — удалить (мёртвый RSpec)

### Соседи (blast-radius, не менять без нужды)

- `app/services/shop/brevo_client.rb` — эталон HTTP/key; **не ломать** `deliver_*`
- `app/models/order_email.rb` — enqueue при consent (уже ок; регресс)
- `test/integration/shop/api/orders_email_test.rb` — S9 consent enqueue
- `test/jobs/send_order_receipt_email_job_test.rb` — receipt не трогаем

## ENV (runbook / docs)

| Var | Назначение |
|-----|------------|
| `BREVO_API_KEY` | Contacts API (уже есть) |
| `BREVO_CRM_LIST_ID` | опц. list «маркетинг consent» |
| `CRM_SYNC_ENABLED` | опц. `0` → no-op log |

Секреты не в репо; Fly secrets — вне этого SBR (только документ).

## Не ломать

1. Post-pay email save без OTP (`EmailService` / `POST …/email`)
2. Receipt через Brevo (`SendOrderReceiptEmailJob`)
3. `marketing_consent=false` → **нет** enqueue CRM
4. Bounce webhook HMAC + `status=bounced` → CRM job no-op
5. Оплата / T-Bank webhook / Order status
6. `#77` `email_collected_at` / `mark_customer_email_collected!`

## Проверка

```bash
ruby bin/rails test test/jobs/sync_contact_to_crm_job_test.rb test/services/shop/crm_contact_sync_test.rb test/jobs/send_order_receipt_email_job_test.rb
ruby bin/rails test test/integration/shop/api/orders_email_test.rb
```

HTTP stub в тестах (как `brevo_client_test` / Net::HTTP) — **без** live Brevo в CI.

## RED subtasks (Minitest)

1. consent=true → job enqueued on create  
2. consent=false → job **not** enqueued  
3. perform → CrmContactSync called with email + customer_id + order_id (+ tenant)  
4. bounced → no CRM call  
5. CRM error → raises (retry path)  
6. second perform → upsert / same external id (stub)  
7. marketing_consent / opt-in в payload  

## Критерий «готово» (DoD Slice A)

- Stub log-only убран  
- Consent / bounce / idempotency в тестах  
- Docs: CRM adapter = Brevo Contacts  
- Slice B — отдельным намерением  
