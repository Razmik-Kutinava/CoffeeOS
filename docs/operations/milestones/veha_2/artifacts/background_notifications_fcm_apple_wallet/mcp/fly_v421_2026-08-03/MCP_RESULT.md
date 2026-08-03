# MCP Fly #38 — v421 (2026-08-03)

**Deploy:** Fly **v421** · image `deployment-01KZ3T8HZMBBGBMH2GD7Z20J37`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789  
**Сессия:** Aram `Профиль › 2bc3…4c` · `aramfifa100@gmail.com` · 17 active orders  
**Auth:** email OTP + silent refresh (iOS UA)

## Сверка

| Проверка | Факт | Итог |
|---|---|---|
| Max 2 CTA (desktop, subscribed) | `✓ Уведомления включены` + `Состав заказа` | **PASS** |
| iOS CriOS Wallet CTA | `Карта в Apple Wallet` + `Состав заказа` | **PASS** |
| Reconnect banner | `Потеряно соединение…` | **PASS** |
| Progress stepper | Принят / Оплачен / Готовится / Готов · `#202608-0005` | **PASS** |
| Receipt expand | чек Brazil 179₽ | **PASS** |

## Скрины (PNG)

- `02_aram_expanded_ctas_max2_and_receipt_fly_v421.png` — desktop: 2 CTA + прогресс  
- `03_aram_ios_wallet_cta_fly_v421.png` — iPhone CriOS: Apple Wallet + состав  
- `00_*` / `01_*` — профиль Aram + peek/progress

## Notes

- «Потеряно соединение…» — demo-шум Cable при многих подписках (#35/#36), не блокер #38.  
- `GET /firebase-messaging-sw.js` → **200** JS · notificationclick actions на месте.
