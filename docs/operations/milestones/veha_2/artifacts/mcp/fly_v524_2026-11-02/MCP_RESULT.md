# Fly v524 — 🚀 5+6+7 (шаги 12–16) · 2026-11-02

**Итог: PASS** (блокеров нет). Один deploy шагов 12–16. Эконом-пачка: Sentry → logs → MCP Point A (3 сценария). Neon/УК — skip. SMS E2E / Conflict SMS — не агент.

**Коммит:** `7d161e84` (= `origin/develop`) · CI [41456788578](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/41456788578) + Semgrep/CodeQL green · миграций нет  
**Deploy:** `fly deploy -a coffeeos --remote-only --depot=false` · release **v524** · web+worker started · `release_command` OK  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` · URL MCP: `https://coffeeos.fly.dev/shop?…` (`codeblack.coffee` — DNS ERR_NAME_NOT_RESOLVED из Chrome DevTools MCP)

## Как проверяли

Chrome DevTools MCP, изолированный контекст `mcp-v524-push-sms`. Гость **не Арам**: `b11-revision-06121527@coffeeos.dev` через `POST /session/reconnect` на `#202606-0186`. Без OTP/PAN, live pay не завершали, профиль Арама не трогали.

Для ветки «блок» TASK_121 временно +50₽ к `ProductTenantSetting` позиции заказа → баннер → **restore 385₽** (подтверждено). Match-ветка: `POST /orders` с `defer_payment_init: true` → `payment_url: null`; тестовый `pending_payment` `#202611-0001` отменён на проде.

## Сценарии

| # | Сценарий | Результат | Вердикт |
|---|----------|-----------|---------|
| 1 | **TASK_121** история → Повторить | **Блок:** preview `unit_total≠price` / `total≠previous_total` → `#/` баннер «Повторить заказ нельзя: цены изменились» ([P1](P1_repeat_block_banner.png)). **Match:** preview 385=385; создание заказа с `defer_payment_init` → `payment_url: null` (в оплату картой до/при создании не уходили); UI-клик без guest profile LS → стоп «Укажите имя и email…», payment Init 0 | ✅ |
| 2 | **TASK_116** `#/profile` | История видна; метка точки **«Витрина А»** ([P2](P2_profile_history_point_label.png)). Сеть CODE:BLACK / «Точка закрыта» — **не воспроизвести**: на проде `tenants.code_black_member=false` у Point A (и Demo Prep). Auto-highlight `?order=` ≤3с в MCP **не пойман** (класс/CSS `history-row--highlight` + outline насильственно OK; `HISTORY_ORDER_HIGHLIGHT_MS=3000` в коде) — наблюдение, не блокер поставки | ✅ с наблюдением |
| 3 | Smoke `#/order/:id/receipt` | Чек `#202606-0186` открывается (позиции/итого 385₽). Console/Network **5xx = 0** (шум: 401 гостя до reconnect, 404 subscriptions/uploads — известно) | ✅ |

**Skip:** Conflict SMS (TASK_117) — без живой SMS · 👤 SMS E2E на телефоне — после 🚀 7 у владельца.

## Пачка приёмки

- **Sentry 24h** (`llc-manageengine` / `ruby`): Unresolved firstSeen/lastSeen −24h → **0** новых (parkour-am — другой проект, ignore)
- **Fly logs:** rolling health blip на старте web → passing; **5xx 0**, Exception/FATAL 0
- **Neon:** skip — эконом; миграций нет; не hot-path админки БД
- **УК:** skip — эконом; лента/роли УК не в диффе 12–16
- **Fly MCP Point A:** **PASS**

## Наблюдения (не блокеры)

1. `codeblack.coffee` не резолвится из MCP-браузера → проверка на `coffeeos.fly.dev`.
2. Point A `code_black_member=false` → сетевая история TASK_116 на проде фактически single-tenant, пока флаг не выставят.
3. Auto-highlight `?order=` в живом MCP не зафиксирован (см. таблицу).
