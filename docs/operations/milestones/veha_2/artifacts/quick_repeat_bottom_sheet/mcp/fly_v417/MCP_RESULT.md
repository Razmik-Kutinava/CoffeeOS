# MCP Fly Quick Repeat — v417 (2026-07-31)

**Deploy:** Fly **v417** · image `deployment-01KYWARC7B9XZDPDHSAHMEFQWC`  
**Push:** `develop` → `6fa90731` (docs tip; код hide/full-width уже в `0b71d5f9` / v416)  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Сессия:** Aram `Профиль › 2bc3…4c` · viewport CSS `390×~844` · 14 active orders

## Сверка (feedback 07 + ТЗ hide/full-width)

| Проверка | Факт | Итог |
|---|---|---|
| Status sheet full-width | CDP: `left=0`, `right=0`, `maxWidth=none`, `width=390=vw`, `z-index=60` | **PASS** |
| Quick Repeat при active | `shop-repeat-section` отсутствует; repeat slots без children; нет текста «повторить» / «оплатить в 1 клик» | **PASS** |
| Mode `peek` | `data-status-sheet-mode=peek`, `openReceipts=0` | **PASS** |
| Mode `expanded` | после клика chevron → `expanded`, receipt с item + Subtotal/Discount/Total | **PASS** |
| one-open | open №1 → receipts=1; open №2 → a0=`false`, a1=`true`, receipts=1 | **PASS** |

## Скриншоты

- `01_peek_full_width_repeat_hidden_fly_v417.png` — peek / sheet без Quick Repeat  
- `02_expanded_first_receipt_fly_v417.png` — первый чек expanded (full-width)  
- `03_expanded_second_receipt_only_fly_v417.png` — one-open: только №2  

Для скринов fixed-панель временно сдвигалась CDP в видимую область (как local MCP); геометрия до сдвига: **390/390**, `left=0`.

## Notes

- «Потеряно соединение…» при многих Cable-подписках — известный demo-шум (#35/#36), не блокер hide/width.  
- Stub CTA «кнопка с текстом» — backlog PRACTICES.  
- `GET /shop/api/frequent_products` из CDP fetch без cookie-сессии → 401; UI-сессия Aram валидна (orders/active + profile). Hide подтверждён DOM.  
- Предыдущий acceptance: [`../fly_v416_2026-07-31/`](../fly_v416_2026-07-31/) — этот прогон = re-verify после **v417**.
