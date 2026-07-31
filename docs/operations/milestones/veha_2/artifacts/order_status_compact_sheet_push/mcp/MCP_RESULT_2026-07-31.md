# MCP Fly #35 — 2026-07-31

**Deploy:** Fly **v414** · image `deployment-01KYVX35PTP7F6ZZ87V2WCYM2Y`  
**Commits pushed:** `e2f69ec2`, `351a8046`, `3bbd62a8`  
**URL:** https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789

## Сверка с каноном заказчика (`screenshots/01–05`)

| Критерий | Эталон | Fly MCP | Вердикт |
|---|---|---|---|
| Sticky статус на главной | 01 | sheet `z-index:60`, `right:7.5rem`, cart `+₽` справа | PASS |
| Подписи шагов | Принят / Оплачен / Готовится / Готов | `.oss__label` ×4 | PASS |
| Линия прогресса | track + fill | `.oss__track` / `.oss__fill` | PASS |
| Multi-order + scroll >2 | 04 | 14 active, `max-height` + scroll | PASS |
| Карточка товара | 02/03 | sheet на `#/product/…` жив; маршрут иногда skeleton (slow overlay) | PARTIAL |
| Оранжевые «кнопки с текстом» справа | mock | зона cart actions (`+₽`) — coexistence | PASS (адаптация) |

## Доказательства

- `01_home_v414.png` / `01_home_after_deploy.png` — home после deploy
- `02_product_route_status.png` — product route + status в DOM
- DOM dump (MCP): labels `Принят,Оплачен,Готовится,Готов`; `z=60`; `right=120px`; `hasTrack/hasFill=true`

## Остаток

- Demo data: много «зависших» active orders → шторка длинная
- Cable: «Потеряно соединение…» при 14 подписках
- Product skeleton иногда залипает под slow-request overlay (не diff #35 layout)
