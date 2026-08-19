# TASK-EMAIL-COLLECTION: PHASE 1 SPECIFICATION

**Дата**: 2026-08-19  
**Статус**: 📋 SPEC  
**Итерация**: 20 Subtasks (RED/GREEN phases)

---

## 1. Файлы & Структура

### Frontend (JavaScript/Svelte)

#### Новые файлы

```
app/frontend/
├── lib/
│   ├── emailCollection.js              # Валидация email, API, логика
│   ├── orderSuccessEmailStore.js       # State management для email-блока
│   └── emailValidation.js              # Utility для inline-валидации
├── components/
│   └── OrderSuccessEmailBlock.svelte    # Email-блок на PaymentResult
└── tests/
    ├── emailCollection.test.ts          # Тесты emailCollection.js
    ├── emailValidation.test.ts          # Тесты валидации
    └── OrderSuccessEmailBlock.test.ts   # Тесты компонента
```

#### Существующие файлы (изменения)

```
app/frontend/
├── routes/
│   ├── Checkout.svelte                 # -email-гейт из identityReady
│   └── PaymentResult.svelte             # +email-блок при успехе
├── components/
│   └── NewCardForm.svelte               # +toggle "Сохранить карту"
├── lib/
│   ├── shopPayFsm.js                    # -зависимость emailVerified
│   ├── shopGuestProfile.js              # Используется как есть (валидация есть)
│   └── cartSheetStore.js                # Проверить интеграцию
```

### Backend (Ruby)

#### Новые файлы

```
app/
├── controllers/
│   └── shop/api/orders/
│       └── email_controller.rb          # POST /orders/:id/email
├── services/
│   └── orders/
│       └── email_service.rb             # Сохранение, очередь
├── jobs/
│   ├── send_order_receipt_email_job.rb  # Отправка чека асинхронно
│   └── sync_contact_to_crm_job.rb       # Отправка в CRM
├── models/
│   └── order_email.rb                   # Model для OrderEmail
└── mailers/
    └── order_receipt_mailer.rb          # Шаблон чека
    
spec/
├── requests/shop/api/orders/
│   └── email_spec.rb                    # API endpoint тесты
└── jobs/
    ├── send_order_receipt_email_job_spec.rb
    └── sync_contact_to_crm_job_spec.rb
```

#### Существующие файлы (изменения)

```
app/
├── models/
│   ├── order.rb                         # +email association + validations
│   └── user.rb                          # +marketing_consent tracking (опционально)
├── routes.rb                            # +POST /orders/:id/email endpoint
└── config/
    └── credentials.yml.enc              # +EMAIL_PROVIDER, CRM keys
```

---

## 2. Детальная Спецификация Subtasks

### SUBTASK 1: Удалить email/имя/OTP из экрана оплаты

**Файл**: `app/frontend/routes/Checkout.svelte`

**Что менять**:
```javascript
// БЫЛО:
const identityReady = $derived(
  phoneVerified || (isValidEmail(email) && emailVerified)
)

// СТАЛО:
const identityReady = $derived(phoneVerified)
```

**Также**:
- Удалить UI элементы email/имени из шаблона (если они есть)
- Оставить phone-authWizard как есть
- Убедиться, что кнопка оплаты зависит только от `phoneVerified`

**Тест**: 
```javascript
// RED: test("email поле не блокирует оплату при пустом значении")
// GREEN: identityReady == phoneVerified
```

---

### SUBTASK 2: Проверить отсутствие email-гейта в payment flow

**Файл**: `app/frontend/lib/shopPayFsm.js`

**Проверить**:
- `isPayFsmClickable()` не зависит от email
- `PAY_FSM` states не требуют email
- NewCardForm не требует email

**Тест**:
```javascript
// RED: test("оплата проходит без email, phoneVerified=true")
// GREEN: mockApi(phone_verified=true) → canPay=true
```

---

### SUBTASK 3: Добавить необязательный toggle сохранения карты

**Файл**: `app/frontend/components/NewCardForm.svelte`

**Что добавить**:
```svelte
<label>
  <input type="checkbox" bind:checked={saveCard} />
  Сохранить карту для быстрой оплаты в следующий раз
</label>
```

