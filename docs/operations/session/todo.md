# todo — Callbacks security CLOSED (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| review#2 Bugbot 0 · Security OK | done local | push по апруву · Fly MCP после deploy |

## Файлы
- `app/controllers/callbacks/tbank_controller.rb`
- `app/controllers/callbacks/sms_ru_controller.rb`
- `app/services/callbacks/sms_ru_webhook.rb`
- `.github/workflows/ci.yml`

## Проверка
- regress sms_ru + tbank → **23/0 PASS**
