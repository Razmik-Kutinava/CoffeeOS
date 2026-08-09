# B1.7 BR-6 — отмена заказа на экране оплаты (2026-06-04)

**Задача:** [B1_7_checkout_order_screen.md](../../requirements/customer_tasks/B1_7_checkout_order_screen.md) § BR-6 — **CLOSED** · апрув заказчика **2026-06-18**

**Стенд:** `https://coffeeos.fly.dev/shop?tenant_id=655aaccb-004a-4bb9-a50a-ce618854dda3`

**Заказ из репорта:** `#3565088f-5af1-48e0-95b6-c456f3bc26f8` · **64₽**

## Скрины

| Файл | Когда |
|------|--------|
| `b17_br6_payment_cancel_customer_2026-06-04.png` | скрин заказчика: `#/payment`, кнопка «Отмена…» не отменяет заказ *(положить вручную из чата — файл не в repo на момент регистрации)* |
| `b17_br6_payment_cancel_repro_2026-06-04.png` | *(после repro на Fly)* |
| `b17_br6_payment_cancel_after_2026-06-04.png` | *(после фикса)* |

**Repro JSON:** [b17_br6_payment_cancel_repro_2026-06-04.json](../b17_br6_payment_cancel_repro_2026-06-04.json)

**Прогон (после апрува):** `node bin/acceptance/b17_br6_payment_cancel_mcp.mjs` *(скрипт — TBD)*
