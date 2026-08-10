# CoffeeOS — карта интеграций (индекс)

**Bridge-контракт:** endpoint → ключи → БД → edge cases. Не доки Т-Банка/SMS.ru.

## Как читать (меньше токенов)

1. **Сначала только этот файл** (~45 строк).
2. **Один** секционный файл из таблицы — не все сразу.
3. `@docs/integrations/INTEGRATIONS.md` = индекс. Детали: `@docs/integrations/tbank.md` и т.д.

**Обновление:** тронул bridge → правь **индекс (если маршрут)** + **секционный файл** (`.cursorrules`).

**Канон:** `Payments::TbankAdapter` · tenant/RLS · hot-path баг → `/trace-bug` · приёмка Fly **Point A** `2fdee1ac-4674-41ee-b89e-87b45643f789`

---

## Маршрутизация

| Задача / симптом | Читай |
|------------------|--------|
| Оплата, webhook, 3DS, карты, RebillId, СБП | [`tbank.md`](tbank.md) |
| Flash call, SMS OTP, cascade «заказ готов» | [`sms-auth.md`](sms-auth.md) |
| Merge профиля, phone/email, «потерянная история» | [`sms-auth.md`](sms-auth.md) § Identity |
| Бонусы, push, WS, fiscal callbacks | [`notify-loyalty.md`](notify-loyalty.md) |

---

## Быстрые ключи (частые баги)

| Внешнее | Наше |
|---------|------|
| `OrderId` / `PaymentId` | `orders.id` / `payments.provider_payment_id` |
| `CustomerKey` | `mobile_customers.id` |
| `RebillId` | `mobile_payment_methods.card_token` |
| phone OTP | `PhoneNormalizer` → `mobile_otp_codes` |

Webhook idem: `tbank:callback:{PaymentId}:{Status}`. Terminal payment status **не откатывается**.

---

## SPEC задачи

Секция «Затронутые сервисы»: индекс + пути секций (не `@codebase`).

*2026-08-10 · индекс в docs/integrations/ рядом с секциями*
