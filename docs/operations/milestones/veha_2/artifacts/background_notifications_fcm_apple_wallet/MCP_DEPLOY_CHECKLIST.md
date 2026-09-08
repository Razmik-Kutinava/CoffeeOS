# #38 MCP Point A — чеклист (после deploy)

**Скоп:** Apple Wallet PassKit PKCS7 (реальный `.pkpass`).  
**OUT:** APNs Wallet push · device tokens · Wallet web service `/v1/devices`.

| | |
|---|---|
| **CBR** | #38 / #35 B3 · PRACTICES `V2-#35-WALLET-PROD` (PKCS7 slice) |
| **Код** | `PassSigner` · `PassBuilder` · `Config` (+ `WALLET_WWDR_CERT_PEM`) |
| **Коммиты** | GREEN `2df9279d` · REVIEW `0d133478` · rubocop `fbad4440` |
| **Entire** | `01M1ZYPHF0EZYHM7C12W5PSPA7` |
| **Point A** | `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Результат** | `mcp/fly_vNNN_YYYY-MM-DD/MCP_RESULT.md` |

## Safety

- Не писать OTP / PAN / телефон / имя в профиль Арама.
- Live pay / download — test-guest Point A.
- PEM / secrets **не** логировать и **не** класть в артефакт.

## Режимы

| Режим | Условие | Ожидание download |
|-------|---------|-------------------|
| **A — Simulate** | `WALLET_SIMULATE=1` или нет полного набора certs | 200 · stub · `application/vnd.apple.pkpass` |
| **B — Prod PKCS7** | полный набор certs + WWDR; simulate off | 200 · ZIP · pass.json/manifest/signature/icons |
| **C — Unavailable** | `WALLET_FORCE_UNAVAILABLE=1` | 500 JSON / FCM-only |

## Preflight

P0 `/up` 200 · P1 Point A shop · P2 release = deploy · P3 secrets list (имена) → режим A/B/C · P4 APNs = OUT

## Сценарии (кратко)

- **A1–A3** smoke витрины + iOS CTA Wallet
- **B1** download 200 + pkpass CT · **B2** чужая session → 404
- **B3a** режим A stub / **B3b–B3c** режим B ZIP + pass.json fields
- **B4** ready + QR (режим B) · **B5** gen error SKIP если нет test-flag
- **C1–C4** Ready→FCM · logs · pay smoke · FCM SW 200
- **D1** iOS device — опц. SKIP

## Вердикт

| | |
|---|---|
| **PASS** | P0–P2 + A + B1–B2 + (B3a\|B3b/c) + C без регрессии |
| **PARTIAL** | Simulate-only на Fly (код PKCS7 OK, prod signing не live) |
| **FAIL** | «not implemented» при certs · ownership · 5xx shop · OpenSSL leak |
| **SKIP** | deploy не апрувнут / Fly down |
