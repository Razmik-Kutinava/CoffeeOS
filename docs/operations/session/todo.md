# todo — #74 Устранение утечки данных чужой карты при привязке

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 0 intake `6e88b962` | SPEC | `/sbr` → RED |

**CBR:** #74  
**ТЗ:** [`customer_tasks/Устранение утечки данных чужой карты при привязке.md`](../milestones/veha_2/requirements/customer_tasks/Устранение%20утечки%20данных%20чужой%20карты%20при%20привязке.md)  
**Артефакты:** [`artifacts/card_binding_unique_hash/`](../milestones/veha_2/artifacts/card_binding_unique_hash/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Группа:** security review · задача 1

## Цель

Одна банковская карта → не более одной **активной** привязки глобально (`card_hash` + partial unique index). При конфликте — контролируемый отказ **без** утечки `card_masked` / BIN / банка / `card_token` / `card_hash` / id владельца. Race закрывается constraint’ом БД.

## Gap / решения SPEC

| Вопрос | Решение на RED/GREEN |
|--------|----------------------|
| Источник `card_hash` | Стабильный keyed hash от `CardId` → `bank_card_id` (уже в схеме); без `CardId` — не создавать глобальный hash / не активировать cross-account guard до появления id (зафиксировать в тесте) |
| Тесты ТЗ (`rspec`/`spec`) | Канон репо: **Minitest** `test/services/payments/saved_card_store_test.rb` (+ точечный integration при необходимости) |
| Ответ API при отказе | Платёж уже soft-success в `NewCardPaymentService`; отказ привязки = нет `saved_card` / нейтральный лог, **не** 500 и не поля чужой карты |
| DDL | Migration Gate: апрув владельца перед `db:migrate` на стенд/prod; локально в GREEN после RED |

## Фазы SBR

- [x] PHASE 0 intake (`6e88b962`)
- [x] PHASE 1 SPEC (этот шаг)
- [ ] RED — падающие тесты `card_hash` / unique / race / no-leak `[RED]`
- [ ] GREEN — миграции + store + data-migration + зелёные тесты `[GREEN]`
- [ ] /regress (зона Проверка)
- [ ] REVIEW (bugbot + security-review + Entire + push/CI)

## Subtasks (из ТЗ)

- [ ] 1. Расчёт стабильного `card_hash` в `SavedCardStore`
- [ ] 2. Колонка `card_hash` (nullable) в `mobile_payment_methods`
- [ ] 3. Data-migration dry-run → отчёт дубликатов в artifacts
- [ ] 4. Деактивация дубликатов (детерминированное правило + журнал)
- [ ] 5. Partial unique index на активный `card_hash`
- [ ] 6. Перехват unique violation → контролируемый отказ (не 500)
- [ ] 7. Payload отказа без данных чужой карты
- [ ] 8. Тест параллельной привязки одного `card_hash`

## Файлы (ожидаемо)

- `app/services/payments/saved_card_store.rb` — считать `card_hash`, писать поле, ловить `RecordNotUnique` / PG unique → отказ без утечки
- `app/models/mobile_payment_method.rb` — поле/`card_hash`, scope активных карт (без лишней валидации, дублирующей БД)
- `db/migrate/*_add_card_hash_to_mobile_payment_methods.rb` — nullable `card_hash`; затем (или той же миграцией после backfill) partial unique `WHERE is_active AND card_hash IS NOT NULL`
- `lib/tasks/mobile_payment_methods_card_hash.rake` — dry-run отчёт + apply деактивации дубликатов
- `test/services/payments/saved_card_store_test.rb` — зеркало: hash, unique refusal, no-leak payload, race (threads)

### Blast-radius (+соседи, не ломать без нужды)

- `app/services/shop/new_card_payment_service.rb` — уже soft-rescue persist; убедиться, что отказ привязки не отдаёт чужой `saved_card`
- `app/jobs/payments/tbank_callback_job.rb` + `app/services/payments/tbank_payment_sync.rb` — второй/третий вход в `persist_from_tbank!` (тот же контракт отказа)
- `app/services/shop/saved_card_json.rb` — **не** сериализовать `card_hash` / `card_token`

## Не ломать

- Оплата новой картой + webhook CONFIRMED + RebillId → карта своего аккаунта по-прежнему сохраняется
- Несколько карт **внутри одного** аккаунта (upsert / смена default) — как сейчас
- `save_card=false` — UserCards не создаются
- One-click / recurrent по уже своей карте; история платежей и auth/OTP не трогаем

## Проверка

```bash
bin/rails test test/services/payments/saved_card_store_test.rb
bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb
bin/rails test test/integration/shop/shop_second_card_step5_test.rb test/integration/shop/shop_save_card_false_step6_test.rb
```

## Ops вне кода

- Migration Gate: явный апрув владельца на DDL/data-migration apply (не только dry-run)
- Dry-run отчёт → `artifacts/card_binding_unique_hash/`
- Fly MCP Point A после deploy (save_card / UserCards) — на REVIEW/deploy
