# TASK-EMAIL-COLLECTION: PHASE 0 INTAKE

**Дата**: 2026-08-19  
**Статус**: 🔴 RED PHASE (анализ)  
**Задача**: Email-сбор после оплаты (Callcheck-флоу)

---

## 1. Бизнес-цель

**Суть**: Убрать email/OTP-гейт из процесса оплаты, перенести сбор email на экран успешной оплаты как опциональный шаг.

**Контекст**:
- Обязательная идентификация пользователя уже закрыта верифицированным номером телефона через callcheck
- Email нужен для дублирования чека и захвата контакта в CRM
- Email НЕ должен быть условием завершения платежа или навигации
- OTP для email-подтверждения в этой задаче **не реализуется**

**Результат**: Оплата работает без email, а email собирается асинхронно на экране успеха.

---

## 2. Анализ Текущего Кода

### Что Сейчас В Checkout.svelte

```javascript
// Текущее состояние (строки 80-114)
let name = $state("")
let email = $state("")
let emailVerified = $state(false)

// Барьер для оплаты (identityReady):
const identityReady = $derived(
  phoneVerified || (isValidEmail(email) && emailVerified)
)
const canPay = $derived(identityReady && !submitting && shopIsOpenForPay())
```

**Проблема**:
- Email является условием `identityReady` (наравне с phoneVerified)
- Это блокирует оплату без email
- Это противоречит callcheck-флоу (telefone уже верифицирован)

### Что в PaymentResult.svelte

- Текущее назначение: отображение статуса платежа (OK/FAIL/WAITING)
- Редирект на `/order/:id` при успехе
- Нет email-блока

**Возможность**: Добавить email-сбор перед редиректом на `/order/:id`

### Связанные Компоненты

1. **NewCardForm.svelte** — форма ввода карты
   - Потенциально нужен toggle "Сохранить карту"

2. **shopGuestProfile.js** — сохранение профиля в localStorage
   - `isValidEmail()` функция уже есть
   - `saveGuestProfile()` есть
   - Потребуется расширение для email

3. **shopPayFsm.js** — state machine оплаты
   - Текущая логика зависит от `identityReady`
   - Нужно рефакторить зависимость от email

4. **shopSavedCards.js** — загрузка сохранённых карт
   - Нужно учитывать toggle сохранения карты при новой оплате

---

## 3. Затронутые Системы и Ограничения

### Системы, Которые МОЖНО менять
- ✅ Checkout.svelte (удалить email-гейт)
- ✅ PaymentResult.svelte (добавить email-блок)
- ✅ NewCardForm.svelte (toggle сохранения карты)
- ✅ Backend API `/shop/api/orders/:id/email` (новый endpoint)
- ✅ Background job для отправки чека
- ✅ CRM интеграция (очередь контактов)
- ✅ Email валидация клиента

### Системы, Которые НЕЛЬЗЯ менять
- ❌ Callcheck и верификация телефона
- ❌ Основной платежный flow (СБП/карта без необходимости)
- ❌ Кассовый чек и ОФД интеграция
- ❌ Логика создания заказа
- ❌ SMS-канал
- ❌ Существующая авторизация

---

## 4. Ключевые Точки Интеграции

### Frontend → Backend API
```
POST /shop/api/orders/:id/email
Body: { email: "user@example.com", marketing_consent: true }
Response: { success: true, email: "...", queued_receipt: true }
```

**Поведение**:
- Email валидируется на клиенте ПЕРЕД отправкой
- API не требует OTP
- API не должен блокировать экран успеха при ошибке
- Отправка чека ставится в очередь асинхронно

### Email-провайдер (Callback)
- Webhook для bounce/недоставки
- Маркирует email как невалидный в БД

### CRM Интеграция
- Email в очередь только при `marketing_consent: true`
- Identity маппинг через `user_id` + `order_id`

---

## 5. Файлы, Которые Нужно Менять/Создать

### Frontend

**Менять**:
- `app/frontend/routes/Checkout.svelte` — удалить email-гейт из identityReady
- `app/frontend/routes/PaymentResult.svelte` — добавить email-блок
- `app/frontend/components/NewCardForm.svelte` — добавить toggle сохранения карты
- `app/frontend/lib/shopPayFsm.js` — убрать зависимость от emailVerified в identityReady

**Создать**:
- `app/frontend/lib/emailCollection.js` — валидация, API, логика сохранения
- `app/frontend/components/OrderSuccessEmailBlock.svelte` — компонент email-блока на успехе
- `app/frontend/routes/PaymentResult.svelte.test.ts` — тесты PaymentResult
- Тесты для emailCollection.js

