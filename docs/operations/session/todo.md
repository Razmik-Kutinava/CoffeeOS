# todo — #73 Хранение и отображение фискальных чеков в ЛК

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 0 intake | ТЗ + CBR + artifacts | `/spec` — план, gap, пути, блокер схемы payload |

**CBR:** #73  
**ТЗ:** [`customer_tasks/Хранение и отображение фискальных чеков в личном кабинете.md`](../milestones/veha_2/requirements/customer_tasks/Хранение%20и%20отображение%20фискальных%20чеков%20в%20личном%20кабинете.md)  
**Артефакты:** [`artifacts/fiscal_receipts_personal_cabinet/`](../milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Серия:** после #72 (Receipt.Email). Не путать: #72 = исходящий контакт в Receipt; #73 = входящий fiscal notification + UI ЛК.

## Цель (1 предложение)

Принимать идемпотентно уведомления о фискализации от Т-Банка, сохранять чеки (ссылка, ФН/ФД/ФП, тип) и показывать их в истории заказов PWA — без своего QR и без API «запросить чек».

## Фазы SBR

- [x] PHASE 0 intake
- [ ] PHASE 1 SPEC (`/spec`)
- [ ] RED / GREEN (`/sbr`)
- [ ] /regress
- [ ] REVIEW

## Блокер (до GREEN)

Subtask 1: точная схема + пример fiscal notification payload. Без подтверждённых полей — обработчик не писать.

## Не ломать

Платежные webhook'и, checkout/payment, возвраты, auth PWA, mapping PaymentId/OrderId, ЛК #69 вне секции чека.
