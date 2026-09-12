# /review — PHASE 3 REVIEW

**Канон (не дублировать):** [`spec-build-review.mdc`](../rules/workflow/spec-build-review.mdc) § PHASE 3.

Порядок: local → `bugbot`+`security-review` → Entire (`explain` не пустой, иначе attach, не push) → push/CI (логи, чин, снова push) → **CI green → стоп**. Deploy — апрув владельца.

## COMPONENT_MAP (опционально, после принятия)

Если задача **главная** для зоны карты (новый/удалённый/переименованный UI-компонент или смена связей CartSheet/OrderStatus*/GuestOrder*) и в ТЗ есть **БЛОК 4** — после зелёных тестов и принятия владельцем обновить только строки таблицы в `docs/operations/session/COMPONENT_MAP.md` (промпт из шапки файла / заказчика). Не главная → **не** читать и **не** править карту. Отдельный docs-коммит: `docs: update COMPONENT_MAP — [компонент]`.

## Обязательно в конце (копипаст)

`Next: deploy — только по апруву владельца`

Дыры до push: `Next: /sbr`
