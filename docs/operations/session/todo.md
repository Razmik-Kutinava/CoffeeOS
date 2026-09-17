# todo — #93 TASK_91: post-pay auto return → catalog + status

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** (Google: TASK_91) |
| **Тип** | SBR · EXT #71 post-pay email → авто `#/` + status model |
| **Статус** | **intake** 2026-09-17 · ждёт `/spec` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-91-Автоматический-возврат-на-каталог-после-post-pay-email.md`](../milestones/veha_2/requirements/customer_tasks/TASK-91-Автоматический-возврат-на-каталог-после-post-pay-email.md) |
| **Google** | https://docs.google.com/document/d/1nlWXyWV0UcV5X33i0owZixXRJl5d-nF_HwHdjjBVd2o/edit |
| **Артефакты** | [`post_pay_auto_return_catalog_status/`](../milestones/veha_2/artifacts/post_pay_auto_return_catalog_status/) · screenshots `01`–`03` |
| **GATES** | [`GATES.md`](GATES.md) — #93 unlazy baseline G1–G3 · G4 Fly pending |
| **OUT** | Checkout `completePaySuccess` · SBP #79/#86 · OrderStatusSheet internals · Quick Repeat #87 · `isCartSheetRoute` + `/payment-result` · immediate redirect on mount |

## SBR

- [x] PHASE 0 intake
- [ ] PHASE 1 `/spec`
- [ ] PHASE 2 RED
- [ ] PHASE 2 GREEN
- [ ] PHASE 3 `/review`

## Next

`/spec` — уточнить точки PaymentResult (submit/skip/nav API) + команды тестов #71/#35.

## DoD (черновик до SPEC)

1. После email submit или Skip на `#/payment-result?status=ok` — авто переход на `#/` без лишнего «В каталог».
2. На `#/` — существующая статусная модель (без правок её логики).
3. Нет auto-redirect при mount success screen (защита #71).
4. Continue «В каталог» (#35) остаётся рабочим.
5. Checkout / SBP recover / QR-QR не трогать.

## Файлы (ожидаемо)

_Заполняется на `/spec` (2–7 путей)._

## Не ломать

_Заполняется на `/spec` (hot-path)._

## Проверка

_Заполняется на `/spec`._
