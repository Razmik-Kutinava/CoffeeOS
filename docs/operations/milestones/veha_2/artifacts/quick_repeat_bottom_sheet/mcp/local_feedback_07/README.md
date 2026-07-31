# MCP local — Quick Repeat feedback 07

**Дата:** 2026-07-31  
**Среда:** Rails `test`, Vite dev, viewport `390×680`  
**Сценарий:** через CDP подставлены 2 active orders и stale `frequent_items` при `has_active_order: true`.

## Результат

| Проверка | Факт | Итог |
|---|---|---|
| `peek` full-width | status sheet `width=390`, viewport `390`, `left=0`, `right=390` | PASS |
| Quick Repeat при active | `repeatVisible=false`, хотя API-stub содержит stale item | PASS |
| `expanded` | `data-status-sheet-mode=expanded`, `openReceipts=1` | PASS |
| one-open | после открытия №2: №1 `aria-expanded=false`, №2 `true`, receipts `1` | PASS |
| `hidden` | после `orders=[]`: status sheet отсутствует, rows `0` | PASS |

## Скриншоты

- `01_peek_full_width_repeat_hidden.png`
- `02_expanded_first_receipt.png`
- `03_expanded_second_receipt_only.png`

Для скриншота fixed-панель временно сдвинута CDP в видимую область browser viewport; код/CSS приложения не изменялись. До сдвига геометрия измерена отдельно: `390/390`, `left=0`, `right=390`.

**Ограничение:** это локальный MCP с детерминированным API-stub, не Fly acceptance. Fly deploy/push требует отдельной явной команды владельца.
