# MCP #80 — Fly v492 — Slice V live (phone) — 2026-09-08

Point A · Fly **v492** · `SHOP_OTP_LOG_FALLBACK=false`  
Phone under test: `+7…4847` (masked in report)

| Step | Result | Notes |
|------|--------|-------|
| **V0** preconditions | **PASS** | shop + checkout → «Вход по телефону» · fallback=false |
| **V1** init Callcheck | **PASS** ×2 | `POST init_callcheck` → UI «Ждем ваш звонок…» · `tel:8-800-777-9999` |
| **V2** live call → `check_status` confirmed | **NOT VERIFIED** | 2× окно ~40с; polls `check_status` без confirmed; затем auto `send_sms` |
| **V3** leave wizard / session | **NOT VERIFIED** | нет confirmed → leave не проверяли |

**Screens:** `01_phone_input_v0.png` · `02_callcheck_waiting.png` · `03_sms_fallback_204.png`

## Наблюдения

1. Callcheck UI path **жив** (init + poll + tel button).
2. После ~40с каскад уходит в SMS fallback (ожидаемо).
3. SMS fallback для этого оператора: **SMS.ru 204** «не подключили данного оператора на отправителе» — **ops кабинет SMS.ru**, не баг leave-wizard после confirmed.
4. В логах: `check_status` poll → `send_sms`; **нет** сигнала confirmed/verified в этой сессии.

## Вердикт Slice V

| | |
|---|---|
| Leave wizard после звонка | **ещё не доказан** (нет confirmed) |
| Slice F (код leave wizard) | **не стартовать** — нет FAIL слоя `confirmed→UI` |
| SMS 204 | отдельно: кабинет SMS.ru «Отправители» · **не** FlashCall · **не** rewrite cascade |

## Дальше

1. Синхронно: как только появится `8-800-777-9999` — **сразу** звонок с `+7…4847` (до таймера SMS).
2. Если звонок уже был, а UI не ушёл — зафиксировать FAIL по матрице (`check_status` forever false vs UI stuck) → тогда Slice F.
3. SMS 204 чинить в SMS.ru, не в CoffeeOS leave-wizard.

**Код:** не трогали.
