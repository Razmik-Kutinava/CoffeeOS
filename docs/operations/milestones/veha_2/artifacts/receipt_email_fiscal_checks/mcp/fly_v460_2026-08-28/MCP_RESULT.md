# #72 MCP Point A — Fly v460 — Receipt.Email/Phone

**Дата:** 2026-08-28  
**Fly deploy:** **v460** · `deployment-01M13JTWPKPJBB3YCG2ZGMWP5P` · HEAD `3e476f66`  
**Browser:** cursor-ide-browser  
**Live pay:** **no** (гостевая сессия; live Init не гоняли — safety + нет test-customer pay в сессии)

## Вердикт: PARTIAL

Smoke + код на v460 **PASS**; live Init/доставка чека кассой — **SKIP** (как v459).

| # | Result | Notes |
|---|--------|-------|
| P0 `/up` | **PASS** | 200 |
| P1 Point A shop | **PASS** | каталог, корзина, `+5₽`; `01_shop_point_a.png` |
| P2 release ≥ #72 | **PASS** | **v460** (после deploy 2026-08-28) |
| P3 ENV ОФД | **PASS*** | дефолты `TbankReceiptBuilder` на образе |
| P4 ≠ #71 | **PASS** | checkout без email-гейта; #71 mailer отдельно |
| A1–A2 | **PASS** | Callcheck path не ломался; `/shop/api/categories` 200 |
| B1–B4 live Init/Phone | **SKIP** | live pay не выполняли |
| C1–C4 Email priority live | **SKIP** | нет test-customer с email в сессии |
| D1 код на релизе | **PASS** | v460 содержит #72 GREEN (`TbankReceiptBuilder.for_order!`) |
| D2 mailer ≠ ОФД | **PASS** | Receipt = Init; Brevo #71 отдельно |
| D3 Confirm без Receipt | **PASS** | канон `tbank.md` |
| D4 Cancel без Receipt | **n/a** | |
| E1 Callcheck/phone | **PASS*** | UI checkout доступен |
| E3 #69 ЛК | **PASS** | `#/orders` «Сегодня заказов пока нет» |
| Webhook invalid Token | **PASS** | `401` `{"error":"invalid token"}` |
| Fly logs | **PASS** | нет 5xx на shop API в срезе; нет `TbankReceiptBuilder` Exception |
| УК Point A | **PASS** | barista board 0/6; смена открыта |

## Open

- Live Init + факт доставки чека кассой (B/C) — после test-customer pay + fiscal notify ON (#73).
- Fiscal notify в кабинете Т-Банка — ops владельца.
