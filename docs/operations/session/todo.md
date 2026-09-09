# todo — V3-SEC-JOB-TENANT-GUC (Solid Queue jobs → tenant GUC)

| Поле | Значение |
|------|----------|
| **ID** | `V3-SEC-JOB-TENANT-GUC` |
| **Тип** | security / background jobs / RLS |
| **Приоритет** | medium (код) · high если queue DB торчит (ops) |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-core` (tenant/RLS) · `@coffeeos-commit-ops` |
| **MVP** | **срез A** — `Rls::JobTenantContext` + wrap order-scoped jobs + тесты + audit/ops абзац |
| **Очередь** | **Solid Queue (Postgres)** — не Sidekiq/Redis (`production.rb` → `queue_adapter = :solid_queue`; worker `./bin/jobs`) |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | signed job args · полный `tenant_guc_inventory` всех jobs · Sidekiq/Redis · `fly deploy` / network audit без апрува · ломать global jobs |
| **Parked** | `V3-SEC-OTP-MERGE` (SPEC готов, RED не начат) · `V3-SEC-SHOP-API-KEYS` (RED tip + GREEN WIP) |

## SBR

- [x] **SPEC** — todo + шапки SESSION/HANDOFF
- [ ] **RED** — тесты хелпера/job GUC · `test: job tenant GUC context [RED]`
- [ ] **GREEN** — helper + wrap order jobs + `RLS_TENANT_AUDIT` · `feat: set tenant GUC in order-scoped jobs [GREEN]`
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI
- [ ] **Ops live** — Fly queue network / creds — **только апрув** владельца

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/services/rls/job_tenant_context.rb` | **новый** — `with(order)` / `with_tenant_id`: `Current.tenant_id` + `SET LOCAL app.current_tenant_id` (quote) + ensure сброс; **не** смешивать с flag-GUC в `guc_context.rb` |
| `app/jobs/application_job.rb` | тонкий wrapper `with_order_tenant!(order)` → JobTenantContext |
| `app/jobs/barista/broadcast_order_board_job.rb` | после `Order.find_by` → GUC по `order.tenant_id` |
| `app/jobs/shop/ready_push_job.rb` | то же |
| `app/jobs/shop/order_ready_cascade_job.rb` | то же |
| `app/jobs/payments/tbank_callback_job.rb` | после resolve payment/order → GUC по tenant заказа |
| `docs/product/security/phase_3_tenant_rls/RLS_TENANT_AUDIT.md` | Background jobs: OK(queue internal) → **FIXED** defense-in-depth + ops runbook абзац |

**Соседи (blast-radius, hot-path):**

| Path | Почему |
|------|--------|
| `app/jobs/send_order_receipt_email_job.rb` | OrderEmail → order → тот же helper |
| `app/jobs/shop/send_push_notification_job.rb` | notification.tenant_id → GUC |
| `app/jobs/broadcast_tv_columns_job.rb` | уже `tenant_id` arg — сверить/добавить GUC |
| `app/services/rls/guc_context.rb` | **не ломать** flag GUCs; JobTenantContext — отдельный класс |

**Не трогать (OK intentional):** `Payments::StuckPaymentsCheckJob`, `TelegramAlertJob` — global by design.

**Тесты (зеркало):**

| Path | Зачем |
|------|--------|
| `test/services/rls/job_tenant_context_test.rb` | без order → raise/no-op; с order A → GUC == A внутри блока |
| `test/jobs/barista/broadcast_order_board_job_test.rb` | создать при отсутствии — perform не падает; GUC выставлен |
| `test/jobs/shop/ready_push_job_test.rb` / `order_ready_cascade_job_test.rb` | регрессия happy-path зелёная |

## Acceptance (срез A)

1. **AC-1** — helper ставит `Current.tenant_id` + `SET LOCAL app.current_tenant_id` из **записи**, не из HTTP args.
2. **AC-2** — order-scoped jobs из таблицы обёрнуты (минимум 5–6 из ТЗ).
3. **AC-3** — нет публичного `perform_later(params[:order_id])` без ownership (grep; fix или ISSUES).
4. **AC-4** — ops чеклист в audit: Solid Queue DB private · worker только Fly · инцидент → rotate + audit `solid_queue_jobs`.
5. **AC-5** — тесты helper + регрессия существующих job tests.

## RED-сценарии

1. Helper без order → raise / documented no-op.
2. Order tenant A → внутри блока GUC == A (`SHOW` / connection helper).
3. `BroadcastOrderBoardJob` или `ReadyPushJob` perform — не падает; GUC выставлен.
4. Существующий ready/cascade happy-path остаётся зелёным после GREEN.

## Не ломать

1. Tbank callback → RebillId / статус оплаты (`perform_now` fallback при недоступной queue).
2. Ready cascade / push / WS board после смены статуса баристой.
3. `StuckPaymentsCheckJob` global scan + `TelegramAlertJob`.
4. HTTP ownership IDOR suite — не ослаблять.

## Проверка

```bash
bin/rails test test/services/rls/job_tenant_context_test.rb
bin/rails test test/jobs/shop/ready_push_job_test.rb test/jobs/shop/order_ready_cascade_job_test.rb
# после GREEN точечно новые job tests; inventory — глазами, не CI-блокер:
# ruby bin/audit/tenant_guc_inventory.rb
```

Ops (владелец, не агент без апрува): `fly postgres` / network — queue не public.
