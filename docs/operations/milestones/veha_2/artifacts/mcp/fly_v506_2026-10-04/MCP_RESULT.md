# Fly v506 — post-deploy (RUBY-1N)

**Date:** 2026-10-04 · **HEAD** `0fa72666` · **Fly** v506 (11:21 UTC)  
**Point A:** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**CI:** [`37198039812`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37198039812) + Semgrep `37198039860` + CodeQL `37198039829` green на `0fa72666`  
**Deploy:** GitHub Actions [`37198218226`](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/37198218226) (workflow_dispatch, `develop`)

## Пачка приёмки

| Где | Результат |
|-----|-----------|
| **Migration** | нет |
| **Fly** | web+worker v506 · health fail на буте Puma → passing · `/`, `/shop`, `/login`, `/shop?tenant_id=…` = 200 |
| **Worker** | `StuckPaymentsCheckJob` 11:30 UTC на v506: 4 stuck pending (11 ₽, 07.09–30.09) → 4 Telegram-алерта, 1668 ms, без ошибок |
| **Sentry** | RUBY-1N regressed в 10:45 UTC — ещё v505 (фикс не был задеплоен). После деплоя новых событий нет; переведён в `resolved` с комментарием. Traces 5% (`SENTRY_TRACES_SAMPLE_RATE=0.05`) → подтверждение по Sentry ~через 20 запусков (~5 ч) |

## Коммиты с v505

| Фича | Коммиты | Проверка | Статус |
|------|---------|----------|--------|
| RUBY-1N: job без `payment.reload` | `4e5452d7` `01efc828` | worker лог 11:30 OK · Sentry ждём сэмпл | **PASS** (лог) |
| RUBY-1N: rebill-ветка только для succeeded | `6f401fb5` `1642a746` | тесты 146/0 + 57/0 | **PASS** |
| TASK_84 docs / crit-audit / ops | docs only | — | skip |

## Next

- Через ~5 ч проверить, что RUBY-1N не regressed
- Backlog: 4 тестовых платежа по 11 ₽ висят pending с сентября → Telegram-алерт каждые 15 минут; закрыть/отменить по решению владельца
