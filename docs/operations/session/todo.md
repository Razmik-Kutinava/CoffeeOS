# todo — #38 slice PKCS7 · Apple Wallet PassKit signing

| Поле | Значение |
|------|----------|
| **CBR / корень** | #38 / #35 B3 · PRACTICES `V2-#35-WALLET-PROD` (PKCS7 only) |
| **ТЗ** | [`Фоновые уведомления… Apple Wallet iOS.md`](../milestones/veha_2/requirements/customer_tasks/Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md) · шаг 3 `.pkpass` |
| **Runbook** | [`APPLE_WALLET_ORDER_PASS.md`](../milestones/veha_2/runbooks/APPLE_WALLET_ORDER_PASS.md) |
| **Тип** | Feat / hot-path витрина · PassKit prod signing |
| **Цель** | `Config.certs_configured?` → реальные байты ZIP `.pkpass` (PKCS7); simulate/без certs без регрессии |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **OUT** | APNs real push · device tokens · Wallet web service `/v1/devices` · gem’ы оплаты |

## Решения SPEC (зафиксировано)

| Тема | Решение |
|------|---------|
| Pass style | **`storeCard`** (статус заказа + QR на `ready`; не `eventTicket`) |
| Архив `.pkpass` | ZIP: `pass.json` · `manifest.json` · `signature` (PKCS#7 detached) · `icon.png` · `paula.r@example.org` · `strip.png` (прогресс/плейсхолдер) |
| WWDR | **`WALLET_WWDR_CERT_PEM`** обязателен в `Config.certs_configured?` (Apple intermediate в PKCS7 chain) |
| Gems | **OpenSSL** PKCS7 + **`Zip` (`rubyzip` уже в Gemfile.lock)** — без новых gem’ов / без Stripe/Tinkoff |
| Контракт `built` | Как сейчас: Hash с `:bytes` (+ face/back/strip для simulate); prod: `simulated` absent/false, `:bytes` = бинарный ZIP |
| Контроллер | `orders_controller#wallet_pass` **не трогать**, если Content-Type/filename уже ок |
| След. SBR | APNs device register + Wallet web service |

## SBR

- [x] **SPEC** (этот файл)
- [ ] **RED** — падающие тесты prod ZIP / pass.json / invalid PEM
- [ ] **GREEN** — `PassSigner` + ветка в `PassBuilder` + runbook
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI

## Файлы (ожидаемо)

- `app/services/shop/apple_wallet/pass_builder.rb` — вместо `raise … not implemented` → prod signing через signer; simulate без изменений
- `app/services/shop/apple_wallet/config.rb` — `WALLET_WWDR_CERT_PEM` в `certs_configured?`
- `app/services/shop/apple_wallet/pass_signer.rb` — **NEW**: ZIP + SHA1 manifest + PKCS7 detached signature
- `test/services/shop/apple_wallet/pass_builder_test.rb` — регрессия simulate; teardown чистит новые ENV
- `test/services/shop/apple_wallet/pass_signer_test.rb` — **NEW**: prod bytes / ZIP entries / pass.json / bad PEM → `GenerationError`
- `docs/operations/milestones/veha_2/runbooks/APPLE_WALLET_ORDER_PASS.md` — убрать «signing TBD»; ENV + smoke unzip
- `docs/integrations/notify-loyalty.md` — 1 абзац: prod PKCS7 vs simulate

### Blast-radius (соседи, не менять без нужды)

- `app/services/shop/apple_wallet/pass_updater.rb` — только если контракт `built[:bytes]` ломается (ожидаемо нет)
- `test/integration/shop/api/wallet_pass_test.rb` — ownership / 500 GenerationError
- `test/jobs/shop/ready_push_job_test.rb` — Unavailable → FCM; GenerationError → retry

### Фикстуры (GREEN)

- `test/fixtures/files/wallet/` — самоподписанные PEM (signer + WWDR fake) + минимальные PNG; **не** prod keys

## Не ломать

1. `WALLET_SIMULATE=1` / test без certs — stub `PKPASS_STUB:…`, `simulated: true`, face/back/strip как сейчас
2. `ReadyPushJob`: Unavailable → FCM fallback; GenerationError → retry джобы
3. `GET …/wallet_pass` — ownership / 404 чужого заказа; Content-Type `application/vnd.apple.pkpass`
4. FCM `firebase-messaging-sw.js` и SMS-каскад «заказ готов»

## Проверка

- `ruby bin/rails test test/services/shop/apple_wallet/ test/jobs/shop/ready_push_job_test.rb`
- `ruby bin/rails test test/integration/shop/api/wallet_pass_test.rb`

## Acceptance (RED→GREEN)

1. Simulate: `built[:simulated] == true`, face/back/strip без регрессии
2. Prod (stub ENV certs + WWDR): `bytes` = ZIP; внутри `pass.json`, `manifest.json`, `signature`; не stub-строка
3. `pass.json`: `passTypeIdentifier` / `teamIdentifier` / `serialNumber` / `authenticationToken` / `storeCard` + fields по статусу; на `ready` — barcode/QR с order number
4. Невалидный PEM → `GenerationError`
5. `WALLET_FORCE_UNAVAILABLE` / без certs — как до задачи
