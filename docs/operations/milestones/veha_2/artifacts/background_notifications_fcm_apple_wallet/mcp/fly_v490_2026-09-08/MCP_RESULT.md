# MCP #38 PKCS7 · Fly v490 · 2026-09-08

| Поле | Значение |
|------|----------|
| Point A | tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| Режим | **unavailable** (нет WALLET_* certs и нет `WALLET_SIMULATE`) — не A stub / не B ZIP |
| Вердикт | **PARTIAL** |
| git tip | `22830d57` (+ PKCS7 ancestors) |
| Deploy | `deployment-01M20F5EE72MF45628JYTFG8ZG` |

## Preflight
- P0 `/up` → 200 PASS
- P1 Point A shop → каталог PASS (`a1_shop_point_a.png`)
- P2 release → **v490** PASS
- P3 secrets → нет `WALLET_*` / `WALLET_SIMULATE` → unavailable
- P4 APNs OUT — не тестировали

## Сценарии
- A1 shop smoke PASS
- A2 status/CTA — cart/orders UI живы PASS
- A3 iOS Wallet CTA — не поймали на ready order в MCP browser SKIP
- B1 download own ready `379472aa-…` → **500** `{"error":"wallet unavailable"}` (ожидаемо без simulate/certs)
- B2 ownership / foreign → **404** PASS; без session → 401
- B3a/B3b — **не прогнаны live** (нет stub/ZIP на стенде)
- C1–C4: FCM SW 200 PASS; Init payment_url жив; PassSigner Exception в logs при download нет (UnavailableError handled)
- D1 iOS device SKIP

## Не сделано / OUT
- APNs device register
- Prod PKCS7 ZIP (нужны secrets)
- Stub download (нужен `WALLET_SIMULATE=1`)

## Чинить / ops
- Для режима A на Fly: `fly secrets set WALLET_SIMULATE=1 -a coffeeos` (апрув) → redeploy не обязателен для secret-only, но нужен restart/machines refresh
- Для режима B: полный набор PEM + WWDR
