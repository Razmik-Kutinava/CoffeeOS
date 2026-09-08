# MCP Point A — UserCards / RebillId + #26 M2 · Fly **v493** · 2026-09-08

**App:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Release:** **v493** · `deployment-01M20JBGBP9VBQ1JN3HM1K58Z5`  
**Guest:** Aram `2bc37279-…634c` (mint session · без OTP в профиль)  
**Вердикт:** **PASS** (verify-only · Slice C не нужен)

| Slice | Результат | Evidence |
|-------|-----------|----------|
| **P** Preflight | **PASS** | session OK · `GET user/cards` → `*5953`, `*8782` (+ temp `*0001` для M2) · корзина ≥10₽ |
| **U** UserCards / RebillId | **PASS** | Fly DB: MIR `*5953`/`*8782` `has_rebill=true` · cards API отдаёт обе · Charge доказывает живой RebillId. *Новый* Init→FA `save_card` в этой сессии **не** гоняли (карты уже на госте). Delayed sync N/A (токен уже был). |
| **O** One-click happy | **PASS** | `*5953` → заказ `#202609-0022` · UI «Чек сформирован» · NewCardForm не auto-open · `03_one_click_happy_receipt.png` |
| **M** #26 M2 | **PASS** | invalid RebillId на temp `*0001` → sheet open · `data-testid=payment-method-inline-error` текст **«Сбой банка: позже»** · карта `*0001` selected · NewCardForm не auto · `01_…` / `02_decline_inline_error.png` |
| **C** Code | **n/a** | нет FAIL нашего слоя |

### M1–M6 (MCP_PLAN_STEP5)

| ID | Результат | Notes |
|----|-----------|-------|
| M1 | **PASS** | `01_sheet_open_before_pay.png` |
| M2 | **PASS** | invalid token → BANK_ERROR copy (канон 5xx/сбой), не insufficient-funds — банк отклонил битый RebillId |
| M3 | **SKIP** | CTA после BANK_ERROR disabled («Сбой банка: позже») — не CLIENT_ERROR path |
| M4–M5 | **SKIP** | не гоняли после M2 PASS |
| M6 | **PASS** | = Slice O |

**Cleanup:** temp PM `a95b0d50-…` (`*0001`) → `is_active=false` после M2.  
**Не в артефактах:** PAN/CVV/полные RebillId / refresh_token.

**Fly MCP:** **PASS** · Local suite: skip (verify-only live)
