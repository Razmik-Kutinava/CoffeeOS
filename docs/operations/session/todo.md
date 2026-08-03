# todo — Order status OS detect + Wallet/WebPush (#37)

**ТЗ:** [`customer_tasks/Адаптивный виджет статуса заказа Детекция ОС и подписка на уведомления.md`](../milestones/veha_2/requirements/customer_tasks/Адаптивный%20виджет%20статуса%20заказа%20Детекция%20ОС%20и%20подписка%20на%20уведомления.md)  
**Артефакты:** [`artifacts/order_status_os_detect_wallet_webpush/`](../milestones/veha_2/artifacts/order_status_os_detect_wallet_webpush/)  
**Фаза:** SPEC `[x]` · RED/GREEN 1–6 `[x]` · REVIEW `[x]` · MCP/deploy `[ ]`

## Шаги

| # | Что | Статус |
|---|-----|--------|
| 1 | `getDeviceOS` | `[x]` |
| 2 | CTA верстка в accordion | `[x]` |
| 3 | «Состав заказа» → receipt | `[x]` |
| 4 | iOS Wallet download | `[x]` |
| 5 | Android/Desktop FCM | `[x]` |
| 6 | Init restored state | `[x]` |

## REVIEW (2026-08-03)

- JS зона: **56/56 PASS**
- Rails: wallet_pass + mount + push_register + active_orders → **11/11 PASS**
- Sanity: RLS/session visibility на `wallet_pass`; N+1 нет (PassUpdater один заказ); Accordion **309** строк (warn — логика в lib)
- PKCS7 prod / device register — backlog PRACTICES `V2-#35-WALLET-PROD`
- MCP/deploy — ждут явный апрув
