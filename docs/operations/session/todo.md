# todo — Hidden mode cards (SBR)

> Не путать с `CHECKLIST.md` вехи.  
> **ТЗ:** [`customer_tasks/Исправление режима отображения Hidden для карточек товаров.md`](../milestones/veha_2/requirements/customer_tasks/Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md)  
> **Скрины:** [`artifacts/product_card_hidden_mode/screenshots/`](../milestones/veha_2/artifacts/product_card_hidden_mode/screenshots/README.md)

## Текущая фаза

**PHASE 3: REVIEW done** · код на develop · апрув заказчика / MCP / deploy — отдельно

## Пункты SBR

### PHASE 1: SPEC — [x]
### PHASE 2: RED — [x] `986c304`
### PHASE 2: GREEN — [x] `71d6eb6` · `catalog_hidden_card_test` 7/0
### PHASE 3: REVIEW — [x]
- [x] Sanity: UI-only · без N+1/RLS · `CategorySection` 89 строк · CartSheet не тронут
- [x] Тесты задачи PASS
- [x] Ops: SESSION_STATE / CHANGELOG / HANDOFF
- [ ] Апрув заказчика / MCP Fly / deploy — ждать **go**

## Заметки

- Pre-existing shop 8 fail (не этот шаг) — не чинили
- Backlog edge: skeleton loader, orientation, empty category message
