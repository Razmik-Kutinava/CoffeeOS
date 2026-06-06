# Code review Веха 1 (перед живым демо)

**Дата начала:** 2026-05-25  
**Ветка:** `develop` (незакоммиченный дифф В1)  
**Цель:** качество диффа и риски до H.3 (живое демо). Поведение уже закрыто H.2 (`docs/operations/milestones/veha_1/qa/QA_ACCEPTANCE_RUN.md`).

**Коммит / деплой:** только после апрува владельца (не в этом шаге).

---

## Что делали

| Шаг | Действие | Результат |
|-----|----------|-----------|
| 1 | Скоуп: сервисы barista/shop/inventory/prep_kitchen, контроллеры смены/shop, миграции F/G | Список файлов в `git status` |
| 2 | Чеклист проекта: RLS, N+1, SQL-интерполяция, тенанты, гибрид смены | См. находки ниже |
| 3 | Прогон тестов по затронутому коду | См. § Тесты |
| 4 | Правки по находкам | Минимальный дифф, без «рефакторинга ради красоты» |

---

## Итог ревью

**Вердикт:** **можно к живому демо** после правки N+1 в shop checkout; блокеров безопасности/тенантов не найдено.

---

## Находки и действия

| ID | Severity | Файл | Находка | Действие |
|----|----------|------|---------|----------|
| CR-1 | Замечание | `app/services/shop/order_creator.rb` | N+1: `Product.find` в цикле по позициям корзины | **Исправлено:** preload `Product.where(id: …).index_by` |
| CR-2 | OK | `app/services/barista/order_creation_service.rb` | Гибрид: `shift.open?`, `cash_shift_id` | Без изменений |
| CR-3 | OK | `app/services/shop/order_creator.rb` | Shop без `cash_shift_id` | Комментарий + `docs/operations/milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md` |
| CR-4 | OK | `app/services/inventory/order_recipe_deduction.rb` | Списание: batch recipes, `lock` на stock | Без изменений (техдолг без StockMovement — В3) |
| CR-5 | OK | `app/services/barista/order_cancellation_service.rb` | Reason + audit + return movement, без SQL `#{}` | Без изменений |
| CR-6 | OK | `app/services/prep_kitchen/stock/movement_creator.rb` | Черновик + items в transaction | Без изменений |
| CR-7 | OK | `app/services/demo/environment_setup.rb` | `SET LOCAL` через `conn.quote`; `update_all` только demo PTS | Документировано как техдолг/демо |
| CR-8 | Nit | `app/services/shop/cart_service.rb` | Одиночный `Product.find` на add — приемлемо для одной позиции | Не трогали |
| CR-9 | OK | RBAC / RLS | `test/integration/auth/*`, `rls_tenant_isolation_test` | Покрыто тестами |
| CR-10 | OK | Гибрид смены | `block_g_cash_shift_test` + `docs/operations/milestones/veha_1/reference/ORDER_ENTRY_AUDIT.md` | Покрыто |

**Не входило в ревью:** полный стиль UI/Svelte, рефакторинг manager/platform, Domain Folders.

---

## Тесты после правок

```text
# после CR-1
bin/rails test test/services/shop/order_creator_test.rb
bin/rails test test/integration/shop/ test/integration/block_g_cash_shift_test.rb
```

Зафиксировать числа runs/assertions/failures в строке ниже после прогона.

| Прогон | Runs | Failures |
|--------|------|----------|
| shop + block_g (после CR-1) | **51**, 165 assertions | **0** (2026-05-25) |
| полный suite (до CR-1) | 479, 1896 assertions | 0 (2026-05-25) |

---

## Следующие шаги

1. Апрув владельца → коммит → деплой Fly (отдельно).
2. H.3 живое демо.
3. § I закрытие вехи в ops.

**Связанные доки:** [`PRACTICES.md`](PRACTICES.md) § Code review V1, [`CHECKLIST.md`](CHECKLIST.md), [`ORDER_ENTRY_AUDIT.md`](ORDER_ENTRY_AUDIT.md).
