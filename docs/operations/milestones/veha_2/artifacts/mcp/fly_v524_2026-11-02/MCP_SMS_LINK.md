# Fly v524 — симуляция SMS-ссылки (без телефона) · 2026-11-02

**Итог: PASS.** Реальную SMS не слали. Проверили тот же entrypoint, что в SMS: `GET /o/{hash}` на `coffeeos.fly.dev`.

## Подготовка

Ссылки по старым заказам были `expired` (якорь `ready_notified_at`/`ready_at` старше 48ч). Для MCP на проде обновили `ready_notified_at` (и при необходимости `ready_at`) у:
- `#202606-0186` (гость `b11-…@coffeeos.dev`) — happy
- `#202610-0013` (Арам) — **только** как чужой заказ для conflict; confirm в профиль Арама **не** нажимали

## Сценарии

| # | Что | Результат |
|---|-----|-----------|
| 1 | Happy: `/o/puqMeKDhR8yxjQqSAadT-JapVek` (чистый контекст) | redirect → `/shop?…&sms_entry=1#/profile?order=a6ea8c78-…`; история B11, заказ `#202606-0186` ([P3](P3_sms_shortlink_happy_profile.png)) |
| 2 | Conflict: сессия B11 → `/o/TOdCTXdwShaIm0N3ZhqiCQSjs3Y` (заказ Арама) | redirect с `sms_transition=…`; диалог «Открыть заказ другого профиля?» ([P4](P4_sms_conflict_dialog.png)); **Отмена** → сессия осталась B11 |
| 3 | Invalid: `/o/not-a-valid-hash` | HTML «Ссылка недействительна» без bind ([P5](P5_sms_link_invalid.png)) |

**Не делали:** живая SMS на телефон; confirm conflict (не входили в профиль Арама).
