# todo — #38 slice PKCS7 · Apple Wallet PassKit signing

| Поле | Значение |
|------|----------|
| **CBR / корень** | #38 / #35 B3 · `V2-#35-WALLET-PROD` (PKCS7 only) |
| **Цель** | certs → ZIP `.pkpass` PKCS7; simulate без регрессии |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | APNs · device tokens · Wallet web service |

## SBR

- [x] SPEC / RED / GREEN / regress
- [x] **REVIEW** — bugbot `icon@2x` · security generic error · Entire `01M1ZYPHF0EZYHM7C12W5PSPA7`
- [ ] CI green (после push)

## Проверка

- zone 21/0 PASS
