# Ops refunds 2026-09-09 — Point A MIR `*5953`

Ручной возврат тестовых/демо оплат витрины на карту клиента (Т-Банк `/v2/Cancel` через `Payments::TbankOrderRefund`).

## Scope

- Tenant: Point A `2fdee1ac-4674-41ee-b89e-87b45643f789`
- Окно: `created_at >= 2026-09-08`
- Карта: MIR `220196******5953`

## Результат

| Заказ | PaymentId | Сумма | До | После | Банк |
|-------|-----------|-------|----|-------|------|
| `#202609-0032` | `9209785225` | 10₽ | succeeded / ready | refunded / cancelled | `REFUNDED` |
| `#202609-0031` | `9209742037` | 10₽ | succeeded / cancelled | refunded / cancelled | `REFUNDED` |

Уже были `refunded` до ops: `#0022`–`#0023`, `#0025`, `#0027`–`#0030` (те же 10₽ / вчерашние 179+358).  
`failed` / `pending` без списания — не трогали (`#0017`–`#0021`, `#0024`, `#0026`).

## Артефакты

- `payments_list.json` — снимок Point A после verify (все card succeeded → refunded)
- `refund_results.json` — ответы `/v2/Cancel` (2× `REFUNDED`, ErrorCode 0)

Деньги на карту: обычно 1–3 банковских дня (иногда мгновенно по MIR).
