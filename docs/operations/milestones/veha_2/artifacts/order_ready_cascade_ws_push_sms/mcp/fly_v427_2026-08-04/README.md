# MCP — #39 v2 Order ready cascade · Fly v427 · 2026-08-04

| Проверка | Результат |
|----------|-----------|
| Push `develop` | `7b4ff49f` |
| Fly image | `deployment-01KZ695P61B8GEC9CVZ0AA8GDD` |
| Version | **v427** |
| HTTP | `/up` **200** · `/shop` **200** · меню Point A загрузилось |
| Secrets | `SMS_RU_*` **не заданы** → SMS fallback log-only |
| PaidNotifier | `TelegramBotClient` **нет** в коде на Fly |
| Cascade offline | order `#202608-0005` · `telegram_chat_id` ещё `183760838` → **`sms:sent`** · `RECENT_TG=0` |
| Cascade online | presence → **`SMS skipped`** · новых логов нет |
| SMOKE_OK | **true** |

**Note:** реальный SMS.ru на Fly не слался (нет `SMS_RU_API_ID`); путь каскада v2 подтверждён (SMS channel, не Telegram).

**Скрипт:** `scripts/scratch/mcp_39_v2_cascade_smoke.rb` (локальный scratch).
