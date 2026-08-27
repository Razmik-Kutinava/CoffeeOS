# todo — T-Bank webhook: ответ plain `OK` на платёжные notify

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| /review · push/CI | CI watch | deploy — апрув |

**CBR:** нет (внутр. hot-path / канон банка)  
**Контекст:** NotificationURL `POST /callbacks/tbank`; офиц. дока Т‑Банка — HTTP 200 + тело ровно `OK`  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Пауза:** #74 Card binding — REVIEW отложен

## Цель

Все **успешные** ответы `Callbacks::TbankController#notify` на **не-fiscal** ветках (новый статус, duplicate, неизвестный статус) — `render plain: "OK", status: :ok`. Fiscal (`RECEIPT`) уже `OK` — не трогать. Ошибки (401 Token, 400, 413, 500) — без изменений.

## Gap / решения SPEC

| Вопрос | Решение |
|--------|---------|
| Где менять ответ | Только контроллер `#notify` (job/handler не render’ят HTTP) |
| Duplicate / ignore status | Тоже plain `OK` (банк считает доставленным) |
| Ошибки | Оставить JSON 4xx/5xx — дока требует `OK` только при успехе |
| Docs | `tbank.md`: убрать «платёжный = JSON»; единый успех = `OK` |

## Фазы SBR

- [x] PHASE 1 SPEC
- [x] RED (`747b8e76`)
- [x] GREEN (`0ee54a9` / Entire `01M11PSGEBSPNB7VMM6MFKDWG3`)
- [x] /regress (зона Проверка) — 46/0 PASS
- [x] REVIEW (bugbot clean · security no medium+ · Entire · push/CI)

## Файлы (ожидаемо)

- `app/controllers/callbacks/tbank_controller.rb` — 3 success-ветки не-fiscal → `plain: "OK"`
- `test/controllers/callbacks/tbank_controller_test.rb` — assert body `"OK"` вместо JSON `ok`/`duplicate`
- `docs/integrations/tbank.md` — канон ответа + риск duplicate

### Blast-radius (+соседи, без правок если не надо)

- `app/jobs/payments/tbank_callback_job.rb` — делегат обработки; HTTP не формирует
- `app/services/payments/tbank_fiscal_notification_handler.rb` — fiscal; ответ уже `OK` в контроллере
- Integration, что бьют `POST /callbacks/tbank` — только если assert’ят JSON body

## Не ломать

- CONFIRMED / REJECTED → payment/order статусы и job как сейчас
- Fiscal `RECEIPT` → plain `OK` + `TbankFiscalNotificationHandler`
- Invalid Token → 401 (не `OK`)
- Idempotency: повторный webhook не ломает оплату (логика claim без смены семантики)

## Проверка

```bash
bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb
```
