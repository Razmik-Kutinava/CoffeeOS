# MCP — #39 Order ready cascade · Fly v426 · 2026-08-04

| Проверка | Результат |
|----------|-----------|
| Push `develop` | `2af25874` |
| Fly image | `deployment-01KZ5X2WSEYB4GKVBVPBMJ3SG0` |
| Version | **v426** |
| Secrets | `TELEGRAM_BOT_TOKEN` staged+deployed · `SMS_RU_*` **не заданы** (SMS fallback log-only если TG нет) |
| DDL | `telegram_chat_id` + `order_notification_logs` (release ConcurrentMigrationError после DDL → `--skip-release-command`) |
| Aram `telegram_chat_id` | `183760838` на `+79639124847` |
| Cascade smoke | order `#202608-0005` → `ready` → job → **`telegram:sent`** · log «Telegram message delivered» |
| HTTP | `/up` OK · `/shop` OK |

**Note:** заказ `#202608-0005` для smoke переведён `accepted→ready` через `update_columns` (не barista UI).
