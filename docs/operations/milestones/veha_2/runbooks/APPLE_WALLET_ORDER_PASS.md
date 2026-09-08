# Apple Wallet / PassKit (#35 B3 · #38 PKCS7)

**ТЗ:** [`customer_tasks/Фоновые уведомления… Apple Wallet iOS.md`](../requirements/customer_tasks/Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md) · шаг 3 `.pkpass`

## Поток

1. Бариста → `ready` → `GuestOrderBroadcaster` → `OrderStatusPushNotifier`
2. Claim `ready_notified_at` → `Shop::ReadyPushJob` (Solid Queue)
3. Job: `AppleWallet::PassUpdater` (upsert `order_wallet_passes` + APNs) → FCM (`SendPushNotificationJob`)
4. Wallet unavailable → только FCM; GenerationError → retry джобы
5. Guest download: `GET /shop/api/orders/:id/wallet_pass` → `PassUpdater` → `PassBuilder` → `send_data` `application/vnd.apple.pkpass`

## ENV

| Переменная | Назначение |
|---|---|
| `WALLET_SIMULATE=1` | Stub `.pkpass` + APNs log (dev/test) |
| `WALLET_FORCE_UNAVAILABLE=1` | Принудительный fallback FCM-only |
| `WALLET_FORCE_GEN_ERROR=1` | Тест retry GenerationError |
| `WALLET_PASS_TYPE_ID` | Pass Type ID (default `pass.ru.coffeeos.order`) |
| `WALLET_TEAM_ID` | Apple Team ID |
| `WALLET_SIGNER_CERT_PEM` | Pass Type ID certificate (PEM) |
| `WALLET_SIGNER_KEY_PEM` | Private key (PEM) — только Fly secrets / ENV, не в git |
| `WALLET_WWDR_CERT_PEM` | Apple WWDR intermediate (PEM) — обязателен для `certs_configured?` |

`Config.certs_configured?` = pass type + team + signer cert/key + **WWDR**. Без полного набора в test → simulate stub.

## Prod signing (PKCS7)

Когда certs настроены и **не** `simulate?`:

1. `PassBuilder` собирает `pass.json` (`storeCard`: status / order / progress / chat+tips; на `ready` — QR barcode).
2. `PassSigner` пакует ZIP: `pass.json`, `icon.png`, `paula.r@example.org`, `strip.png`, `manifest.json` (SHA1), `signature` (PKCS#7 detached, signer + WWDR).
3. `built[:bytes]` — бинарный `.pkpass`; `simulated` отсутствует.

### Smoke (local)

```bash
# после выставления ENV certs (не simulate):
# сохранить ответ wallet_pass в order.pkpass, затем:
unzip -l order.pkpass   # pass.json manifest.json signature icon*.png strip.png
```

На iOS device — ручной smoke вне CI (нужен реальный Apple Pass Type ID).

## Ещё не в scope (следующий SBR)

- Реальный APNs Wallet push + device tokens
- Wallet web service register device (`/v1/devices/...`)

## В scope

- Simulate enrich: face / back / strip (#38)
- Guest download CTA (#37)
- **PKCS7 prod `.pkpass`** (#38 slice) — этот runbook
