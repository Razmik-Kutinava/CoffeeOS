# todo — #93 TASK_93-D: История заказов / ЛК список (per_page)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-D** |
| **Тип** | SBR · shop API history / ЛК |
| **Статус** | **GREEN** · Next: `/regress` · Entire `01M2STB3BHJ65BAYQM492QTT7P` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата TASK_93-D · зонтик [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта D |
| **GATES** | [`session/GATES.md`](GATES.md) · [`GATES-block-D.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-D.md) |
| **Цель** | Default `per_page=20` (не 1); max 50; ЛК / «сегодня» показывают пачку |
| **OUT** | active sheet · Quick Repeat · load-more · A–C/E/F · deploy (L) |

## Канон продукта

| ID | Решение |
|----|---------|
| **R1** | Default `per_page` = **20** |
| **R2** | Явный `per_page` в **1..50** |
| **R3** | Пустой / `"0"` / мусор → **20** |
| **R4** | `today=1` фильтр без изменений |
| **R5** | Клиенты без param → серверный default |

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — GATES D
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED — `faca7e3c`
- [x] PHASE 2 GREEN — формула per_page · T-D* PASS
- [ ] `/regress` — G2 orders + mvp_flow
- [ ] PHASE 3 `/review` — таблица D1–D3 PASS · push · **без deploy**

## Файлы

- `app/controllers/shop/api/orders_controller.rb` — `#history` default 20
- `app/frontend/routes/PersonalAccount.svelte` — без param (сервер 20)
- `app/frontend/routes/Orders.svelte` — `today=1` без param
- `app/frontend/lib/shopAccountOrders.js` — `perPage \|\| 20`
- `test/integration/shop/api/orders_controller_test.rb` — T-D1* · T-D3*

## Не ломать

1. История только своего `customer_id` + tenant
2. `today=1` — только сегодня
3. Гость без session → `[]`
4. Изоляция tenant
5. `active` / ACTIVE_ORDERS

## Проверка

```bash
bin/rails test test/integration/shop/api/orders_controller_test.rb
bin/rails test test/integration/shop/api/orders_controller_test.rb \
  test/integration/shop/api/mvp_flow_test.rb
```

## DoD

- [x] Default 20 · T-D1a–d · T-D3a/b PASS · D2 grep нет per_page=1 · max 50
- [ ] REVIEW-таблица · Deploy = L
