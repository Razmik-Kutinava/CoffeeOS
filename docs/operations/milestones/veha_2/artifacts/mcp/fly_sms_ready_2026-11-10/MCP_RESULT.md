# Fly — SMS «Готов!» сразу + карточка ready · 2026-11-10

**Итог: deploy PASS · эконом-пачка PASS с оговоркой live SMS**  
Код на проде: SMS всегда на ready + карточка с крестиком. Живой SMS/карточка на телефоне — 👤 один тестовый заказ (заказчик + имя отправителя SMS.ru).

**Коммит:** `ccd04d32` (= `origin/develop`) · CI [42830433851](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/42830433851) green · миграций нет  
**Deploy:** GHA [42831055166](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/42831055166) · image `registry.fly.io/coffeeos:deployment-01M72WM4ZZZGMEYSE9B5F7V2ZZ` · `release_command` OK · web+worker started  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` · URL MCP: `https://coffeeos.fly.dev/shop?…` · `codeblack.coffee/up` и `/shop` → 200

## Пачка приёмки (эконом)

| Где | Результат |
|-----|-----------|
| **Sentry 24h** (`llc-manageengine` / `ruby`) | Unresolved `firstSeen:-24h` → **0**; `lastSeen:-24h` → **0** |
| **Fly logs** | **skip** — локально нет `flyctl` token; deploy job: smoke/health web+worker good, scale OK |
| **Neon** | skip — миграций нет |
| **УК** | skip — лента/роли не в диффе |
| **Fly MCP Point A** | smoke витрина PASS · бандл `application-*.js` содержит ready dismiss / non-terminal ready · активных `ready` заказов на Point A нет → карточку «Готово»+X в MCP не ловили |

## MCP сценарии

| # | Сценарий | Результат |
|---|----------|-----------|
| 1 | Smoke Point A shop | 200, каталог, CartSheet «тут будут твои заказы», console: известный шум 401/404, **5xx 0** · [P1](P1_shop_point_a.png) |
| 2 | Бандл ready UX | `readyDismiss=true`, `nonTerminalReady=true` в `application-Ckg2pPwk.js` |
| 3 | Live SMS + карточка | **👤** тестовый заказ → «Готово» на табло → SMS на телефон + карточка с крестиком |

## Наблюдения

1. CI перед деплоем потребовал bump: RuboCop spacing в тесте #75, nokogiri≥1.19.5, rails-html-sanitizer≥1.7.2, Rails **8.1.4.1** (новые advisories 2026-11-09).
2. Живая SMS зависит от регистрации имени отправителя в SMS.ru у заказчика.
