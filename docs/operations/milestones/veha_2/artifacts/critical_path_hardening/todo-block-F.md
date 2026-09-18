# todo — #93 TASK_93-F: Callbacks / stuck payments / Events

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-F** |
| **Тип** | SBR · hot-path callbacks / payments |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата F1–F5 · зонтик [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта F |
| **GATES** | [`session/GATES.md`](../../../session/GATES.md) · [`GATES-block-F.md`](GATES-block-F.md) |
| **Цель** | Events без secrets закрыты на публичном стенде; rejected не держит `processing` 24h; stuck tbank дожимаются через GetState; fiscal soft-skip → явный алерт/retry |
| **OUT** | A–E / G–K · T‑Bank `notify` HMAC ломать · deploy (L) · gem’ы оплаты · Rack Redis (I) |
| **Зависимость** | **A до F** предпочтительно (GetState→succeeded может снова дернуть deduction) |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1 (F1)** | Fail-closed Events без пары `CALLBACK_SHARED_TOKEN` + `CALLBACK_SHARED_SECRET`, если `Rails.env.production?` **или** `ENV["FLY_APP_NAME"].present?` **или** `ENV["CALLBACK_FAIL_CLOSED"]=1`. В fail-closed `authenticate_*` **не** `return if blank` |
| **R2 (F2)** | Terminal `processed` / `failed` / **`rejected`** обновляет или удаляет claim; rejected/422 не оставляют `processing` 24h |
| **R3 (F2)** | **Release claim on reject** (`cache.delete`). После reject retry разрешён. После success → `duplicate: true, ok: true` |
| **R4 (F3)** | Stuck 30m / limit 50: с pid → `TbankPaymentSync`; без id → alert; sync errors → log+alert, job не падает |
| **R5 (F4)** | Skip → `Rails.error.report`; retry job **1×** только `payment_not_found`; `missing_fiscal_ids` — report без retry |
| **R6** | Amount mismatch Events → 422, не succeeded |

TTL claim: 24h на processed/failed; rejected → delete.

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — GATES F `f56db39b`
- [x] PHASE 1 `/spec` — зеркало session `todo.md`
- [x] PHASE 2 RED — T-F1a · T-F2a/b · T-F3a · T-F4a · `[RED]` `4913e432` / `1c7d71a7`
- [x] PHASE 2 GREEN — R1–R6 · `[GREEN]` `1b28a128` · все T-F* PASS (48 runs)
- [ ] `/regress` — G4
- [ ] PHASE 3 `/review` — F1–F5 PASS · push · без deploy

**Entire:** attach session `863c79d0-3a0a-4671-9180-2a0be7fd2ee0` → GREEN why-context (docs checkpoint)

## Файлы (ожидаемо)

- `app/controllers/callbacks/events_controller.rb`
- `app/jobs/payments/stuck_payments_check_job.rb`
- `app/services/payments/tbank_fiscal_notification_handler.rb`
- `app/jobs/payments/tbank_fiscal_retry_job.rb` (новый)
- `test/controllers/callbacks/events_controller_test.rb`
- `test/jobs/payments/stuck_payments_check_job_test.rb` (создать)
- `test/services/payments/tbank_fiscal_notification_handler_test.rb`

## Не ломать / Проверка

См. канон в `docs/operations/session/todo.md` (тот же текст секций).
