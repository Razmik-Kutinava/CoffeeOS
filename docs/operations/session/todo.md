# todo — #93 TASK_93-D: История заказов / ЛК список (per_page)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-D** |
| **Тип** | SBR · shop API history / ЛК |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата TASK_93-D · зонтик [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта D |
| **GATES** | [`session/GATES.md`](GATES.md) · [`GATES-block-D.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-D.md) |
| **Цель** | Default `per_page=20` (не 1) при отсутствии/нуле/мусоре; max 50; ЛК / «сегодня» показывают пачку заказов |
| **OUT** | active orders sheet · Quick Repeat · UI load-more · A/B/C · deploy (L) · products/categories per_page |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1** | Default `per_page` = **20** |
| **R2** | Явный `per_page` уважается в **1..50** |
| **R3** | Пустой / `"0"` / мусор → default **20**, не 1 |
| **R4** | `today=1` фильтр без изменений; меняется только размер страницы |
| **R5** | Клиенты без param → серверный default; `shopAccountOrders` может слать 20 |

Формула (GREEN):

```ruby
raw = params[:per_page].presence&.to_i
per_page = raw.nil? || raw < 1 ? 20 : [ raw, 50 ].min
```

## SBR

- [x] PHASE 0 `/start` — бриф TASK_93-D в чате
- [x] `/unlazy` — GATES D `2e9fce04` (G1–G3 unmet · G4→L)
- [x] PHASE 1 `/spec` — этот todo
- [ ] PHASE 2 RED — T-D3a/b (+ T-D1*) падают · коммит `[RED]`
- [ ] PHASE 2 GREEN — формула per_page (+ клиент по желанию) · коммит `[GREEN]` · все T-D* PASS
- [ ] `/regress` — G2 orders + mvp_flow
- [ ] PHASE 3 `/review` — таблица D1–D3 PASS · push · **без deploy**

## Файлы (ожидаемо)

- `app/controllers/shop/api/orders_controller.rb` — `#history`: default 20 / max 50 / blank→20
- `app/frontend/routes/PersonalAccount.svelte` — `api("/orders/history")` без `per_page=1`
- `app/frontend/routes/Orders.svelte` — `today=1` без `per_page=1`
- `app/frontend/lib/shopAccountOrders.js` — `perPage \|\| 20` (регресс D2a)
- `test/integration/shop/api/orders_controller_test.rb` — T-D1a–d · T-D3a/b

### Blast-radius (+соседи)

- `app/frontend/routes/Profile.svelte` — уже через `fetchAccountOrderHistory` (не ломать; не трогать без нужды)
- Другие `per_page.to_i` в products/categories — **вне scope** D

## Матрица приёмки (RED → GREEN)

| ID | Тест | Файл |
|----|------|------|
| T-D1a | without per_page → length == min(n,20), не 1 | `orders_controller_test` |
| T-D1b | blank/zero per_page → default, не 1 | ↑ |
| T-D1c | per_page=999 → length ≤ 50 | ↑ |
| T-D1d | per_page=2 → length == 2 | ↑ |
| T-D2a | shopAccountOrders default 20 | code review / grep |
| T-D2b | PersonalAccount / Orders без per_page=1 | ↑ |
| T-D3a | ≥2 orders → history без param length ≥ 2 | `orders_controller_test` |
| T-D3b | ≥2 today → `today=1` без per_page length ≥ 2 | ↑ |

Без **T-D3a+b** блок не закрыт.

## Не ломать

1. История только своего `customer_id` + tenant
2. `today=1` — только заказы с сегодня
3. Гость без session → `[]`
4. Изоляция tenant (существующий test)
5. `active` endpoint / окно ACTIVE_ORDERS — не трогать

## Проверка

```bash
# G1 — матрица D
bin/rails test test/integration/shop/api/orders_controller_test.rb

# G2 — узкий регресс (/regress)
bin/rails test test/integration/shop/api/orders_controller_test.rb \
  test/integration/shop/api/mvp_flow_test.rb
```

## DoD блока D

- [ ] Default `per_page` = 20 (не 1) при отсутствии/нуле
- [ ] T-D1a–d PASS
- [ ] T-D3a, T-D3b PASS
- [ ] D2 клиент / grep PASS
- [ ] Max 50 сохранён
- [ ] REVIEW-таблица D1–D3 \| тест ID \| PASS
- [ ] Deploy = TASK_93-L
