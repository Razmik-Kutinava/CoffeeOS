# todo — #93 TASK_93-F: Callbacks / stuck payments / Events

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-F** |
| **Тип** | SBR · hot-path callbacks / payments |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата F1–F5 · зонтик [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта F |
| **GATES** | [`session/GATES.md`](GATES.md) · [`GATES-block-F.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-F.md) |
| **Цель** | Events без secrets закрыты на публичном стенде; rejected не держит `processing` 24h; stuck tbank дожимаются через GetState; fiscal soft-skip → явный алерт/retry |
| **OUT** | A–E / G–K · T‑Bank `notify` HMAC ломать · deploy (L) · gem’ы оплаты · Rack Redis (I) |
| **Зависимость** | **A до F** предпочтительно (GetState→succeeded может снова дернуть deduction) |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1 (F1)** | Fail-closed Events без пары `CALLBACK_SHARED_TOKEN` + `CALLBACK_SHARED_SECRET`, если `Rails.env.production?` **или** `ENV["FLY_APP_NAME"].present?` **или** `ENV["CALLBACK_FAIL_CLOSED"]=1`. В fail-closed `authenticate_*` **не** `return if blank`. Dev/test без флага — можно открыто; тесты ставят secrets или flag |
| **R2 (F2)** | После claim `processing`: terminal `processed` / `failed` / **`rejected`** → update **или** `Rails.cache.delete` claim. Rejected/422 **не** оставляют `processing` на 24h |
| **R3 (F2)** | **Release claim on reject** (`cache.delete`, как `Callbacks::TbankController#release_idempotency_claim`). После reject повтор с тем же key **может** обработаться заново. После **успеха** (`processed`) повтор → `duplicate: true, ok: true` без мутации |
| **R4 (F3)** | `StuckPaymentsCheckJob` (`STUCK_THRESHOLD` **30.minutes**, `limit(50)`): для каждого stuck tbank с `provider_payment_id` → `Payments::TbankPaymentSync` (GetState) → обновить статус; без id → alert only; ошибки sync → log + alert, job **не** падает целиком; если после sync всё ещё stuck → alert |
| **R5 (F4)** | Fiscal skip `payment_not_found` / `missing_fiscal_ids` → `Rails.error.report` (сигнал обязателен; не тихий success). **Retry:** enqueue `Payments::TbankFiscalRetryJob` **1 раз** только для `payment_not_found` (max attempts = 2 с учётом первого); `missing_fiscal_ids` — report **без** retry |
| **R6** | Amount mismatch на Events → **422**, payment **не** → succeeded (регресс) |

TTL claim: **24h** на `processed`/`failed` write; на `rejected` — **delete** (нет ghost processing).

## SBR

- [x] PHASE 0 `/start` — бриф TASK_93-F в чате
- [x] `/unlazy` — GATES F `f56db39b` (G1–G4 unmet · G5→L)
- [x] PHASE 1 `/spec` — этот todo (+ зеркало `todo-block-F.md`)
- [ ] PHASE 2 RED — T-F1a · T-F2a/b · T-F3a · T-F4a падают · коммит `[RED]`
- [ ] PHASE 2 GREEN — R1–R6 · коммит `[GREEN]` · все T-F* PASS
- [ ] `/regress` — G4 callbacks/payments + tbank sync
- [ ] PHASE 3 `/review` — таблица F1–F5 PASS · push · **без deploy**

## Файлы (ожидаемо)

- `app/controllers/callbacks/events_controller.rb` — R1 fail-closed env; R2/R3 release claim on `rejected`; audit_event terminal
- `app/jobs/payments/stuck_payments_check_job.rb` — R4 GetState/sync + alert
- `app/services/payments/tbank_fiscal_notification_handler.rb` — R5 report (+ enqueue retry)
- `app/jobs/payments/tbank_fiscal_retry_job.rb` — **новый**: 1 retry `payment_not_found`
- `test/controllers/callbacks/events_controller_test.rb` — T-F1 · T-F2 · T-F5
- `test/jobs/payments/stuck_payments_check_job_test.rb` — **создать** T-F3a–d
- `test/services/payments/tbank_fiscal_notification_handler_test.rb` — T-F4a–d

### Blast-radius (+соседи)

- `app/services/payments/tbank_payment_sync.rb` — **reuse** из stuck job (не ломать API sync)
- `app/controllers/callbacks/tbank_controller.rb` — **паттерн** `release_idempotency_claim` (не менять notify/HMAC в F)
- `test/controllers/callbacks/tbank_controller_test.rb` · `test/jobs/payments/tbank_callback_job_test.rb` — регресс §8

## Матрица приёмки (RED → GREEN)

| ID | Тест | Файл |
|----|------|------|
| T-F1a | secrets blank + fail-closed env → 401; payment unchanged | `events_controller_test` |
| T-F1b | только token, secret blank, fail-closed → 401 | тж |
| T-F1c | token+secret+hmac+idem → ok path | тж |
| T-F2a | amount mismatch 422 → claim **не** `processing` | тж |
| T-F2b | retry после mismatch с correct amount → не ложный duplicate ok | тж |
| T-F2c | success ×2 → второй `duplicate: true` | тж |
| T-F2d | missing idempotency key → 422; нет orphan processing | тж |
| T-F3a | stuck pending + pid → GetState → succeeded | `stuck_payments_check_job_test` |
| T-F3b | stuck без pid → alert; no crash | тж |
| T-F3c | GetState raise → alert + continue batch | тж |
| T-F3d | fresh <30m → no sync/no alert | тж |
| T-F4a | `payment_not_found` → `Rails.error.report` | `tbank_fiscal_notification_handler_test` |
| T-F4b | `missing_fiscal_ids` → report | тж |
| T-F4c | `payment_not_found` → enqueue fiscal retry ≤1 | тж |
| T-F4d | happy create receipt; no false report | тж |
| T-F5a/b | invalid token/HMAC → 401 (есть — дополнить дыры F1/F2) | `events_controller_test` |

Без **T-F2a** и **T-F3a** блок не закрыт.

## Не ломать

1. Happy path Events payment → succeeded + order accept (с учётом A, если смержен)
2. Valid HMAC + token; anti-replay stale timestamp
3. T‑Bank `notify` signature + amount mismatch release (уже есть) — **не трогать** в F
4. Fiscal duplicate `ofd_receipt_id` — идемпотентный create
5. Stuck job `limit(50)` / threshold 30m — не раздувать без нужды

## Проверка

```bash
# G1–G3 матрица F (+ регресс tbank notify path)
bin/rails test \
  test/controllers/callbacks/events_controller_test.rb \
  test/jobs/payments/stuck_payments_check_job_test.rb \
  test/services/payments/tbank_fiscal_notification_handler_test.rb \
  test/jobs/payments/tbank_callback_job_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb

# G4 регресс зоны
bin/rails test test/controllers/callbacks/ test/jobs/payments/ test/services/payments/tbank_payment_sync_test.rb
```