**Логика**:
- Toggle опциональный (не влияет на возможность оплаты)
- Состояние не влияет на validation
- При успехе: передать `{ saveCard }` в API

**Тест**:
```javascript
// RED: test("toggle сохранения карты не блокирует оплату")
// GREEN: canPay=true когда saveCard=false
```

---

### SUBTASK 4: Добавить email-блок на экран успешной оплаты

**Файл**: `app/frontend/routes/PaymentResult.svelte`

**Что добавить** (при status=ok):
```svelte
{#if status === "ok" || status === "ok_sbp"}
  <div class="success-section">
    <p>✅ Чек сформирован</p>
    
    <div class="email-block">
      <h3>📧 Куда прислать чек и предложения</h3>
      <OrderSuccessEmailBlock orderId={orderId} />
    </div>
  </div>
{/if}
```

**Поведение**:
- Email-блок видна ТОЛЬКО при успешной оплате
- Блок НЕ обязательный (можно закрыть без заполнения)
- Зависит от компонента `OrderSuccessEmailBlock.svelte`

**Тест**:
```javascript
// RED: test("email-блок есть при status=ok")
// GREEN: email-блок отображается, toggle может быть пустой
```

---

### SUBTASK 5: Добавить чекбокс маркетингового согласия

**Файл**: `app/frontend/components/OrderSuccessEmailBlock.svelte`

**Что добавить**:
```svelte
<div>
  <input type="email" bind:value={email} placeholder="your@email.com" />
  
  <label>
    <input type="checkbox" bind:checked={marketingConsent} />
    Отправляйте мне предложения и новости
  </label>
</div>
```

**Логика**:
- Согласие опциональное
- Начальное состояние: `false` (opt-in, no pre-check)
- Согласие НЕ требуется для сохранения email

**Тест**:
```javascript
// RED: test("маркетинг-согласие не требуется для отправки email")
// GREEN: можно отправить email с marketingConsent=false
```

---

### SUBTASK 6: Сделать email-блок неблокирующим

**Файл**: `app/frontend/routes/PaymentResult.svelte`

**Навигация**:
- Кнопка "Продолжить" / "Дальше" работает БЕЗ заполнения email
- Закрытие экрана НЕ требует email
- Редирект на `/order/:id` БЕЗ ошибки

**Тест**:
```javascript
// RED: test("можно навигироваться без email")
// GREEN: push("/order/:id") без email
```

---

### SUBTASK 7: Добавить inline-валидацию email

**Файл**: `app/frontend/components/OrderSuccessEmailBlock.svelte`

**Логика**:
```javascript
function validateEmail(value) {
  const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
  return isValid
}
```

**Поведение**:
- На blur: проверить формат
- Inline ошибка: "Некорректный email"
- Кнопка "Отправить" disabled если ошибка
- НЕ отправляется запрос на backend с невалидным email

**Тест**:
```javascript
// RED: test("невалидный email не отправляется на backend")
// GREEN: inline error показана, запрос НЕ отправлен
```

---

### SUBTASK 8: Реализовать API сохранения email заказа

**Backend Endpoint**: `POST /shop/api/orders/:id/email`

**Файл**: `app/controllers/shop/api/orders/email_controller.rb`

```ruby
module Shop
  module Api
    module Orders
      class EmailController < ApplicationController
        def create
          order = Order.find(params[:order_id])
          
          service = Orders::EmailService.new(order)
          result = service.save_email(
            email: params[:email],
            marketing_consent: params[:marketing_consent]
          )
          
          if result.success?
            render json: result.to_h, status: 200
          else
            render json: result.to_h, status: 400
          end
        end
      end
    end
  end
end
```

**Request**:
```json
{
  "email": "user@example.com",
  "marketing_consent": true
}
```

**Response 200**:
```json
{
  "success": true,
  "email": "user@example.com",
  "queued_receipt": true,
  "queued_crm": true
}
```

**Validation**:
- Email format проверяется на backend (redundant с фронт, но обязательно)
- Order должен существовать
- Email может быть пусто (опциональный запрос)

