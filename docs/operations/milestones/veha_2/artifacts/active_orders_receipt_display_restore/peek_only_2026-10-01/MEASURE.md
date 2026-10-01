# TASK_84-PEEK-ONLY-EXT — замер в браузере (local, 2026-10-01)

Стенд: Rails `:3001` + Vite, tenant `8c7f5bc7-…` (local Point A), viewport 390×844, `/orders/active` подменён (1 заказ, 3 позиции + модификатор).

| Шаг | `data-status-sheet-mode` | `.oss__panel` высота | Класс панели | Чек |
|-----|--------------------------|----------------------|--------------|-----|
| До клика | `peek` | 136px | `embedded` | — |
| «Состав заказа» | `peek` | 136px | `embedded receipt-open` | 673–774 (101px, `max-height: 101px; overflow-y: auto`), внутри панели 638–774 |
| Прокрутка чека вниз | `peek` | 136px | — | `Total Amount: 940₽` 751–766 — виден; `scrollTop` панели 110.5 → 110.5 (внешняя не скроллится) |
| «Состав заказа» повторно | `peek` | 136px | `embedded` | скрыт |

Скрин: [01_receipt_open_peek_total_390x844.png](01_receipt_open_peek_total_390x844.png)
