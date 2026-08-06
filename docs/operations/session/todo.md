# todo — Active order + cart peek stack (фикс mutex)

**Баг:** при `has_active_order` `hideCartTail` прятал peek — add на карточке «пропадал».  
**Канон:** gesture → status → CTA → «уже в заказе» → checkout (стык, не mutex).

| # | Шаг | Статус |
|---|-----|--------|
| 1 | RED: тесты статус+peek вместе | `[x]` |
| 2 | GREEN: убрать hideCartTail; STATUS_IN_SHEET_EXTRA_VH; prog38 | `[x]` |
| 3 | Регрессия cart sheet zone | `[x]` 57/0 |
| 4 | Ops + commit | `[x]` |
| 5 | Push / Fly / MCP | `[ ]` ждёт апрув |
