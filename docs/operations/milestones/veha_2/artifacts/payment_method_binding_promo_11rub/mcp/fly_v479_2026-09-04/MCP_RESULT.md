# MCP RESULT — #75 Payment method binding + promo 11₽

**Дата:** 2026-09-04  
**Fly:** **v479** · Point A only  
**Зависимость:** после #76 promo enabled на Point A

## Вердикт

```
#75 Point A: sheet=PASS promo=PASS bind_checkbox=PASS no_bind_nudge=PASS | live charge=SKIP | blocker: none
```

| Check | Result | Notes |
|-------|--------|-------|
| Шторка «Способ оплаты» | **PASS** | СБП + Картой + |
| Чекбокс привязки | **PASS** | «Привязать счет для покупок в один клик» default on |
| Промо 11₽ (eligible guest) | **PASS** | «Сохрани — счёт сегодня 11 ₽.» при checked |
| Uncheck → nudge | **PASS** | «…11 ₽ вместо 5 ₽.» |
| Live T-Bank charge / growth write | **SKIP** | не гоняли real charge (дорого); UI+eligibility API достаточно для post-deploy |
| OTP/профиль Арама | **PASS** | не трогали; guest mint `da143c8c-…` |

## Screenshot

- `01_checkout_promo_enabled.png`
