# todo — #93 TASK_93-H: Корзина cookie / overflow

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-H** |
| **Тип** | SBR · hot-path shop cart / session cookie |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата H1–H3 · зонтик [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта H |
| **GATES** | [`GATES-block-H.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-H.md) (канон блока; `session/GATES.md` может быть чужим блоком) |
| **Цель** | Большая корзина → **422 + clear**, не **500/NameError**; proactive line/byte cap до commit cookie |
| **OUT** | A–G / I–K · UI CartSheet UX · полный MobileCart/PWA redesign · deploy (L) |
| **Зависимость** | нет (параллельно с D/F/…) |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1 (H1)** | Запрещён голый `rescue ActionDispatch::CookieOverflow` без `const_defined?`. Канон: `rescue Shop::CartService::OverflowError` → clear + **422**. Опционально вторичный rescue CookieOverflow **только если** `ActionDispatch.const_defined?(:CookieOverflow)` — тот же clear+422 |
| **R2 (H1)** | `Shop::CartService::OverflowError < StandardError`. Клиентское сообщение (стабильное): `"Корзина переполнена. Мы её очистили — добавьте товары снова."` |
| **R3 (H2)** | **Cookie + hard caps** (дешёвый DoD). **Server-side MobileCart/cache — OUT** этого прогона; **T-H2c SKIP**. `MobileCart` остаётся для profile merge — не трогаем |
| **R4 (H2)** | `MAX_CART_LINES = 20` (distinct lines в `session[:shop_cart]`). `MAX_SESSION_CART_BYTES = 3072` (~3KB JSON estimate payload корзины). Проверка в `touch_cart_session!` (после compact, до/при commit) → `raise OverflowError`. Сохраняем `MAX_CART_ITEMS = 50` (сумма qty) и `MAX_ITEM_QUANTITY = 99` |
| **R5 (H1/H3)** | `add` **и** `update` (`replace_line!` / `update_quantity!`) ловят OverflowError → 422 + clear. `destroy`/`clear`/`show` — без нового overflow path |
| **R6** | Оценка размера: `JSON.generate(@session[SESSION_KEY]).bytesize` (или эквивалент после compact). Тесты: stub `MAX_SESSION_CART_BYTES` / `MAX_CART_LINES` вниз для стабильности |

**H2 итог:** cookie + `MAX_CART_LINES` + `MAX_SESSION_CART_BYTES` достаточный DoD; DB store не открываем в H.

## SBR

- [x] PHASE 0 `/start` — бриф TASK_93-H в чате
- [x] `/unlazy` — GATES H `6d4a8a5f` (G1–G4 unmet · G5→L)
- [x] PHASE 1 `/spec` — этот todo (+ зеркало `todo-block-H.md`)
- [ ] PHASE 2 RED — T-H1a/b · T-H1c · T-H2a/b · T-H3a/b падают · коммит `[RED]`
- [ ] PHASE 2 GREEN — R1–R6 · коммит `[GREEN]` · все T-H* PASS (T-H2c skip)
- [ ] `/regress` — G4 § Проверка
- [ ] PHASE 3 `/review` — таблица H1–H3 PASS · push · **без deploy**

## Файлы (ожидаемо)

- `app/controllers/shop/api/cart_controller.rb` — OverflowError rescue на add+update; убрать/оговорить мёртвый CookieOverflow
- `app/services/shop/cart_service.rb` — `OverflowError` · `MAX_CART_LINES` · `MAX_SESSION_CART_BYTES` · guard в `touch_cart_session!`
- `test/services/shop/cart_service_test.rb` — T-H2a/b (lines/bytes → OverflowError)
- `test/integration/shop/api/cart_overflow_test.rb` — **новый**: T-H1a/b/c · T-H3a/b
- `test/integration/shop/api/cart_persistence_test.rb` — регресс persist (не ломать)

### Blast-radius (+соседи)

- `test/integration/shop/b113_s4_cart_modifiers_test.rb` — compact modifiers регресс (§ Проверка)
- **не трогать:** `app/models/mobile_cart.rb` · `customer_profile_merger` merge path

## Матрица приёмки (RED → GREEN)

| ID | Тест | Файл |
|----|------|------|
| T-H1a | stub/force OverflowError на add → **422** + error copy + cart empty | `cart_overflow_test` |
| T-H1b | нет NameError / нет голого CookieOverflow-only rescue | тж (source/assert) |
| T-H1c | update path (replace_line! / inflate) → 422 + clear | тж |
| T-H2a | distinct lines > `MAX_CART_LINES` → OverflowError | `cart_service_test` |
| T-H2b | estimated bytes > budget (stub низкий порог) → OverflowError | тж |
| T-H2c | server-side beyond cookie | **SKIP** (R3 cookie+cap) |
| T-H3a | POST add until overflow → **422 never 500** | `cart_overflow_test` |
| T-H3b | small cart 1–3 items → 200 | тж |

Без **T-H3a** блок не закрыт.

## Не ломать

1. Persist cart across requests (session cookie + api key) — `cart_persistence_test`
2. Compact modifiers — только `id` в session (не name/price blob)
3. `MAX_CART_ITEMS` / `MAX_ITEM_QUANTITY` (суммарный qty + per-line)
4. Pending order keeps cart until pay success; clear after successful pay

## Проверка

```bash
bin/rails test test/services/shop/cart_service_test.rb test/integration/shop/api/cart_overflow_test.rb test/integration/shop/api/cart_persistence_test.rb
```

Регресс после GREEN:

```bash
bin/rails test test/services/shop/cart_service_test.rb test/integration/shop/api/cart_persistence_test.rb test/integration/shop/b113_s4_cart_modifiers_test.rb
```
