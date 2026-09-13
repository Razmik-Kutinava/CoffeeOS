# todo — TASK_83 Status sheet dismiss (крестик ×)

| Поле | Значение |
|------|----------|
| **ID** | `TASK_83` / CBR **#83** |
| **Тип** | витрина / PWA / статусная шторка (hot-path) |
| **Приоритет** | medium |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-83-status-sheet-dismiss.md`](../milestones/veha_2/requirements/customer_tasks/TASK-83-status-sheet-dismiss.md) |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | блок чека / `receiptView` · `shopOrderCable.js` · API · gem’ы оплаты · чужой scope «Восстановление чека» |
| **Gate до RED** | продуктовые решения §6 ТЗ: (1) dismiss + Cable до `ready`; (2) dismiss после reload |

## SBR

- [x] **SPEC** — этот файл · пути + Не ломать/Проверка
- [ ] **RED** — падающие тесты dismiss-контракта `[RED]` (после Gate продуктовых решений)
- [ ] **GREEN** — реализация только в scope dismiss `[GREEN]`
- [ ] **regress** — команды из «Проверка»
- [ ] **REVIEW** — local · bugbot+security · Entire · push/CI
- [ ] **deploy** — только апрув · затем Fly MCP Point A

## Файлы (ожидаемо)

| Path | Зачем |
|------|--------|
| `app/frontend/components/ActiveOrdersAccordion.svelte` | только `aoa__dismiss` / `onDismiss` (~139–150) |
| `app/frontend/lib/orderStatusSheet.js` | только `dismissOrder` / связанный `refreshMode` (~119–132+) |
| `test/javascript/order_status_notify_actions_test.mjs` | UI dismiss в аккордеоне (ТЗ §5) |
| `test/javascript/order_status_sheet_test.mjs` | unit `dismissOrder` / `dismissedIds` / sync |

**Соседи (blast-radius, не менять без нужды):**
- `app/frontend/components/OrderStatusSheet.svelte` — уже вызывает `dismissOrder` / `onDismissOrder`
- `app/frontend/lib/shopOrderCable.js` — **запрещено** (Cable)
- блок чека / `receiptView` в тех же UI-файлах — **запрещено** (задача «Восстановление чека»)

## Не ломать

1. Оплата / checkout / Repeat — dismiss не трогает серверный статус и API.
2. Блок чека / `receiptView` — общий файл с «Восстановление чека»; не диффать.
3. Cable-подписка (`shopOrderCable.js`) — обновления статусов продолжают работать.
4. Peek / hide on `ready` / статусная шторка вне крестика — без регрессии чужих сценариев.

## Проверка

```bash
yarn test test/javascript/order_status_notify_actions_test.mjs
yarn test test/javascript/order_status_sheet_test.mjs
```

(При необходимости типов: `yarn tsc` — если применимо к зоне.)

После deploy (не на SPEC): Fly MCP Point A + артефакт в `artifacts/status_sheet_dismiss_behavior/mcp/`.

## Продуктовые решения (обязательно до RED)

| # | Вопрос | Варианты | Решение |
|---|--------|----------|---------|
| 1 | После Cable-обновления (до `ready`) | остаётся скрытым / снова в шторке | **❓ ждёт владельца** |
| 2 | После перезагрузки страницы | dismiss сохраняется / заказ снова виден | **❓ ждёт владельца** |

Без ответов Cursor **не** выбирает поведение сам (ТЗ §6).

## DoD

- [ ] Решения Cable + reload зафиксированы
- [ ] Локальный dismiss × без API
- [ ] `dismissOrder` / `refreshMode` = контракт
- [ ] TDD-тесты на dismiss зелёные
- [ ] Чек / Cable не изменены
- [ ] «Проверка» PASS · REVIEW/CI · MCP после deploy
