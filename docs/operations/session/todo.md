# todo — 🚀 SMS «Готов!» на прод

| Поле | Значение |
|------|----------|
| **Статус** | deploy PASS · эконом-пачка PASS · live SMS 👤 |
| **Основание** | апрув владельца: push + deploy · шаг 1 плана |

## Файлы

- код уже на `develop` (`8f262444` + review docs); CI-фиксы `fa0c1e49` / `ccd04d32`
- артефакт: `docs/operations/milestones/veha_2/artifacts/mcp/fly_sms_ready_2026-11-10/`

## Не ломать

- SMS текст / short-link / presence / push / Wallet / табло бариста

## Проверка

- [x] push `ccd04d32`
- [x] CI green
- [x] deploy GHA success
- [x] Sentry 24h 0
- [x] MCP shop smoke + бандл readyDismiss
- [ ] 👤 тестовый заказ → «Готово» → SMS на телефон + карточка с крестиком

## SBR

- не применимо (deploy-шаг)
