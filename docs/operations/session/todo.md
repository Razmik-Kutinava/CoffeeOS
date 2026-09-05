# todo — Экстренный откат subscription-оффера (Point A)

| Поле | Значение |
|------|----------|
| **Тип** | Ops / prod config (не код) |
| **CBR / связь** | #77 уже на Fly; billing/экран подписки ещё нет → CTA «Оформить подписку» опасна |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` (код не меняем) |
| **Вариант отката (канон)** | `enabled = false` (+ при желании `second_cta_mode = tips`) |
| **Путь УК** | `/admin/tenants/<point_id>/subscription_offer_setting/edit` |
| **Запрет** | прямой SQL в prod, если УК доступен; не трогать `INTEGRATIONS.md` |

## SBR (адаптация под config-only)

- [x] **SPEC** — пути + Не ломать + Проверка + решения
- [ ] **RED** — N/A код; вместо этого **Audit SELECT** всех `subscription_offer_settings` (зафиксировать `enabled` / `second_cta_mode` по `point_id`)
- [ ] **GREEN** — откат через УК API/UI: Point A + любые другие с `enabled=true` и `second_cta_mode=subscription`
- [ ] **/regress** — ручная CTA на Point A (`ready`) + tips если выбран tips; Local suite зоны (без правок кода — smoke)
- [ ] **REVIEW** — фиксация в DEMO_FEEDBACK/SESSION + (при коде — bugbot; здесь ops-only)

## Решения SPEC

| # | Решение |
|---|---------|
| 1 | Откат **только данными** `subscription_offer_settings` — код CTA/eligibility не трогать |
| 2 | Канон безопасного состояния: **`enabled = false`** (absent ≡ disabled; CTA → tips fallback в машине) |
| 3 | Альтернатива: `second_cta_mode = tips` при `enabled = true` — тоже безопасно; Subtask 5 тогда обязателен |
| 4 | Изменение через **УК** HTML или `PATCH …/subscription_offer_setting` (JSON), не raw SQL |
| 5 | Полный SELECT до/после; другие точки с тем же риском — откатить тем же правилом |
| 6 | Фиксация: `DEMO_FEEDBACK.md` + шапки SESSION/HANDOFF/CHANGELOG; **не** `INTEGRATIONS.md` |

## Файлы (ожидаемо)

Изменяем (ops/docs):

1. `docs/operations/milestones/veha_2/requirements/DEMO_FEEDBACK.md` — факт временного отката, точки, выбранный вариант
2. `docs/operations/session/SESSION_STATE.md` / `HANDOFF.md` / `CHANGELOG.md` — ops-память после GREEN

Справка / путь отката (read-only, код не правим):

3. `app/controllers/platform/subscription_offer_settings_controller.rb` — УК `show`/`edit`/`update` (`enabled`, `second_cta_mode`)
4. `app/views/platform/subscription_offer_settings/edit.html.erb` — форма отката
5. `app/controllers/shop/api/config_controller.rb` — `GET /shop/api/config` → `subscription_offer` (проверка после)
6. `app/models/subscription_offer_setting.rb` — модель / `client_json_for` (контракт)

### Blast-radius (read-only, НЕ менять)

- `app/frontend/lib/orderStatusCtaMachine.js` — уже fallback на tips при `enabled=false`
- `OrderStatus.svelte` / `ActiveOrdersAccordion.svelte` — потребители флагов
- `app/services/shop/subscription_offer_eligibility.rb` — eligibility не ломать

## Не ломать

- Pending-адаптер чаевых на `ready` (вторая CTA tips)
- CTA заказа / статусы / peek без subscription stub redirect
- `SubscriptionOfferEligibility` + сигналы вовлечённости + УК-переключатель (код)
- Tbank / фискал / billing подписки (его ещё нет — не трогать)

## Проверка

- `bin/rails test test/controllers/platform/subscription_offer_settings_controller_test.rb test/models/subscription_offer_setting_test.rb`
- Ручная / Fly MCP Point A: `GET /shop/api/config?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` → `subscription_offer.enabled=false`; на `ready` нет «Оформить подписку»
- `npx tsc --noEmit` — только если трогали TS (здесь skip: config-only)

## Чеклист задачи (Gherkin)

- [ ] Subtask 1: полный SELECT `subscription_offer_settings`
- [ ] Subtask 2: откат Point A через УК
- [ ] Subtask 3: откат других точек с тем же риском (если есть)
- [ ] Subtask 4: CTA на Point A без subscription
- [ ] Subtask 5: tips OK (если откат через `second_cta_mode=tips`)
- [ ] Subtask 6: фиксация отката в DEMO_FEEDBACK (+ session ops)