**Тест**:
```ruby
# RED: test "POST /orders/:id/email saves email without OTP"
# GREEN: Order.email == "user@example.com"
```

---

### SUBTASK 9: Передавать email в CRM только при согласии

**Файл**: `app/services/orders/email_service.rb`

```ruby
def save_email(email:, marketing_consent:)
  if email.present? && valid_email?(email)
    order.order_email.create!(
      email: email,
      marketing_consent: marketing_consent
    )
    
    SyncContactToCrmJob.perform_later(
      order_id: order.id,
      email: email,
      marketing_consent: marketing_consent
    ) if marketing_consent
    
    SendOrderReceiptEmailJob.perform_later(order_id: order.id, email: email)
  end
end
```

**Логика**:
- Если `marketing_consent=false`: email сохраняется, но НЕ отправляется в CRM
- Если `marketing_consent=true`: email отправляется в CRM очередь

**Тест**:
```ruby
# RED: test "email не передаёт в CRM без согласия"
# GREEN: SyncContactToCrmJob.enqueued? == false когда consent=false
```

---

### SUBTASK 10: Отправлять копию чека асинхронно

**Файл**: `app/jobs/send_order_receipt_email_job.rb`

```ruby
class SendOrderReceiptEmailJob
  include Sidekiq::Job
  
  def perform(order_id, email)
    order = Order.find(order_id)
    OrderReceiptMailer.send_receipt(order, email).deliver_later
  end
end
```

**Поведение**:
- Задача ставится в очередь АСИНХРОННО
- API возвращает результат сразу (без ожидания email)
- Маилер использует существующий receipt-шаблон

**Тест**:
```ruby
# RED: test "API возвращает успех без ожидания отправки email"
# GREEN: response time < 500ms, job enqueued
```

---

### SUBTASK 11: Обработать недоставку email (bounce)

**Файл**: `app/controllers/shop/webhooks/email_provider_controller.rb`

```ruby
def handle_bounce
  # Webhook от email-провайдера (SendGrid, Mailgun, etc)
  email = params[:email]
  
  OrderEmail.where(email: email).update_all(
    status: 'bounced',
    bounce_reason: params[:bounce_reason]
  )
  
  # Исключить из CRM рассылок
  User.find_by_email(email)&.update(excluded_from_crm: true)
  
  render json: { status: 'processed' }
end
```

**Логика**:
- Email помечается как `bounced`
- Исключается из CRM очереди при следующей синхронизации
- Пользователю НЕ показывается повторный запрос

**Webhook Security**:
- Провайдер должен подписывать webhook (HMAC/signature)
- Проверить подпись перед обработкой

**Тест**:
```ruby
# RED: test "bounce маркирует email как невалидный"
# GREEN: OrderEmail.status == 'bounced'
```

---

### SUBTASK 12: Предзаполнять email для повторного заказа

**Файл**: `app/frontend/routes/PaymentResult.svelte`

```javascript
onMount(async () => {
  // ... existing code
  
  // Загрузить последний email пользователя
  const profile = await api("profile")
  if (profile?.email) {
    prefilledEmail = profile.email
  }
})
```

**Логика**:
- При загрузке экрана: проверить profile.email
- Если есть: предзаполнить в OrderSuccessEmailBlock
- User может изменить или удалить значение

**Тест**:
```javascript
// RED: test "email предзаполнен из профиля"
// GREEN: input.value == profile.email
```

---

### SUBTASK 13: Разрешить изменение и удаление сохранённого email

**Файл**: `app/frontend/components/OrderSuccessEmailBlock.svelte`

**Поведение**:
- User может изменить любое символ в email
- User может очистить поле полностью
- Кнопка "Отправить" работает при измененном email
- Нет блокировки на изменение

**Тест**:
```javascript
// RED: test "user может удалить email из предзаполненного поля"
// GREEN: можно отправить пусто или новое значение
```

---

### SUBTASK 14: Обеспечить идемпотентность повторного сохранения

**Файл**: `app/models/order_email.rb`

