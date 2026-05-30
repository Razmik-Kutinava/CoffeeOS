# Code review Веха 2

**Зачем:** фиксация ревью перед включением **реальной оплаты** и онбординга на проде — по образцу [`../veha_1/CODE_REVIEW.md`](../veha_1/CODE_REVIEW.md).

**Когда заполнять:** перед merge крупного блока (оплата, онбординг UI, киоск).

---

## Скоуп ревью (план)

| Блок | Файлы (ориентир) |
|------|------------------|
| Онбординг | `platform/tenants*`, `tenant_onboarding/*`, views |
| Оплата | `shop/order_creator`, callbacks, провайдер |
| Киоск | _TBD_ |
| RLS / tenant | controllers base, `Current` |

**Чеклист проекта:** `.cursor/rules/coffeeos-performance.mdc`, `coffeeos-core.mdc`.

---

## Итог ревью

**Вердикт:** **PASS для включения боевой оплаты на витрине** *(2026-05-30)*

Оплата Т-Банк: adapter, callback, idempotency, Outbox, Circuit Breaker, worker на Fly — соответствует `.cursor/rules`. Kiosk: `POST /kiosk/api/auth` + shop API reuse. Хвост: Flutter UI, refund (В3), UX таймаут БД.

## Тесты после ревью

```
kiosk auth: 6 runs, 0 failures (2026-05-30)
payment-related: см. PAYMENT.md прогоны 3–4
```
