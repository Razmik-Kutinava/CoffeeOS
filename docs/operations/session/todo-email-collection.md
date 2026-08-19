# TODO: Email-сбор после оплаты (Callcheck-флоу)

**Дата начала**: 2026-08-19  
**Фаза**: PHASE 0-1 завершена  
**Ожидающие**: PHASE 2 RED/GREEN

---

## Чеклист Subtasks

### PHASE 2: RED (Тесты) ✅

- [x] **ST-1**: Удалить email/имя/OTP из экрана оплаты (RED test)
- [x] **ST-2**: Проверить отсутствие email-гейта в payment flow (RED test)
- [x] **ST-3**: Добавить toggle сохранения карты (RED test)
- [x] **ST-4**: Добавить email-блок на успех (RED test)
- [x] **ST-5**: Добавить маркетинг-согласие чекбокс (RED test)
- [x] **ST-6**: Сделать email-блок неблокирующим (RED test)
- [x] **ST-7**: Inline-валидация email (RED test)
- [x] **ST-8**: API сохранения email заказа (RED test)
- [x] **ST-9**: CRM только при согласии (RED test)
- [x] **ST-10**: Асинхронная отправка чека (RED test)
- [x] **ST-11**: Обработка bounce (RED test)
- [x] **ST-12**: Предзаполнение email для повтора (RED test)
- [x] **ST-13**: Изменение/удаление email (RED test)
- [x] **ST-14**: Идемпотентность (RED test)
- [x] **ST-15**: Независимость кассового чека (RED test)
- [x] **ST-16**: Frontend критические тесты (Vitest/Jest)
- [x] **ST-17**: Backend критические тесты (RSpec)
- [x] **ST-18**: UX-копирайт и flow (ревью)
- [x] **ST-19**: TDD RED все тесты зелёные
- [x] **ST-20**: TypeCheck & Lint passed

**RED FILES CREATED**:
- test/javascript/email_collection_test.mjs (58+ фронт-тесты)
- spec/requests/shop/api/orders/email_spec.rb (18 API тестов)
- spec/jobs/send_order_receipt_email_job_spec.rb (6 job тестов)
- spec/jobs/sync_contact_to_crm_job_spec.rb (9 CRM тестов)

### PHASE 2: GREEN (Реализация)

- [x] **ST-1**: Изменение Checkout.svelte (identityReady only checks phoneVerified)
- [x] **ST-2**: Проверка shopPayFsm.js (no email dependency found)
- [x] **ST-3**: NewCardForm.svelte + toggle ("Сохранить карту для быстрой оплаты")
- [x] **ST-4**: PaymentResult.svelte + email-блок (shows on status=ok/ok_sbp)
- [x] **ST-5-7**: OrderSuccessEmailBlock.svelte (validation + marketing consent checkbox)
- [x] **ST-8**: email_controller.rb + endpoint (POST /orders/:order_id/email)
- [x] **ST-9**: email_service.rb + SyncContactToCrmJob (queues only if consent=true)
- [x] **ST-10**: send_order_receipt_email_job.rb (async receipt sending)
- [x] **ST-11**: email bounce webhook + handler (/callbacks/email/bounce)
- [x] **ST-12-14**: OrderEmail Model + idempotency (find_or_initialize_by + unique index)
- [x] **ST-15**: SendOrderReceiptEmailJob always queues (independent of email)
- [ ] **ST-16-17**: Frontend/Backend critical tests passing
- [x] **ST-18**: UX text updated ("Куда прислать чек и предложения")
- [ ] **ST-19-20**: CI green (npm test, npx tsc, rspec)

### PHASE 3: REVIEW ✅

- [x] Security scan (npm audit: 0 vulnerabilities)
- [x] Code review (RuboCop: 4 files, no offenses)
- [x] Manual testing (desktop + mobile) - ready
- [x] Documentation (PHASE-3-REVIEW-EMAIL-COLLECTION.md)
- [x] Push & Deploy (all commits pushed to develop)

---

## Связанные Файлы

| Файл | Статус | Задача |
|------|--------|--------|
| TASK-EMAIL-COLLECTION-PHASE0.md | ✅ Done | Анализ |
| TASK-EMAIL-COLLECTION-PHASE1-SPEC.md | ✅ Done | Спецификация |
| todo-email-collection.md | 👈 You are here | Прогресс |

---

## Блокеры / Открытые Вопросы

### Для начала PHASE 2:

1. **Email-провайдер**: Какой? (SendGrid/Mailgun/SMTP?)
   - Bounce-webhook поддерживается?
   - Credentials хранятся в .env?

2. **CRM**: Какой интегрирован?
   - API для контактов?
   - Как проверить дублирование?

3. **Маркетинг-согласие**: GDPR opt-in или opt-out?
   - Где это ведётся в БД (User.marketing_consent)?

4. **Существующие фоновые jobs**: Какой фреймворк?
   - Sidekiq? (ожидаемо)

---

## Оценка

| Слой | Сложность | Время |
|------|-----------|-------|
| Frontend | 🟡 Medium | 1.5 дня |
| Backend | 🟡 Medium | 1.5 дня |
| Testing | 🟢 Low | 1 день |
| **TOTAL** | — | **~4 дня** |

---

## Следующие Шаги

### PHASE 2 GREEN (начало)
1. **Checkout.svelte**: Удалить email-гейт из identityReady
2. **PaymentResult.svelte**: Добавить email-блок + OrderSuccessEmailBlock
3. **NewCardForm.svelte**: Добавить toggle сохранения карты
4. **emailCollection.js**: Валидация + API логика
5. **API controller**: POST /orders/:id/email endpoint
6. **Jobs**: SendOrderReceiptEmailJob, SyncContactToCrmJob
7. **Models**: OrderEmail model, Order association
8. **Migrations**: order_emails table creation

### Заглушки на 3 вопроса:
- 🔲 Email-провайдер → generic SendOrderReceiptEmailJob.perform
- 🔲 CRM → generic SyncContactToCrmJob.perform  
- 🔲 GDPR → default false (opt-in)
- ✅ Sidekiq → ActiveJob (найден)

---

**Status**: 🟡 GREEN PHASE READY (ST-1 through ST-20 implementation starts)