### Backend

**Создать**:
- `app/controllers/shop/api/orders/email_controller.rb` — обработка POST /orders/:id/email
- `app/services/orders/email_service.rb` — сохранение email, постановка в очередь
- `app/jobs/send_order_receipt_email_job.rb` — отправка чека асинхронно
- `app/jobs/sync_contact_to_crm_job.rb` — передача контакта в CRM
- `app/models/order_email.rb` или расширение Order — хранение email и статуса

**Менять**:
- `app/models/order.rb` — добавить association для email
- `app/models/user.rb` — tracking marketing_consent

**Тесты**:
- `spec/requests/shop/api/orders/email_spec.rb` — API тесты
- `spec/jobs/send_order_receipt_email_job_spec.rb`
- `spec/jobs/sync_contact_to_crm_job_spec.rb`

---

## 6. API Контракт (Предварительно)

### POST /shop/api/orders/:id/email

**Request**:
```json
{
  "email": "user@example.com",
  "marketing_consent": false
}
```

**Response 200 OK**:
```json
{
  "success": true,
  "email": "user@example.com",
  "queued_receipt": true,
  "queued_crm": false
}
```

**Response 400 Bad Request** (invalid email):
```json
{
  "success": false,
  "error": "invalid_email",
  "message": "Email format is invalid"
}
```

**Response 404 Not Found** (no order):
```json
{
  "success": false,
  "error": "not_found"
}
```

---

## 7. User Flows (Gherkin)

### Основной Сценарий (Happy Path)

```gherkin
Scenario: Оплата без email, сбор email на успехе
  Given: Пользователь с верифицированным телефоном
  When: Открывает Checkout
  Then: На экране НЕТ полей email/имени/OTP
  
  When: Выбирает способ оплаты и платит
  Then: Платёж проходит БЕЗ email
  
  When: Попадает на PaymentResult (успех)
  Then: 
    - Видит статус "Чек сформирован"
    - Видит блок "Куда прислать чек и предложения"
    - Email-блок НЕ обязательный
    - Может навигироваться дальше БЕЗ email
```

### Email-Сценарий

```gherkin
Scenario: Сохранение email с согласием на маркетинг
  Given: Пользователь на экране успеха
  When: Вводит корректный email и включает маркетинг
  Then: 
    - Email сохраняется без OTP
    - Чек отправляется асинхронно
    - Контакт добавляется в CRM очередь
    - API возвращает успех сразу (async)
```

### Обработка Ошибок

```gherkin
Scenario: Невалидный email не отправляется на backend
  Given: Пользователь вводит "invalid@"
  When: Фокус теряется или нажимает отправку
  Then: Inline-ошибка показана, запрос НЕ отправляется
```

---

## 8. Открытые Вопросы (для PHASE 1)

1. **Email-провайдер**: Какой провайдер используется? (SendGrid, Mailgun, SMTP?)
   - Где хранятся credentials?
   - Есть ли bounce-webhook?

2. **CRM**: Какой CRM интегрирован? (Pipedrive, HubSpot, другой?)
   - Есть ли API для контактов?
   - Как идентифицировать дублирование контактов?

3. **Кассовый чек**: Как сейчас формируется и отправляется?
   - Через ОФД? Через email-провайдер?
   - Нужна ли копия email при сохранении email заказа?

4. **Маркетинговое согласие**: Что такое "согласованное юридическое требование"?
   - GDPR opt-in или opt-out?
   - Где это согласие хранится в БД?

5. **Карта сохранение**: Текущее поведение на NewCardForm?
   - Есть ли toggle?
   - Как сохраняется карта?

---

## 9. Предварительная Оценка Сложности

**Frontend**: 🟡 Средняя
- Удалить email-гейт: low
- Добавить email-блок на успех: medium (валидация, UI)
- Toggle сохранения карты: low

**Backend**: 🟡 Средняя
- API endpoint: low
- Email-сервис + background job: medium
- CRM интеграция: medium (зависит от наличия адаптера)
- Bounce-обработка: medium (зависит от webhook)

**Total Effort**: ~4-5 дней (RED/GREEN/REVIEW)

---

## 10. Следующий Шаг

→ **PHASE 1**: Спецификация файлов, API контрактов, тестовые сценарии

**Blockers для начала PHASE 1**:
- [ ] Ответы на открытые вопросы (email-провайдер, CRM, маркетинг-согласие)
- [ ] Текущее состояние email-провайдера (есть ли?)
- [ ] Текущее состояние CRM (есть ли адаптер?)

---

**PHASE 0 READY**: Анализ завершён, готово к спецификации
