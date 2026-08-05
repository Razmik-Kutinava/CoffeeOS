# Artifacts — stuck orders / status sheet blocks payment

**Дата:** 2026-08-05  
**ТЗ:** [`customer_tasks/Зависшие заказы в статусной шторке PWA блокируют оплату.md`](../../requirements/customer_tasks/Зависшие%20заказы%20в%20статусной%20шторке%20PWA%20блокируют%20оплату.md)

## Скрины из чата Арама (канон)

Исходники пришли вложением в Cursor chat (Telegram screenshots). Имена канона:

| Файл | Содержание |
|------|------------|
| `01_pwa_sheet_stuck_orders.png` | PWA Point A: шторка с `#202606-0259` / `#202606-0257`, «Потеряно соединение…», cancel+push |
| `02_gm_order_202606-0259.png` | GM `/manager`: order accepted, payment **processing** |
| `03_shift_manager_filter_empty.png` | Shift manager Заказы: фильтр «Все» → «Ничего не найдено» |
| `04_gm_order_202606-0257.png` | GM: accepted + payment processing |
| `05_gm_order_202606-0094.png` | GM: бейдж «возврат», payment cash succeeded, возвратов нет |
| `06_gm_order_202606-0085.png` | GM: accepted + payment **succeeded** |
| `07_gm_order_202606-0084.png` | GM: accepted + payment processing |
| `08_chat_payment_statuses.png` | Вопрос: что значит succeeded / processing |
| `09_chat_blocks_testing.png` | «перекрывает пол экрана, не могу дойти до оплаты» |

Папка `screenshots/` — положить копии при наличии файлов; док задачи самодостаточен по тексту 1:1.
