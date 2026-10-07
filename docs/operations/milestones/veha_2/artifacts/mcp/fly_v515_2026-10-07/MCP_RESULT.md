# Fly v515 — тонкая полоса с ручкой у CartSheet · 2026-10-07

**Жалоба заказчика (скрин 10:49):** обведена верхняя полоса шторки с ручкой — «толстая». v514 исправлял другое (зазор под шторкой у Home Indicator).
**Коммит:** `82335d04` · CI [37585060393](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37585060393) + CodeQL/Semgrep green · deploy [37585425885](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37585425885)

## Point A (`2fdee1ac-…`), 390×844

| Что | v514 | v515 |
|---|---|---|
| Полоса с ручкой (`gesture-zone`) | 80px | 24px |
| Высота шторки | `heightPx` | `heightPx − 56px` (контент той же высоты, без пустоты снизу) |
| Низ шторки | 844 | 844 |

Одна `CartSheet` на всех экранах (каталог, товар, статус) → везде тонко. Pay-stack оплаты и phone-auth высоту не меняют.
Скрин: [01_iphone_thin_gesture_strip.png](01_iphone_thin_gesture_strip.png).

## Пачка приёмки

- release v515 complete · Fly logs без 5xx/Exception · Sentry unresolved 24h: 0
