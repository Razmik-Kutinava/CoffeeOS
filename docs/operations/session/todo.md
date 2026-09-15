# todo — #26 Repeat invalid token · Патч 1 (HTTP 422)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#26** · Патч 1 |
| **Тип** | docs patch (контракт Subtask 5) |
| **Приоритет** | high |
| **Ветка** | `develop` |
| **Канон** | `@coffeeos-task-patch` · `TASK_PATCH.md` · `@coffeeos-commit-ops` |
| **ТЗ** | [`Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md`](../milestones/veha_2/requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) · секция **Патч 1: 2026-09-15** |
| **OUT** | код оплаты · FSM · i18n · TASK_85 / тексты по `error_code` |
| **EXT** | точные inline-ошибки по `error_code` → отдельная задача (TASK_85), не этот патч |

## SBR: docs patch (без RED/GREEN кода)

- [x] **Патч 1** — секция в TASK · Subtask 5 (patch v2): `422` + `error_code` / `500` без кода
- [ ] **TASK_85** — отдельный SBR (не в этой итерации)

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `…/customer_tasks/Главный экран — повторный заказ (невалидный токен)….md` | секция Патч 1 + заметки агента |
| `docs/operations/session/todo.md` | эта итерация |

**Не менять:** `payments_controller.rb`, `shopPayFsm*`, `Checkout*`, `PaymentMethodsSheet*`, i18n, тесты.

## Не ломать

1. Existing FSM / selection / invalid-token UI (см. «Не трогать» в Патче 1).
2. Соседние payment / SBP / auth flows.
3. Исходный дословный текст заказчика в шапке TASK (Шаг 5 с `400` остаётся как история; канон = Патч 1).

## Проверка

```bash
# docs-only — код не трогали
rg -n "Патч 1: 2026-09-15|patch v2|status: :unprocessable_entity" \
  "docs/operations/milestones/veha_2/requirements/customer_tasks/Главный экран — повторный заказ (невалидный токен) BottomSheet выбора способа оплаты.md" \
  app/controllers/shop/api/payments_controller.rb
```

Факт backend (аудит): `render_payment_error` → HTTP `422` + `error_code` (`payments_controller.rb:174–180`); `OrderCreator::Error` → `422` (`:36–39`).

## DoD

- [x] В TASK есть **Патч 1** с Исправленным сценарием Subtask 5 (patch v2)
- [x] Контракт: бизнес-ошибка T-Bank = `error_code` + HTTP `422`; системная без кода = `500`
- [x] Код оплаты / FSM / UI / i18n **не** изменены
- [x] Детализация текстов по `error_code` **не** в этом патче (→ EXT / TASK_85)
