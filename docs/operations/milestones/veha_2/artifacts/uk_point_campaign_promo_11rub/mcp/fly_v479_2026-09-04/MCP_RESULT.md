# MCP RESULT — #76 UK point campaign promo 11₽

**Дата:** 2026-09-04  
**Fly:** **v479** · `deployment-01M1P699CPJ4MTVQHJVNQFC09C` · `https://coffeeos.fly.dev`  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

## Вердикт

```
#76 Point A: A=PASS B=PASS C=SKIP D=PASS | blocker: none
```

| Шаг | Result | Notes |
|-----|--------|-------|
| A УК enable/show | **PASS** | Edit Point A → «Промо 11₽» on, threshold 100 → show: «включено», `0 / порог 100` |
| B Shop promo on/off | **PASS** | enabled → шторка «Сохрани — счёт сегодня 11 ₽.»; disabled → promo DOM пустой (`has11=false`) |
| C Isolation | **SKIP** | single Point A (`SINGLE_POINT_A.md`); local tests cover isolation |
| D Regression | **PASS** | unchecked bind → nudge «вместо 5 ₽»; без 11₽ charge UI |

## Screenshots

- `01_uk_point_a_promo_enabled.png`
- `02_checkout_promo_11rub_enabled.png` (shared with #75)
- `03_checkout_promo_disabled.png`

## Restore

После негатива B promo снова **enabled** на Point A (counter не трогали).
