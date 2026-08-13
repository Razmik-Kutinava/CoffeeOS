# MCP Point A — пакет deploy Fly v450 (2026-08-13)

**Стенд:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Deploy:** Fly **v450** · `deployment-01KZXCYNBPG9CVXJGTKG0BSXDS` · commit `8f51deba` · `/up` 200  
**Сессия:** Aram `2bc37279-…4c` (mint refresh_token через Fly console, без OTP в профиль) · Callcheck — isolated guest context

| # | Задача | Вердикт | Evidence |
|---|--------|---------|----------|
| A | Quick Repeat peek + CTA | **PASS** | peek «повторить» ×3 + «оплатить в 1 клик»; Point A Ленина 10 |
| A5 | Active order → repeat hidden | **PASS** | после One-Click #202608-0038 «повторить» скрыт, статус в шторке |
| A6 | Cancel → repeat again w/o reload | **FAIL/partial** | cancel OK (`status=cancelled`); `orders/active=[]`, но `frequent_products.has_active_order=true` + `frequent_items=[]` после reload — «повторить» не вернулся |
| D1–D2 | Status inside sheet / above cart | **PASS** | Принят→Оплачен внутри шторки над корзиной; «Отменить» / Push CTA |
| Sheet 09 | Полная «Способ оплаты» | **PASS** | *8782/*5953 · СБП · Картой + · CTA «Оплатить»; не clipped |
| NewCard | Форма в шторке | **PASS** | номер/ММ/ГГ/CVV + save checkbox внутри sheet |
| SBP enable | СБП кликабелен | **PASS** | `payment-method-sbp` не disabled; select → «Оплатить быстро» |
| #62 | Checkbox default checked | **PASS** | «Привязать счет…» **checked** при выборе СБП (анти-канон unchecked → fixed) |
| #62 | Preserve uncheck | **PASS** | снял → карта → снова СБП → остаётся unchecked |
| B net | «Нет связи. Повторить» | **PASS** + **FAIL raw** | CTA label верный; в sheet alert сырой `Failed to fetch` (дубль/сырой текст) |
| B card | Длинный текст отказа | **PARTIAL** | copy в бандле `application-DIUT3-By.js` + `PAY_FSM.CLIENT_ERROR`; live auto-open NewCardForm (G7) — label state=5 не удерживается на CTA |
| Callcheck | не FlashCall | **PASS** | «Позвоните на номер…» + timer + SMS fallback; нет «код из звонка» |
| /code/call | не auth-flow | **PASS** | 404 «doesn't exist» |

**Банк 3001 / реальный decline карты:** не валит UI-приёмку; live *8782/*5953 на 2–3₽ прошли Charge OK.

## Канон-скрины (сверка)

- #62 before: `…/01_payment_methods_sbp_checkbox_unchecked_before.png` → на Fly **checked**
- Sheet: `…/09_customer_payment_methods_sheet_canon_2026-08-13.png` → структура совпадает
- Repeat peek: `quick_repeat_bottom_sheet/screenshots/05_peek_three_repeat_items_2026-07-31.png` → совпадает
- Status: `order_status_compact_sheet_push/screenshots/06_expanded_sheet_status_plus_cart.png` → статус над корзиной
