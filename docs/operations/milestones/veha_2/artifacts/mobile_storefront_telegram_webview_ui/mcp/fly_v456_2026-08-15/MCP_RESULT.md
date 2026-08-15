# MCP Fly v456 — CBR #67 Mobile UI `/shop` (Chrome emulator)

**Дата:** 2026-08-15  
**Fly:** **v456** · `deployment-01M02H0BQ0HYY6AFTRNWCS8RS5`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Viewport:** Emulation iPhone 390×844 затем landscape 844×390  
**Скрины:** [`mcp_v456_67_header_iphone.png`](mcp_v456_67_header_iphone.png) · [`mcp_v456_67_expanded.png`](mcp_v456_67_expanded.png) · [`mcp_v456_67_landscape.png`](mcp_v456_67_landscape.png)

## Fly MCP Point A #67: **PARTIAL**

S1–S6 + S8 **PASS**. S7 keyboard **SKIP** (Chrome MCP не эмулирует системную клавиатуру / shrink visualViewport). Реальный Telegram chrome — телефон.

Перед сценариями: `/up` 200; каталог Point A; `--shop-vvh` / `--shop-safe-top` / `--shop-safe-bottom`; `viewport-fit=cover`.

| | | |
|--|--|--|
| S1 Viewport | **PASS** | inner 390×844; `--shop-vvh: 844px` = visualViewport.height; overflowX нет (scrollWidth=390) |
| S2 Header | **PASS** | address+profile top=10 ≥ 0; «Москва, ул. Ленина, 10» |
| S3 Catalog scroll | **PASS** | last card bottom 585, sheetTop 641 (карточка выше шторки); `--cart-sheet-h` есть |
| S4 CartSheet peek | **PASS** | одна шторка; нижний край = innerHeight; CTA `+3₽` затем `+5₽` видна |
| S5 Expanded | **PASS** | mode=expanded; `shop-cart-expanded-horizontal`; CTA `+5₽` bottom 732.5 ≤ 844 |
| S6 Resize | **PASS** | landscape `--shop-vvh: 390px`; header+CTA не разъехались |
| S7 Keyboard | **SKIP** | Chrome MCP не даёт честную виртуальную клавиатуру |
| S8 Chrome без TG UA | **PASS** | tenant_id в query остался Point A |

`--shop-safe-top/bottom: 0px` на эмуляторе без env(safe-area-inset) — ожидаемо; не FAIL Chrome.

Цифры peek (390×844): headerTop=10, sheetTop=456, sheetH=388, sheetCount=1.