```ruby
class OrderEmail < ApplicationRecord
  belongs_to :order
  
  validates :email, uniqueness: { scope: :order_id }
end
```

**Логика**:
- Один email на один заказ (unique constraint)
- Повторное сохранение: UPDATE не CREATE
- API возвращает успех в обоих случаях

**Тест**:
```ruby
# RED: test "повторное сохранение не создаёт дубликаты"
# GREEN: OrderEmail.count == 1 после двух запросов
```

---

### SUBTASK 15: Проверить независимость кассового чека от email

**Файл**: существующая логика оформления заказа

**Проверить**:
- Кассовый чек формируется БЕЗ email
- Чек доступен через кассовую систему / ОФД
- Email опционален для чека

**Тест**:
```ruby
# RED: test "кассовый чек формируется без email"
# GREEN: Receipt.find(order_id).present? even when email.blank?
```

---

### SUBTASK 16: Покрыть frontend тестами

**Файлы**:
- `app/frontend/routes/PaymentResult.test.ts`
- `app/frontend/components/OrderSuccessEmailBlock.test.ts`
- `app/frontend/lib/emailCollection.test.ts`

**Критические сценарии**:
1. Email-блок НЕ видна при status!=ok
2. Email-блок видна при status=ok
3. Email невалидный → inline error
4. Email валидный → можно отправить
5. Маркетинг-согласие опциональное
6. API вызвана с корректными параметрами
7. Навигация работает БЕЗ email

---

### SUBTASK 17: Покрыть backend тестами

**Файл**: `spec/requests/shop/api/orders/email_spec.rb`

**Критические сценарии**:
1. POST с корректным email → 200 OK
2. POST с невалидным email → 400 Bad Request
3. POST без email (пусто) → 200 OK (опциональный)
4. POST с marketing_consent=true → CRM job enqueued
5. POST с marketing_consent=false → CRM job НЕ enqueued
6. Receipt email job enqueued
7. Идемпотентность: два запроса → одна OrderEmail

---

### SUBTASK 18: Проверить UX-копирайт и итоговый flow

**Макет экрана успеха**:
```
┌─────────────────────────────────┐
│ ✅ Заказ #123 успешно оплачен   │
│                                 │
│ 📋 Статус: Готовится к оформлению
│                                 │
│ 📧 Куда прислать чек и          │
│    предложения                  │
│                                 │
│ [Email field placeholder]       │
│                                 │
│ ☐ Отправляйте мне предложения  │
│   и новости                     │
│                                 │
│ [Отправить] [Пропустить]        │
└─────────────────────────────────┘
```

**Копирайт**:
- "Куда прислать чек..." → описывает пользу
- "Отправляйте..." → маркетинг-согласие
- Нет слова "обязательно"

---

### SUBTASK 19: TDD RED-фаза (фронт + бэк)

**Все 18 subtasks имеют RED тесты**:
- 58 фронт-тестов (Vitest/Jest)
- 12 бэк-тестов (RSpec)
- Все используют `assert.fail()` или `skip`

---

### SUBTASK 20: TDD GREEN-фаза, typecheck & lint

После всех изменений:
```bash
npm test -- src/**/*.test.ts         # ✅ GREEN
npx tsc --noEmit                      # ✅ 0 errors
bundle exec rspec spec/requests...   # ✅ GREEN
```

---

## 3. API Контракты (Final)

### Frontend → Backend

#### POST /shop/api/orders/:id/email

**Route** (in `config/routes.rb`):
```ruby
post '/orders/:order_id/email', to: 'shop/api/orders/email#create'
```

**Request**:
```json
{
  "email": "user@example.com",
  "marketing_consent": true
}
```

**Response 200**:
```json
{
  "success": true,
  "email": "user@example.com",
  "email_status": "pending",
  "queued_receipt": true,
  "queued_crm": true
}
```

**Response 400**:
```json
{
  "success": false,
  "error": "invalid_email",
  "message": "Email format is invalid"
}
```

---

## 4. Email Provider Integration

### Webhook Endpoint

**Path**: `POST /webhooks/email_events`

**Event Types**:
- `bounce`: email не доставлен
- `complaint`: спам-жалоба
- `delivered`: успешно доставлен

