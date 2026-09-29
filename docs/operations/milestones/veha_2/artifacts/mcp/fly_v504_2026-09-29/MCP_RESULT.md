# Fly v504 — post-deploy MCP (batch since v503)

**Date:** 2026-09-29 · **HEAD** `0a3ac0db` · **Fly** v504 `deployment-01M3PQG2QBMETHG8G0R8ETRD9A`  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**CI:** [`36578912741`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/36578912741) + Semgrep `36578912605` + CodeQL `36578912630` green на `0a3ac0db`

## Пачка приёмки

| Где | Результат |
|-----|-----------|
| **Migration** | `20260929120000` (`subscription_offer_states`) + `20260929150000` (`marketing_events`) — `up` на проде, только CREATE TABLE |
| **Fly** | `release_command` OK · web+worker v504 · health fail 11с на буте Puma → passing · 5xx/Exception в логах нет (200×18, 401×2 — гость без сессии) |
| **Sentry** | `is:unresolved lastSeen:-24h` — **0 issues** |
| **Neon / УК** | skip |

## Коммиты с v503 → что проверили

| Фича | Коммиты | Проверка | Статус |
|------|---------|----------|--------|
| TASK_95 состояние оффера на гостя | `42b61e1c` `bb64f742` | таблица на проде; `OfferPresentationService#call` на реальном госте Point A → all false (offer OFF, ожидаемо); `POST subscription_offer/{shown,dismiss,viewed,opened}` без auth → 401 (контроль: несуществующий → 404) | **PASS** wire; live — skip (offer OFF) |
| TASK_96 баннер / LK карточка / события | `63a317a1` | bundle содержит `subscription_offer/shown`, `should_show_banner`, `has_unread_offer_in_lk`; витрина рендерится, баннера нет | **PASS** bundle; live — skip (offer OFF) |
| TASK_97 advisory lock offer push | `c187fd81` | код на проде (`offer_push_notifier.rb:47 create_once`); конкуренция — local test | **PASS** deploy; live push — skip |
| TASK_98 воронка + UTM | `00bdcf64` (+ `63a317a1`) | `OfferFunnelReport.call(point A, 7d)` → `rows: []` без ошибок; `/manager/subscription_offer_funnel` → 302 `/login` | **PASS** |
| TASK_99 iOS WebPush permission | `48fa2646` | `requestPermission` в bundle; SW `/firebase-messaging-sw.js` содержит `offer_url` | **PASS** bundle; G4 физический iPhone — pending |
| rack-proxy 2.0.1 / vite_ruby 3.11.0 | `23565015` | vite assets 200, витрина 200 | **PASS** |

Проверка backend — read-only `rails runner` в транзакции с `ROLLBACK`; данных не создавали.

## Findings

- ⚪ Rails warning: enum `not_shown` в `SubscriptionOfferState` конфликтует с авто negative scopes (`not_*`). Не ошибка рантайма — backlog.
- 🟡 `/uploads/products/*` 404 — известно (`ISSUES.md`), не регресс v504.

## Next

- TASK_99 G4 — физический iPhone (диалог сразу после клика, токен в БД)
- Live offer flow — после включения offer на Point A (billing UI)
