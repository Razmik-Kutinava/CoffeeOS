# MCP #80 — Fly v492 — Slice V live sync — 2026-09-08

Point A · Fly **v492** · `SHOP_OTP_LOG_FALLBACK=false`  
Phone: `+7…4847`

| Step | Result | Notes |
|------|--------|-------|
| **V0** | **PASS** | shop / checkout / fallback=false |
| **V1** | **PASS** | sync «звоню»: init → «Ждем…» · `tel:8-800-777-9999` · timer `secondsLeft` down from 40 |
| **V2** | **NOT CONFIRMED** | app `check_status` → **200** с `confirmed:false` до timeout; нет `confirmed:true` в сессии |
| **V3** | **NOT VERIFIED** | leave wizard не наступил |

**Screens:** `01_phone_input_v0.png` · `02_callcheck_waiting.png` · `03_sms_fallback_204.png` · `04_sync_call_waiting.png` (если есть)

## Sync attempt (пользователь: «звоню»)

1. Callcheck экран поднят; окно ~40с (`CALLCHECK_TIMEOUT_SEC`).
2. Poll UI каждые 3с → Fly: `Completed 200` на `check_status` (не 401 у app; 401 только у голого fetch без CSRF).
3. До `confirmed` не дошли → auto SMS → **422** / SMS.ru **204** (оператор/отправитель).
4. Код leave-wizard **не трогали** — нет FAIL `confirmed:true` + UI stuck.

## Вердикт

| Вопрос | Ответ |
|--------|--------|
| UI Callcheck | работает |
| Leave after confirmed | **не доказан** (SMS.ru не отдал confirmed) |
| Slice F | **не стартовать**, пока нет `confirmed:true` или явного «звонок прошёл, экран не закрылся» с network body |
| SMS 204 | ops SMS.ru «Отправители» |

## Нужно от владельца

1. Подтвердить: звонок на **`8-800-777-9999`** с `+7…4847` реально ушёл (гудки/сброс)?  
2. Если да — проверить в кабинете SMS.ru Callcheck status для check_id.  
3. Если звонок был, а `check_status` всегда `confirmed:false` → FAIL слоя SMS.ru/parse → тогда Slice F точечно.
