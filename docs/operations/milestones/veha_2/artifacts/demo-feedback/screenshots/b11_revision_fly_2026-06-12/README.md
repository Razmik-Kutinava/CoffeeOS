# B1.1 ревизия — Fly MCP скрины (2026-06-12)

Прогон: chrome-devtools MCP на `https://coffeeos.fly.dev`, tenant demo A.  
Заказ: `a6ea8c78-a0e1-47cc-b18d-0a9201a753f8` (card → pending_payment, оплата симулирована на Fly).

## Путь заказчика (workflow)

| Файл | Шаг |
|------|-----|
| `01_catalog_fly.png` | Каталог витрины |
| `02_product_fly.png` | Карточка товара → «В корзину» |
| `03_cart_fly.png` | Корзина → «Оформить заказ» |
| `04_checkout_fly.png` | Checkout (карта, email) |
| `05_step_accepted_fly.png` | Экран статуса: **Принят** (pending_payment) |
| `06_step_paid_fly.png` | **Оплачен** (WS без перезагрузки) |
| `07_step_preparing_fly.png` | **Готовится** (как макет заказчика) |
| `08_step_ready_fly.png` | **Готов** |

Артефакт: [`../../b11_revision_acceptance_2026-06-12.json`](../../b11_revision_acceptance_2026-06-12.json)
