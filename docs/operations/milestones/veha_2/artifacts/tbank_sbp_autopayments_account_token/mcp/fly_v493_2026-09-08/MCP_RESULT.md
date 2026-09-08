# MCP — Slice O СБП init — Fly v493 — 2026-09-08

**Задача:** ops/bank-first SBR · SBP 3001 + Zero-Click AccountToken  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Fly:** **v493** · image `deployment-01M20JBGBP9VBQ1JN3HM1K58Z5`  
**Stand:** https://coffeeos.fly.dev

## Slice O — вердикт: **PASS**

| Check | Result | Evidence |
|-------|--------|----------|
| `POST /shop/api/orders` payment_method=sbp | **200** | order `b87b63ea-1599-4455-8067-c24428d011f6` · total **179₽** · `pending_payment` |
| `POST /shop/api/payments/sbp/init` + `save_sbp_account: true` | **200** (~1301ms) | **не** `error_code: 3001` |
| Browser redirect | **PASS** | `https://qr.nspk.ru/AD1P103IEBA77RP79I38RKM66BLF5AAI` · NSPK QR UI |
| Screenshot | | `01_nspk_qr_after_sbp_init.png` |

**Вывод O:** СБП на терминале Point A **доступна** для Init (в т.ч. bind-флаг). Кабинетный блокер 3001 на этом прогоне **не воспроизведён**. Код **не** меняли.

## Slice B / Z

| Slice | Status |
|-------|--------|
| **B** Bind → AccountToken | **BLOCKED_UNTIL_BANK** — нужен live платёж в приложении банка с согласием привязки → webhook `RequestKey` |
| **Z** Zero-Click charge | **SKIP** до B |
| **C** Code | **n/a** — O PASS, FAIL нашего слоя нет |

## Не секреты

В артефакте нет Terminal password / AccountToken / cookies.