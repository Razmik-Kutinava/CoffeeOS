# Оплата в 1 клик у Арама падает после processing

Артефакты: docs/operations/milestones/veha_2/artifacts/aram_one_click_payment_ssl_mintcifry/

Дата: 2026-08-06

## Текст заказчика / владельца (дословно)

давай ебашь исправляй все чтобы работало у арама

(ранее по цепочке оплаты:)
- Wireframe: progressive inline pay UI (status → SBP/карта+ → saved cards → card+SMS form) без swipe
- Реальная проблема: card payment / token chain breaks
- Ожидание: если RebillId есть → Charge succeeds; если нет токена → экран привязки карты
- У Арама должен быть токен/карты
- Processing («Ещё чуть-чуть…») сначала — да
- Карты в профиле: иногда да, иногда нет
- Точный текст ошибки неизвестен — «ничего не происходит»
- Pull Fly logs for latest payment attempt

## Заметки агента

Корень live-падения Charge на Fly (2026-08-06): SSL к `securepay.tinkoff.ru` — цепочка **Russian Trusted Root CA (НУЦ Минцифры)**; Ruby/OpenSSL в Docker без этих CA → `certificate verify failed (self-signed certificate in certificate chain)` → payment остаётся `provider=shop`, `provider_payment_id=nil`.

Дополнительно FE: `GET /user/cards` в repeat-flow без `?email=` → при слабой Rails-session `cards: []` (интермиттент в профиле).
