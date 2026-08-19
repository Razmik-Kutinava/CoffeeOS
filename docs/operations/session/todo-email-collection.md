# TODO: Email-сбор после оплаты (Callcheck-флоу)

**Дата начала**: 2026-08-19  
**Фаза**: PHASE 0-1 завершена  
**Ожидающие**: PHASE 2 RED/GREEN

---

## Чеклист Subtasks

### PHASE 2: RED (Тесты)

- [ ] **ST-1**: Удалить email/имя/OTP из экрана оплаты (RED test)
- [ ] **ST-2**: Проверить отсутствие email-гейта в payment flow (RED test)
- [ ] **ST-3**: Добавить toggle сохранения карты (RED test)
- [ ] **ST-4**: Добавить email-блок на успех (RED test)
- [ ] **ST-5**: Добавить маркетинг-согласие чекбокс (RED test)
- [ ] **ST-6**: Сделать email-блок неблокирующим (RED test)
- [ ] **ST-7**: Inline-валидация email (RED test)
- [ ] **ST-8**: API сохранения email заказа (RED test)
- [ ] **ST-9**: CRM только при согласии (RED test)
- [ ] **ST-10**: Асинхронная отправка чека (RED test)
- [ ] **ST-11**: Обработка bounce (RED test)
- [ ] **ST-12**: Предзаполнение email для повтора (RED test)
- [ ] **ST-13**: Изменение/удаление email (RED test)
- [ ] **ST-14**: Идемпотентность (RED test)
- [ ] **ST-15**: Независимость кассового чека (RED test)
- [ ] **ST-16**: Frontend критические тесты (Vitest/Jest)
- [ ] **ST-17**: Backend критические тесты (RSpec)
- [ ] **ST-18**: UX-копирайт и flow (ревью)
- [ ] **ST-19**: TDD RED все тесты зелёные
- [ ] **ST-20**: TypeCheck & Lint passed

### PHASE 2: GREEN (Реализация)

- [ ] **ST-1**: Изменение Checkout.svelte
- [ ] **ST-2**: Проверка shopPayFsm.js
- [ ] **ST-3**: NewCardForm.svelte + toggle
- [ ] **ST-4**: PaymentResult.svelte + email-блок
- [ ] **ST-5-7**: OrderSuccessEmailBlock.svelte (валидация + маркетинг)
- [ ] **ST-8**: email_controller.rb + endpoint
- [ ] **ST-9**: email_service.rb (логика + очередь)
- [ ] **ST-10**: send_order_receipt_email_job.rb
- [ ] **ST-11**: email_provider webhook + bounce handling
- [ ] **ST-12-14**: OrderEmail Model + идемпотентность
- [ ] **ST-15**: Проверка Receipt formation
- [ ] **ST-16-17**: Все тесты GREEN
- [ ] **ST-18**: UX review + текст
- [ ] **ST-19-20**: CI green (npm test, npx tsc, rspec)

### PHASE 3: REVIEW

- [ ] Security scan (npm audit)
- [ ] Code review
- [ ] Manual testing (desktop + mobile)
- [ ] Documentation
- [ ] Push & Deploy

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

1. **PHASE 2 START**: Разбить RED tests по subtasks
2. **RED тесты**: Написать intentional failures
3. **GREEN**: Реализовать функции
4. **CI**: Запустить локально и убедиться green
5. **PHASE 3**: Ревью и deployment

---

**Status**: 🔴 RED PHASE READY (waiting for START signal)
