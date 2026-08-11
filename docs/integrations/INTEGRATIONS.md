# CoffeeOS — карта интеграций (индекс)

**Bridge-контракт:** endpoint → ключи → БД → edge cases. Не доки Т-Банка/SMS.ru.

## Как читать (меньше токенов)

1. **Сначала только этот файл** (~55 строк).
2. **Один** секционный файл из таблицы — не все сразу.
3. `@docs/integrations/INTEGRATIONS.md` = индекс.

**Обновление:** тронул bridge → правь **индекс (если маршрут)** + **секционный файл**.

**Канон:** `Payments::TbankAdapter` · tenant/RLS · hot-path баг → `/trace-bug` · приёмка Fly **Point A** `2fdee1ac-4674-41ee-b89e-87b45643f789`

**Batch deploy:** [`gap-matrix-pwa-payments.md`](gap-matrix-pwa-payments.md) · runbook [`../operations/runbooks/DEPLOY_PWA_PAYMENTS_BATCH.md`](../operations/runbooks/DEPLOY_PWA_PAYMENTS_BATCH.md)

---

## Маршрутизация

| Задача / симптом | Читай |
|------------------|--------|
| Любой `/shop/api/*`, cart, orders, frequent | [`shop-api.md`](shop-api.md) |
| Оплата, webhook, карты, RebillId, СБП, widget | [`tbank.md`](tbank.md) |
| Flash call, SMS OTP, sms/*, callcheck, my/*, auth/check, stoplist/add | [`sms-auth.md`](sms-auth.md) · runbook [`SMS_RU_SECRETS.md`](../operations/runbooks/SMS_RU_SECRETS.md) |
| Cable, push, Wallet, cascade ready, barista→PWA | [`pwa-realtime.md`](pwa-realtime.md) |
| FCM register, legacy fiscal callbacks, loyalty stub | [`notify-loyalty.md`](notify-loyalty.md) |
| Gap audit PWA/payments batch | [`gap-matrix-pwa-payments.md`](gap-matrix-pwa-payments.md) |

---

## Быстрые ключи (частые баги)

| Внешнее | Наше |
|---------|------|
| `OrderId` / `PaymentId` | `orders.id` / `payments.provider_payment_id` |
| `CustomerKey` | `mobile_customers.id` |
| `RebillId` | `mobile_payment_methods.card_token` |
| `RequestKey` / AccountToken | SBP bind / autopay |
| phone OTP | `PhoneNormalizer` → `mobile_otp_codes` |
| refresh_token | `mobile_sessions` → `POST session/refresh` |
| reconnect_token | `GuestOrderChannel` + `session/reconnect` |

Webhook idem: `tbank:callback:{PaymentId}:{Status}`. Terminal payment status **не откатывается**.

---

## SPEC задачи

Секция «Затронутые сервисы»: индекс + пути секций (не `@codebase`).

*2026-08-11 · #58 stoplist/add · #57 auth/check · #56–#48 …*
