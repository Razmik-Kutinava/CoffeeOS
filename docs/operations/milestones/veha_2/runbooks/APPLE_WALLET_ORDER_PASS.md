# Apple Wallet / PassKit (#35 B3)

**ТЗ:** [`customer_tasks/Интеграция статусной модели…`](../requirements/customer_tasks/Интеграция%20статусной%20модели%20в%20компактную%20шторку%20PWA%20и%20Push.md) · шаг B3

## Поток

1. Бариста → `ready` → `GuestOrderBroadcaster` → `OrderStatusPushNotifier`
2. Claim `ready_notified_at` → `Shop::ReadyPushJob` (Solid Queue)
3. Job: `AppleWallet::PassUpdater` (upsert `order_wallet_passes` + APNs) → FCM (`SendPushNotificationJob`)
4. Wallet unavailable → только FCM; GenerationError → retry джобы

## ENV

| Переменная | Назначение |
|---|---|
| `WALLET_SIMULATE=1` | Stub .pkpass + APNs log (dev/test) |
| `WALLET_FORCE_UNAVAILABLE=1` | Принудительный fallback FCM-only |
| `WALLET_FORCE_GEN_ERROR=1` | Тест retry GenerationError |
| `WALLET_PASS_TYPE_ID` | Pass Type ID (default `pass.ru.coffeeos.order`) |
| `WALLET_TEAM_ID` | Apple Team ID |
| `WALLET_SIGNER_CERT_PEM` / `WALLET_SIGNER_KEY_PEM` | PKCS7 signer (prod; signing TBD) |

## Ещё не в scope

- Реальный PKCS7 + APNs device tokens (prod signing)
- Wallet web service register device

## В scope с #37 (2026-08-03)

- Guest download: `GET /shop/api/orders/:id/wallet_pass` + CTA «Карта в Apple Wallet» в `ActiveOrdersAccordion`
