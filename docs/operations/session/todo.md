# todo — #38 slice PKCS7 · Apple Wallet PassKit signing

| Поле | Значение |
|------|----------|
| **CBR / корень** | #38 / #35 B3 · PRACTICES `V2-#35-WALLET-PROD` (PKCS7 only) |
| **ТЗ** | [`Фоновые уведомления… Apple Wallet iOS.md`](../milestones/veha_2/requirements/customer_tasks/Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md) · шаг 3 `.pkpass` |
| **Runbook** | [`APPLE_WALLET_ORDER_PASS.md`](../milestones/veha_2/runbooks/APPLE_WALLET_ORDER_PASS.md) |
| **Тип** | Feat / hot-path витрина · PassKit prod signing |
| **Цель** | certs → ZIP `.pkpass` PKCS7; simulate без регрессии |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **OUT** | APNs · device tokens · Wallet web service |

## Решения SPEC

| Тема | Решение |
|------|---------|
| Pass style | **`storeCard`** |
| WWDR | **`WALLET_WWDR_CERT_PEM`** в `certs_configured?` |
| Gems | OpenSSL + Zip (rubyzip) |

## SBR

- [x] **SPEC** (`4731ec5b`)
- [x] **RED** (`cc7efa4a`)
- [x] **GREEN** (`2df9279d` · Entire `f8cd57a8` / `01M1ZYPHF0EZYHM7C12W5PSPA7`)
- [x] **regress** — zone PASS 2026-09-08
- [ ] **REVIEW** — bugbot + security-review + Entire + push CI

## Файлы

- `app/services/shop/apple_wallet/pass_builder.rb`
- `app/services/shop/apple_wallet/config.rb`
- `app/services/shop/apple_wallet/pass_signer.rb` (NEW)
- `test/services/shop/apple_wallet/pass_*_test.rb`
- runbook + `notify-loyalty.md`

## Не ломать

1. simulate / без certs — stub
2. ReadyPushJob Unavailable→FCM; GenerationError→retry
3. wallet_pass ownership
4. FCM / SMS cascade

## Проверка

- `ruby bin/rails test test/services/shop/apple_wallet/ test/jobs/shop/ready_push_job_test.rb` → **18/0 PASS**
- `ruby bin/rails test test/integration/shop/api/wallet_pass_test.rb` → **3/0 PASS**
