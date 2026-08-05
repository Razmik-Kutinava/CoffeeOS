# MCP — #40 T-Bank auto refund on PWA cancel · Fly v428 · 2026-08-04 (+ modal 2026-08-05)

| Проверка | Результат |
|----------|-----------|
| Push `develop` | `e2c10736` (+ ops tips) |
| Fly image | `deployment-01KZ6M11H6F1RJ4GPMND07P57R` |
| Version | **v428** |
| HTTP | `/up` **200** · `/shop` Point A **200** |
| SSH code | `cancel_payment` **true** · `REFUND_UNAVAILABLE` **true** |
| MCP UI pending_payment cancel | **PASS** · `#202608-0003` → `cancelled` · payment `failed` |
| MCP UI ready block | **PASS** · `#202608-0005` · «Написать в поддержку» |
| MCP UI accepted modal | **PASS** · `#202608-0006` · modal + confirm → `cancelled` · toast |
| Live T-Bank `/v2/Cancel` E2E | **отложено** — modal/cash path без PaymentId; боевой Cancel не дёргали |
| SMOKE_OK | **true** |

## Сценарии

1. **pending_payment cancel** — `#202608-0003` · без модалки · toast success · payment `failed`.

2. **ready — блок** — `#202608-0005` · «Написать в поддержку» · нет cancel.

3. **accepted — модалка (2026-08-05)**  
   Cash `accepted` `#202608-0006` · CTA «Отменить заказ» + hint «Вернем 100% суммы» → modal  
   «Отменить заказ №#202608-0006?» · «Вернём 179 ₽…» · «Да, отменить и вернуть 179 ₽» / «Оставить заказ»  
   Confirm → toast success · DB `cancelled` (cash local, payment остался `succeeded` — без T-Bank Cancel).

## Скрины

| Файл | Что |
|------|-----|
| `01_shop_point_a.png` | Витрина Point A |
| `02_pending_cancel_success_toast.png` | pending cancel toast |
| `03_*` / `03b_*` | ready · support CTA |
| `04_accepted_cancel_modal.png` | модалка accepted |
| `05_accepted_modal_cancel_success.png` | успех после confirm |

## Note

Двойной `#` в заголовке (`№#202608-…`) — косметика copy (`order_number` уже с `#`). Live `/v2/Cancel` — отдельный прогон на card `succeeded`+PaymentId.
