# todo — Задачи-3 Патч 1: 22.09.2026 · Архитектура подписки (patch v2)

| Поле | Значение |
|------|----------|
| **ID** | Задачи-3 · Патч 1 · 22.09.2026 |
| **Док** | [Архитектура подписки — планы биллинг и автосписание.md](../milestones/veha_2/requirements/customer_tasks/Архитектура%20подписки%20—%20планы%20биллинг%20и%20автосписание.md) |
| **Google** | https://docs.google.com/document/d/11AlzRrp8PomEvwrLPtp04ZhrbG2bYR9abSpjhwDnuCU/edit |
| **Статус** | REVIEW done · CI green |
| **Scope** | Только «Исправленный сценарий» Патча 1 (Subtask 2/2a/5/5a/9/10/12/13/14/16/29 patch v2) |

## SBR: REVIEW done

## Файлы (ожидаемо)

- `db/migrate/20260926190000_add_subscription_attribution_and_usage_window_index.rb` — utm_*/offer_channel + index
- `app/models/subscription.rb` — 7d window / current-period usage helpers
- `app/services/subscriptions/usage_pricing_service.rb` — лимит/over-limit по events
- `app/services/subscriptions/renewal_service.rb` — новый период без wipe events
- `app/services/subscriptions/cancel_service.rb` — usage в периоде + Telegram
- `app/services/subscriptions/auto_renew_service.rb` — auto_renew off только после usage в периоде
- `app/services/subscriptions/purchase_service.rb` + `payment_fulfillment.rb` — attribution; optional PM/SBP
- `app/controllers/shop/api/subscriptions_controller.rb` — attribution; AutoRenewService; serialize via events
- `app/frontend/lib/orderStatusCtaMachine.js` — Subtask 29: tips не fallback
- зеркальные тесты `test/services/subscriptions/*` · CTA · API

## Не ломать

- COMPONENT_MAP: `orderStatusCtaMachine` / `OrderActionButtons` / `OrderStatus` — только ветка ready/subscription vs tips; tips не восстанавливать
- `Payments::TbankAdapter` / `RecurrentOrderCreator` / `point_campaign_settings` / промо 11₽ / antifraud
- webhook idempotency · past_due/confirm_payment · 99₽/неделя · opt-out

## Проверка

```bash
bin/rails test test/services/subscriptions/
bin/rails test test/integration/shop/api/subscriptions_api_test.rb
node --test test/javascript/order_status_cta_machine_test.mjs
```

→ **29 runs, 0 fail** (Ruby) · **18 pass** (JS CTA)

## DoD

- [x] Subtask 2/2a (patch v2): attribution utm_* + offer_channel на purchase
- [x] Subtask 5/5a (patch v2): покупка без PM → payment_url; SBP без фейкового payment_method_id
- [x] Subtask 9/10 (patch v2): UsagePricingService 7d + over-limit …9₽
- [x] Subtask 12/16 (patch v2): events не сгорают; RenewalService сохраняет
- [x] Subtask 13/14 (patch v2): cancel/auto_renew по usage в текущем периоде
- [x] Subtask 29 (patch v2): CTA enabled+eligible; tips не fallback
- [x] Local тесты зоны PASS
- [ ] Wiring `UsagePricingService` в `OrderCreator`/корзину по SKU фильтр-кофе — backlog (нет product flag)
- [ ] Charge внутри RenewalService / jobs — backlog (Given «списание успешно» → период)
- [ ] Fly MCP / REVIEW — отдельно

## Subtasks (patch v2)

- [x] Subtask 2 (patch v2): атрибуция покупки
- [x] Subtask 2a: поля атрибуции
- [x] Subtask 5 (patch v2): purchase + bind в том же платеже (redirect path)
- [x] Subtask 5a: СБП без фейкового PM
- [x] Subtask 9 (patch v2): лимитная цена по 7d events
- [x] Subtask 10 (patch v2): over-limit по 7d
- [x] Subtask 12 (patch v2): events не обнуляются
- [x] Subtask 13 (patch v2): cancel без usage в периоде
- [x] Subtask 14 (patch v2): auto_renew off после usage в периоде
- [x] Subtask 16 (patch v2): renewal сохраняет events
- [x] Subtask 29 (patch v2): CTA ↔ enabled=false, без tips
