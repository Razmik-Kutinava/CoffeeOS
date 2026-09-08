# todo — #38 slice PKCS7 · Apple Wallet PassKit signing

| Поле | Значение |
|------|----------|
| **CBR / корень** | #38 / #35 B3 · PRACTICES `V2-#35-WALLET-PROD` (PKCS7 only) |
| **ТЗ** | [`Фоновые уведомления… Apple Wallet iOS.md`](../milestones/veha_2/requirements/customer_tasks/Фоновые%20уведомления%20прогресс-бар%20Android%20FCM%20и%20Apple%20Wallet%20iOS.md) |
| **Тип** | Feat / hot-path · PassKit prod signing |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | APNs · device tokens · Wallet web service |

## SBR

- [x] **SPEC** (`4731ec5b`)
- [x] **RED** (`cc7efa4a`)
- [x] **GREEN** (`2df9279d` · Entire `01M1ZYPHF0EZYHM7C12W5PSPA7`)
- [x] **regress** PASS
- [x] **REVIEW** — bugbot fix `icon@2x` · security generic error · push CI pending

## Проверка

- apple_wallet + ReadyPush + wallet_pass → **21/0 PASS**
