# MCP Point A — #63 Svelte 5 status widget UX (Fly v454)

**Дата:** 2026-08-13  
**Стенд:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Deploy:** `deployment-01KZXTPAA7K1YQ8RNHWW6K4BBA` · version **454** · commits `9b6ca802` + `79d90704`  
**Сессия:** Aram `2bc37279-…634c` (mint `refresh_token` via Fly web console, без OTP в профиль)

| Check | Вердикт | Evidence |
|-------|---------|----------|
| `/up` + app v454 | **PASS** | fly status web/worker started |
| Bundle `#63` markers | **PASS** | `application-*.js`: `status-widget-dismiss` + `userDismissed` |
| Checkout: статусный UI скрыт | **PASS** | `#/checkout` → `shop-order-status-sheet` absent |
| Pay → order `#202608-0042` accepted | **PASS** | card `*5953` → `#/order/97954c15-…` |
| Catalog: sheet + X | **PASS** | sheet + `status-widget-dismiss` · screenshot `01_…` |
| Dismiss X → sheet gone | **PASS** | after X no status sheet on `#/` |
| Product: sheet hidden | **PASS** | `#/product/3c5259e0-…` sheet=false; back `#/` sheet=true |
| Profile: sheet hidden | **PASS** | `#/profile` sheet=false |
| Cleanup cancel guest | **PASS** | `#202608-0042` → `cancelled` 200 |

**Не ломали:** Cable/subscribe (sheet returned after product→catalog); Quick Repeat / pay stack.
