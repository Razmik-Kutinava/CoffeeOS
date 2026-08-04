# MCP — #40 T-Bank auto refund on PWA cancel · Fly v428 · 2026-08-04

| Проверка | Результат |
|----------|-----------|
| Push `develop` | `e2c10736` |
| Fly image | `deployment-01KZ6M11H6F1RJ4GPMND07P57R` |
| Version | **v428** (web+worker started, checks passing) |
| HTTP | `/up` **200** · `/shop?tenant_id=PointA` **200** |
| SSH code | `cancel_payment` **true** · `REFUND_UNAVAILABLE` **true** |
| MCP UI pending_payment cancel | **PASS** · `#202608-0003` → `cancelled` · payment `failed` · toast success |
| MCP UI ready block | **PASS** · `#202608-0005` status **Готов** · CTA **«Написать в поддержку»** · нет «Отменить заказ» |
| Live T-Bank `/v2/Cancel` E2E | **отложено** — не было `accepted`+`succeeded`+PaymentId в сессии гостя (не дёргали боевой Cancel на чужой платёж) |
| SMOKE_OK | **true** (deploy + FE cancel/block; Cancel API — unit + SSH method) |

## Сценарии

1. **pending_payment cancel (локальный, без банка)**  
   Guest `2bc3…4c` · order `#202608-0003` · UI «Отменить заказ» → «Отменяем…» → toast  
   `Заказ отменён. Деньги ушли на возврат…` · DB: `status=cancelled`, payment `failed`, reason гостевой.

2. **ready — блок отмены**  
   `#202608-0005` · heading **Готов** · кнопки **Написать в поддержку** / **Чаевые** · cancel CTA отсутствует.

## Скрины

| Файл | Что |
|------|-----|
| `01_shop_point_a.png` | Витрина Point A на v428 |
| `02_pending_cancel_success_toast.png` | Успех отмены + toast |
| `03_ready_support_cta_no_cancel.png` / `03b_ready_support_cta.png` | ready · support CTA |

## Note

Модалка accepted (`OrderCancelModal`) на MCP не ловилась: у `pending_payment` modal не показывается (`shouldShowAcceptedCancelModal` только для `accepted`). Live Cancel — при апруве на тестовый paid `accepted` заказ.
