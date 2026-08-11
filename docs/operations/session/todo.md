# todo — Fly v448 callbacks security (2026-08-11)

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| push+deploy v448 · MCP Point A PASS | done on Fly | SMS.ru URL в ЛК если нужно |

## Smoke Fly
- `/up` 200
- `POST /callbacks/tbank` {} → 401
- `POST /callbacks/tbank` 256KB+ → **413**
- `POST /callbacks/sms_ru` bad hash → 401
- Point A shop MCP → 200 + витрина
