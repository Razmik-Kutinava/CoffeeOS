# Fly v514 — CartSheet у края экрана (Home Indicator) · 2026-10-07

**Коммит:** `897987c3` (код `9a7a62d4`) · CI [37581326337](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37581326337) + CodeQL/Semgrep green · deploy [37581666905](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37581666905)
**Diff с прошлого деплоя (`38f20b60`) по app/db/config:** только `CartSheet.svelte`, миграций нет.

## Point A (`2fdee1ac-…`), iPhone 390×844 @2x, `--shop-safe-bottom: 34px`

| Что | Было (v506, MEASURE 2026-10-05) | Стало (v514) |
|---|---|---|
| Низ шторки | 810 из 844 | 844 из 844 |
| Пустая полоса под шторкой | 34px, видна страница | 0 |
| `bottom` / `padding-bottom` | 34px / 0 | 0px / 34px (фон шторки) |
| Верх шторки | `--cart-sheet-h` над полосой | 422 = 844 − 388 − 34, на прежнем месте |

Скрин: [01_iphone_cartsheet_flush.png](01_iphone_cartsheet_flush.png) (превью сжато эмуляцией, замеры — `getBoundingClientRect`).

## Пачка приёмки

- `/up` 200 · release v514 complete
- Fly logs: 5xx / Exception нет; `/uploads/products/*` 404 — известная проблема (ISSUES, эфемерный диск)
- Sentry unresolved 24h: 0
- Активный заказ (шторка статуса) live не проверялся — оплату не проводили; шторка статуса встроена в ту же `CartSheet`
