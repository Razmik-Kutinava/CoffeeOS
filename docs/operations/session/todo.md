# todo — #74 Устранение утечки данных чужой карты при привязке

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| /regress PASS 5+46+8 | ждёт `/review` | `/review` |

**CBR:** #74  
**ТЗ:** [`customer_tasks/Устранение утечки данных чужой карты при привязке.md`](../milestones/veha_2/requirements/customer_tasks/Устранение%20утечки%20данных%20чужой%20карты%20при%20привязке.md)  
**Артефакты:** [`artifacts/card_binding_unique_hash/`](../milestones/veha_2/artifacts/card_binding_unique_hash/)  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Группа:** security review · задача 1

## Цель

Одна банковская карта → не более одной **активной** привязки глобально (`card_hash` + partial unique index). При конфликте — контролируемый отказ **без** утечки `card_masked` / BIN / банка / `card_token` / `card_hash` / id владельца. Race закрывается constraint’ом БД.

## Gap / решения SPEC

| Вопрос | Решение |
|--------|---------|
| Источник `card_hash` | HMAC-SHA256(`secret_key_base`, `mobile_payment_methods.card_hash.v1:` + CardId) |
| Без CardId | `card_hash` nil — без глобального unique |
| Отказ | `persist_from_tbank!` → `nil` + лог `card_binding_rejected` (не 500) |
| Data-migration | `rails mobile_payment_methods:card_hash:dry_run` / `:apply` **до** unique index на prod с дублями |

## Фазы SBR

- [x] PHASE 0 intake (`6e88b962`)
- [x] PHASE 1 SPEC (`bdda8687`)
- [x] RED (`951a349b`)
- [x] GREEN (`37ae717c`) · Entire `01M11NEP02FPMW463C1RK4A1T5`
- [x] /regress (зона Проверка) — 5+46+8 PASS
- [ ] REVIEW (bugbot + security-review + Entire + push/CI)

## Subtasks (из ТЗ)

- [x] 1. Расчёт стабильного `card_hash` в `SavedCardStore`
- [x] 2. Колонка `card_hash` (nullable) в `mobile_payment_methods`
- [x] 3. Data-migration dry-run → отчёт дубликатов
- [x] 4. Деактивация дубликатов (oldest created_at/id)
- [x] 5. Partial unique index на активный `card_hash`
- [x] 6. Перехват unique violation → контролируемый отказ (не 500)
- [x] 7. Payload отказа без данных чужой карты
- [x] 8. Тест параллельной привязки одного `card_hash`

## Файлы (ожидаемо)

- `app/services/payments/saved_card_store.rb` — `card_hash` + отказ
- `app/models/mobile_payment_method.rb` — `card_hash`, `dedupe_active_card_hashes!`
- `db/migrate/20260827180000_add_card_hash_to_mobile_payment_methods.rb` — nullable column
- `db/migrate/20260827180100_add_unique_active_card_hash_index_to_mobile_payment_methods.rb` — partial unique
- `lib/tasks/mobile_payment_methods_card_hash.rake` — dry-run / apply
- `app/services/payments/mobile_payment_methods_card_hash_migration.rb` — логика data-migration (+1)
- `test/services/payments/saved_card_store_test.rb` — TDD

### Blast-radius (+соседи)

- `app/services/shop/new_card_payment_service.rb` — soft-rescue persist (без правок)
- `app/jobs/payments/tbank_callback_job.rb` + `tbank_payment_sync.rb` — тот же `persist_from_tbank!`
- `app/services/shop/saved_card_json.rb` — не сериализует `card_hash`/`card_token`

## Не ломать

- Оплата новой картой + webhook CONFIRMED + RebillId → карта своего аккаунта сохраняется
- Несколько карт **внутри одного** аккаунта (upsert / default)
- `save_card=false` — UserCards не создаются
- One-click / recurrent по своей карте; auth/OTP не трогаем

## Проверка

```bash
bin/rails test test/services/payments/saved_card_store_test.rb
bin/rails test test/controllers/callbacks/tbank_controller_test.rb test/services/payments/tbank_adapter_test.rb
bin/rails test test/integration/shop/shop_second_card_step5_test.rb test/integration/shop/shop_save_card_false_step6_test.rb
```

## Ops вне кода

- Prod: `card_hash:dry_run` → отчёт в artifacts → `card_hash:apply` → затем migrate unique index (если index ещё не накатили)
- Migration Gate / deploy — апрув владельца
- Fly MCP Point A после deploy
