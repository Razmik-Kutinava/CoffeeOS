# HANDOFF

Спринт: 1 | Задача: Синхронизация core(11) -> schema | Статус: done (миграционные батчи B1–B5)

Параллельно (Веха 1): `docs/operations/milestones/veha_1/` ([README](milestones/veha_1/README.md)).

Следующий шаг: при необходимости — B0 (документация canonical rename-mapping без `ALTER RENAME`) и/или отдельное решение по PL/pgSQL из core (`start_production_batch`, `complete_production_batch` и т.д., несовместимость `movement_type` с текущим `stock_movements` при переносе). После апрува — приведение кода под Service Objects (см. `MILESTONE_PRACTICES.md`).

Блокеры: нет
Последние коммиты: ожидает коммита пользователя
Открытые вопросы: нет (приоритет батчей зафиксирован в `docs/operations/GAP_LIST_CORE_SCHEMA.md`)