**Payload (example - SendGrid)**:
```json
{
  "event": "bounce",
  "email": "user@example.com",
  "bounce_type": "permanent",
  "reason": "550 5.1.1 unknown user"
}
```

**Security**: HMAC-SHA256 подпись в headers

---

## 5. CRM Integration Queue

### Job: SyncContactToCrmJob

```ruby
SyncContactToCrmJob.perform_later(
  order_id: 123,
  email: "user@example.com",
  marketing_consent: true
)
```

**Логика**:
- Преобразовать контакт в CRM формат
- Отправить в CRM API или очередь
- Retry при ошибке (через Sidekiq policy)

---

## 6. Database Schema

### Migrations

#### OrderEmail table

```ruby
create_table :order_emails do |t|
  t.references :order, foreign_key: true
  t.string :email
  t.boolean :marketing_consent, default: false
  t.string :status, default: 'pending' # pending, sent, bounced, complained
  t.string :bounce_reason
  t.datetime :sent_at
  t.datetime :bounced_at
  
  t.timestamps
  t.index [:order_id, :email], unique: true
end
```

---

## 7. Environment Variables

```bash
# Email Provider (SendGrid, Mailgun, etc)
EMAIL_PROVIDER_API_KEY=sg_...
EMAIL_PROVIDER_WEBHOOK_SECRET=...
EMAIL_SENDER_ADDRESS=noreply@coffeeos.ru

# CRM (Pipedrive, HubSpot, etc)
CRM_API_KEY=...
CRM_WEBHOOK_SECRET=...
CRM_CONTACT_ENDPOINT=...
```

---

## 8. Файлы для Тестирования

### Frontend Tests

```typescript
// emailValidation.test.ts
test('valid email', () => {
  expect(isValidEmail('user@example.com')).toBe(true)
})

test('invalid email', () => {
  expect(isValidEmail('invalid@')).toBe(false)
})
```

### Backend Tests

```ruby
# spec/requests/shop/api/orders/email_spec.rb
describe 'POST /shop/api/orders/:order_id/email' do
  it 'saves email without OTP' do
    post "/shop/api/orders/#{order.id}/email", 
         params: { email: 'user@example.com', marketing_consent: true }
    expect(order.order_email.email).to eq('user@example.com')
  end
end
```

---

## 9. Файл-по-файлу Чеклист

### Frontend

- [ ] Checkout.svelte — удалить email-гейт
- [ ] PaymentResult.svelte — добавить email-блок
- [ ] OrderSuccessEmailBlock.svelte — новый компонент (email + marketing)
- [ ] emailCollection.js — API + логика валидации
- [ ] NewCardForm.svelte — toggle сохранения карты
- [ ] emailValidation.test.ts — тесты валидации
- [ ] OrderSuccessEmailBlock.test.ts — тесты компонента
- [ ] PaymentResult.test.ts — тесты экрана успеха

### Backend

- [ ] email_controller.rb — POST endpoint
- [ ] email_service.rb — сохранение + очередь
- [ ] send_order_receipt_email_job.rb — async отправка чека
- [ ] sync_contact_to_crm_job.rb — отправка в CRM
- [ ] order_email.rb — Model
- [ ] order.rb — associations + validations
- [ ] email_webhook_controller.rb — bounce обработка
- [ ] OrderReceiptMailer — шаблон чека
- [ ] routes.rb — новый endpoint
- [ ] migration для order_emails table
- [ ] email_spec.rb — API тесты
- [ ] send_order_receipt_email_job_spec.rb
- [ ] sync_contact_to_crm_job_spec.rb

---

## 10. Exit Criteria (PHASE 1 → PHASE 2)

- [ ] Все 20 subtasks разбиты на RED tests
- [ ] Файл-структура определена
- [ ] API контракты документированы
- [ ] Database schema определена
- [ ] Email-провайдер интеграция уточнена
- [ ] CRM интеграция уточнена
- [ ] Маркетинг-согласие policy определена
- [ ] Готово к RED/GREEN фазе

---

**PHASE 1 READY**: Спецификация завершена
