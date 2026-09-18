# todo — #93 TASK_93-H: Корзина cookie / overflow

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-H** |
| **Тип** | SBR · hot-path shop cart / session cookie |
| **Статус** | **SPEC** · Next: `/sbr` RED |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата H1–H3 · зонтик [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта H |
| **GATES** | [`GATES-block-H.md`](GATES-block-H.md) · session `todo.md` — живой канон |
| **Цель** | Большая корзина → **422 + clear**, не **500/NameError**; proactive line/byte cap |
| **OUT** | A–G / I–K · CartSheet UX · MobileCart server-side · deploy (L) |
| **Зависимость** | нет |

## Канон продукта (зафиксировано SPEC)

| ID | Решение |
|----|---------|
| **R1** | Нет голого `rescue ActionDispatch::CookieOverflow`; канон `OverflowError` → 422+clear; CookieOverflow только при `const_defined?` |
| **R2** | `Shop::CartService::OverflowError`; copy: `"Корзина переполнена. Мы её очистили — добавьте товары снова."` |
| **R3** | **Cookie + caps**; MobileCart/store **OUT**; **T-H2c SKIP** |
| **R4** | `MAX_CART_LINES=20` · `MAX_SESSION_CART_BYTES=3072` · guard в `touch_cart_session!`; qty caps 50/99 без изменений |
| **R5** | add **и** update ловят OverflowError |
| **R6** | bytes via `JSON.generate(cart).bytesize`; тесты stub порогов вниз |

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — GATES H `6d4a8a5f`
- [x] PHASE 1 `/spec` — зеркало session `todo.md`
- [x] PHASE 2 RED — T-H1a/b/c · T-H2a/b · T-H3a/b · `[RED]` `5a635be3`
- [x] PHASE 2 GREEN — R1–R6 · `[GREEN]` · все T-H* PASS (T-H2c skip)
- [ ] `/regress` — G4
- [ ] PHASE 3 `/review` — H1–H3 PASS · push · без deploy

## Файлы (ожидаемо)

- `app/controllers/shop/api/cart_controller.rb`
- `app/services/shop/cart_service.rb`
- `test/services/shop/cart_service_test.rb`
- `test/integration/shop/api/cart_overflow_test.rb` (новый)
- `test/integration/shop/api/cart_persistence_test.rb` (регресс)

## Не ломать / Проверка

См. канон в `docs/operations/session/todo.md` (тот же текст секций).
