# todo — MCP Point A пакет после deploy v450 (2026-08-13)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| push+deploy v450 + MCP пакет | done MCP report | фикс NET raw `Failed to fetch` · A6 frequent after cancel |

## Цель
Один deploy → MCP Point A по задачам агентов (шторка / #62 / ошибки / Callcheck / Repeat / статусы).

## Файлы (ожидаемо) — следующий фикс
- `app/frontend/routes/Checkout.svelte` — не писать сырой `e.message` в `sheetInlineError` на NET
- `app/frontend/components/PaymentMethodsSheet.svelte` — inline error surface
- `app/services/shop/customer_frequent_products_service.rb` (+ cache invalidate on cancel) — A6

## Не ломать
- #62 checkbox default / preserve
- СБП enable + «Оплатить быстро»
- Callcheck → SMS fallback
- Status inside cart sheet

## Проверка
- `bin/rails test` / JS zone по фиксу (когда будет GREEN)
- Fly MCP Point A recheck A6 + NET error UI
