# todo — СБП банк-ограничения: 3001 + Zero-Click AccountToken

| Поле | Значение |
|------|----------|
| **Режим** | ops/bank-first SBR · **не** «переписать оплату» |
| **Primary** | Slice **O** → **B** → **Z** |
| **Conditional** | Slice **C** (код) — только если после O банк OK, а падает наш слой |
| **ТЗ** | [`Интеграция Автоплатежей СБП Т-Касса в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20Автоплатежей%20СБП%20Т-Касса%20в%20PWA.md) (#34) |
| **Канон** | `docs/integrations/tbank.md` · runbook `DEPLOY_PWA_PAYMENTS_BATCH.md` · ISSUES `SBP 3001` 🟡 |
| **Артефакты** | `docs/operations/milestones/veha_2/artifacts/tbank_sbp_autopayments_account_token/` |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Блокер** | **3001 без кабинета = BLOCKED ops, не баг кода** |

## Жёсткие запреты

- Фиктивный GREEN «обошли 3001 в коде» / мок prod-оплаты как «готово»
- Новые платёжные gem’ы / другой эквайринг
- ErrorCode банка ≠ сразу баг CoffeeOS

## Slices

| Slice | DoD | Статус |
|-------|-----|--------|
| **O** Кабинет / 3001 | ЛК: СБП на терминале Point A · Fly TerminalKey совпадает · `POST …/sbp/init` **без** `error_code: 3001` → `payment_url` | [ ] |
| **B** Bind AccountToken | O PASS · `save_sbp_account: true` · webhook `RequestKey` · `GetAddAccountQRState` → token в `mobile_payment_methods` (sbp) · токен не в логах/UI целиком | [ ] |
| **Z** Zero-Click | B PASS · `POST …/sbp/charge` → ChargeQr CONFIRMED (или soft decline → fallback **без** удаления token) | [ ] SKIP пока нет B |
| **C** Code | Только доказанный FAIL нашего слоя после O PASS · RED→GREEN→REVIEW | [ ] условный |

### Вердикт O → дальше

| Результат | Действие |
|-----------|----------|
| PASS (`payment_url`) | → B |
| FAIL 3001 | артефакт JSON · **код не трогать** · эскалировать кабинет |
| FAIL другой ErrorCode | матрица кабинет vs Init/Token |

### FAIL matrix → когда C

| Симптом | Слой |
|---------|------|
| Банк OK, webhook не дошёл / 401 подпись | callbacks / NotificationURL / Token |
| Webhook есть, AccountToken не сохранён | `SbpAccountTokenFromWebhook` / store |
| Токен есть, UI не предлагает «Ваш счёт СБП» | shop API methods / frontend |
| 3001 на init bind | снова **O**, не C |

## SBR

- [x] **SPEC** (этот файл)
- [ ] **Verify O** — live init Point A + артефакт MCP (docs/artifact commit OK; без feat)
- [ ] **Verify B** — live bind → AccountToken в БД
- [ ] **Verify Z** — charge PASS **или** BLOCKED «банк не отдал token» с доказательством
- [ ] **RED** — только если Slice C
- [ ] **GREEN** — только если Slice C
- [ ] **REVIEW** — только если был C (bugbot + security + Entire + push)

## Файлы (ожидаемо)

Verify / условный C (2–7 + blast):

- `docs/integrations/tbank.md` — канон СБП / autopay / ErrorCode 3001
- `app/services/payments/sbp_account_token_from_webhook.rb` — RequestKey → GetAddAccountQRState → store
- `app/services/payments/sbp_account_token_store.rb` — idempotent запись sbp method
- `app/services/payments/tbank_sbp_autopay.rb` — ChargeQr zero-click
- `app/frontend/lib/shopSbpPay.js` — `mapSbpInitError` 3001 + fallback copy (C только если сломан)
- `test/integration/shop/api/sbp_autopay_charge_test.rb` — зона charge при C
- `test/integration/shop/api/sbp_init_save_account_test.rb` — bind/init save_account при C

### Blast-radius (+соседи)

- `app/jobs/payments/tbank_callback_job.rb` — ветка `RequestKey` → FromWebhook (если webhook path в C)
- `docs/operations/runbooks/DEPLOY_PWA_PAYMENTS_BATCH.md` — «SBP 3001 = кабинет, не hotfix»
- артефакт: `…/artifacts/tbank_sbp_autopayments_account_token/mcp/fly_vNNN_…/MCP_RESULT.md`

## Не ломать

1. Разовый СБП deep link (CODE:BLACK) / `sbp/init` без bind
2. Card Init/Charge / UserCards / RebillId
3. Webhook idempotency `tbank:callback:{PaymentId}:{Status}`
4. Min charge ≥10₽ · `mapSbpInitError` 3001 → понятный текст + путь на карту
5. Soft decline zero-click — **не** удалять AccountToken

## Проверка

```bash
# Local (обязательно при Slice C; при O/B/Z — smoke зоны по желанию)
ruby bin/rails test test/integration/shop/api/sbp_autopay_charge_test.rb
ruby bin/rails test test/services/payments/sbp_account_token_store_test.rb test/services/payments/sbp_account_token_from_webhook_test.rb

# Live Point A (O / B / Z)
# POST /shop/api/payments/sbp/init  → не 3001
# bind save_sbp_account=true → AccountToken в БД
# POST /shop/api/payments/sbp/charge → CONFIRMED или явный BLOCKED
```

## Критерий «готово»

- [ ] Init СБП Point A **без 3001**
- [ ] Хотя бы один live bind → `AccountToken` в БД
- [ ] Zero-Click PASS **или** BLOCKED «банк не отдал token» с доказательством
- [ ] Если был C — тесты + live после фикса

Продукт «СБП работает» ≠ «написали ещё адаптер».
