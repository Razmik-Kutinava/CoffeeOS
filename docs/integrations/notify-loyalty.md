# Bridge: уведомления, лояльность, legacy callbacks

## Лояльность [DRAFT]

| | |
|---|---|
| Схема | `loyalty_accounts`, `loyalty_transactions` |
| earn/spend | **нет сервиса** в `app/services/` пока |
| Merge | `CustomerProfileMerger#reassign_loyalty!` |

При начислениях: триггер (order succeeded?), idempotent txn, обновить этот файл.

## Push / WebSocket (не оплата)

| Роль | Путь |
|------|------|
| WS | `GuestOrderBroadcaster`, `GuestOrderChannel` |
| Presence | `OrderReadyPresence` (online → skip SMS) |
| FCM | `OrderStatusPushPayload`; `FCM_SIMULATE=1` |
| Cascade | WS/Push → `OrderReadyCascadeJob` → SMS |

Исходящие уведомления клиенту — не путать с webhook Т-Банка.

## Legacy callbacks

| Endpoint | Назначение |
|----------|------------|
| `POST /callbacks/payments` | `Callbacks::EventsController` |
| `POST /callbacks/fiscal_receipts` | фискальные колбэки |

ENV: `CALLBACK_*` как в проекте.

---

## Шаблон [DRAFT] интеграции

Файлы · endpoints · mapping keys · ENV · idempotency · edge cases · `bin/rails test …`

SPEC: «Затронутые сервисы из @docs/integrations/INTEGRATIONS.md».
