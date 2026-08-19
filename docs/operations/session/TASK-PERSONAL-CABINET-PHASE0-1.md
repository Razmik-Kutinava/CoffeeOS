# TASK-PERSONAL-CABINET: PHASE 0 + PHASE 1 (INTAKE & SPEC)

| Phase | Status | Current |
|-------|--------|---------|
| **PHASE 0** | ✅ DONE | Intake, требования, макеты, артефакты |
| **PHASE 1** | 📋 ACTIVE | SPEC: анализ файлов, структура, TDD setup |
| **PHASE 2** | ⏳ PENDING | BUILD: RED (тесты), GREEN (реализация) |
| **PHASE 3** | ⏳ PENDING | REVIEW: CI, security, целая пояснительная записка, PUSH |

---

## PHASE 0: INTAKE (ЗАВЕРШЕНО)

### Входящие материалы
- ✅ Полное описание требований (31 subtask)
- ✅ UI/UX макеты (screenshot приложен)
- ✅ Бизнес-цель: завершить сценарий личного кабинета в PWA
- ✅ Scope: история заказов, профиль, о приложении, без ОФД, без PLG-логики

### Документация создана
- ✅ `docs/operations/milestones/veha_2/requirements/customer_tasks/TASK-PERSONAL-CABINET.md`
- ✅ `docs/operations/milestones/veha_2/artifacts/personal_cabinet_lk_mockups/README.md`
- ✅ Папка артефактов с местом для скриншотов

### Ключевые ограничения (ФИКСИРОВАНЫ)
1. **Новые интеграции**: НЕТ
2. **ОФД интеграция**: ЗАПРЕЩЕНА
3. **PLG-логика**: ЗАПРЕЩЕНА (только контейнер конфигурации)
4. **Backend-контракты**: Требуют уточнения (открытые вопросы)
5. **Смежные модули**: Auth, routing, orders, payments НЕ ЛОМАТЬ

### Макеты и UI-компоненты
- Главный экран ЛК (шапка + PLG-контейнеры + история заказов)
- Деталь заказа (продукты, суммы, кнопка повтора)
- Профиль/настройки (имя, уведомления, контакты, logout)
- Экран «О нас» (версия, ссылки из конфигурации, footer)
- Bottom sheet «Написать нам» (Telegram + Email)

---

## PHASE 1: SPEC (В ПРОЦЕССЕ)

### 1.1 Анализ структуры репозитория

**Что проверить:**
```bash
# Структура фронтенда
find app/frontend -type d -name "routes" -o -name "components" | head -20
find app/frontend -name "*profile*" -o -name "*account*" -o -name "*personal*"

# Существующие bottom sheets
find app/frontend/components -name "*Sheet.svelte"

# Конфигурация
find app/frontend -name "config*" -o -name "constants*" | head -10

# Тесты
find test -name "*.test.*" -o -name "*test.mjs" | head -10
```

**Найти и изучить:**
- [ ] Существующий маршрут профиля (Profile.svelte)
- [ ] Паттерн bottom sheet (CartSheet, PaymentMethodsSheet и др.)
- [ ] Структура конфигурации (где хранятся URL, константы)
- [ ] Существующие тесты для компонентов
- [ ] Структура API-запросов и обработки ошибок

### 1.2 Определить Backend-контракты (Blocker)

**Открытые вопросы, требующие clarification от backend:**

1. **API истории заказов**
   - Endpoint URL: `/api/orders` ? `/api/user/orders` ?
   - Метод: GET, POST ?
   - Request параметры: pagination, filter ?
   - Response format:
     ```json
     {
       "orders": [
         {
           "id": "string | number",
           "title": "string",
           "date": "ISO8601",
           "total": "number",
           "status": "string"
         }
       ],
       "pagination": { "total": "number", "page": "number" }
     }
     ```

2. **API изменения профиля (имя)**
   - Endpoint: PUT `/api/user/profile` или PATCH ?
   - Request:
     ```json
     { "name": "string" }
     ```
   - Response: { "success": true, "user": { ... } }

3. **Уведомления (тумблер)**
   - Какой параметр отвечает за "уведомления"? (all, email, push, sms ?)
   - Endpoint и механизм сохранения состояния?

4. **Подтверждение email**
   - POST `/api/email/verify/request` → получить код или ссылку ?
   - POST `/api/email/verify/confirm?code=...` ?

5. **Подтверждение телефона**
   - POST `/api/phone/verify/request` → SMS с кодом ?
   - POST `/api/phone/verify/confirm?code=...` ?

6. **Logout**
   - Существующий механизм: какой файл, какая функция?
   - Где вызывается? (`src/auth/logout.ts` ?)
   - Целевой экран после logout?

7. **Email для «Написать нам»**
   - Email получателя для обратной связи (конфиг или backend)?
   - Механизм отправки: mailto: или API ?

### 1.3 Файлы и модули к созданию/изменению

**Структура (предварительная):**

```
app/frontend/
├── routes/
│   ├── profile/
│   │   ├── +page.svelte (или +layout ?)
│   │   ├── orders/
│   │   │   ├── +page.svelte (история)
│   │   │   └── [orderId]/
│   │   │       └── +page.svelte (деталь)
│   │   └── about/
│   │       └── +page.svelte
│   └── [остальное...]
├── components/
│   ├── PersonalAccount/
│   │   ├── PersonalAccountHeader.svelte
│   │   ├── OrderHistory.svelte
│   │   ├── OrderHistoryItem.svelte
│   │   └── PLGContainer.svelte
│   ├── Profile/
│   │   ├── ProfileForm.svelte
│   │   ├── NotificationToggle.svelte
│   │   └── ContactsBlock.svelte
│   ├── About/
│   │   ├── AppInfo.svelte
│   │   ├── CopyButton.svelte
│   │   ├── InfoLinks.svelte
│   │   └── Footer.svelte
│   ├── OrderDetail/
│   │   ├── OrderHeader.svelte
│   │   ├── OrderItems.svelte
│   │   └── RepeatButton.svelte
│   └── [существующие]: SupportContactSheet.svelte (уже создан)
├── lib/
│   ├── config/
│   │   ├── aboutLinks.js (конфигурация)
│   │   └── supportContacts.js (уже создан)
│   ├── api/
│   │   ├── orders.js (запросы истории и деталей)
│   │   ├── profile.js (запросы профиля)
│   │   └── contacts.js (подтверждение email/phone)
│   └── [остальное...]
└── ...

test/
├── integration/
│   └── TASK-PERSONAL-CABINET.test.ts (интеграционные тесты)
└── ...
```

### 1.4 TDD Setup: Тесты и требования

**RED-phase тесты (упадут):**

Структура теста (примерно):
```javascript
describe('TASK-PERSONAL-CABINET', () => {
  describe('Экран главного ЛК', () => {
    it('отображает аватар и имя пользователя', () => {
      // Test: PersonalAccountHeader содержит user.name и avatar
    });
    it('загружает историю заказов по API', () => {
      // Test: запрос к /api/orders, отображение элементов
    });
    it('обрабатывает пустую историю', () => {
      // Test: EmptyState когда orders.length === 0
    });
  });
  
  describe('Экран деталей заказа', () => {
    it('отображает продукты и сумму', () => {
      // Test: OrderDetail компонент рендерит items, total
    });
    it('кнопка ПОВТОРИТЬ есть но не функциональна', () => {
      // Test: RepeatButton присутствует, обработчик empty или stub
    });
  });
  
  describe('Профиль', () => {
    it('сохраняет измененное имя', () => {
      // Test: ProfileForm изменение + PUT /api/user/profile
    });
    it('управляет уведомлениями', () => {
      // Test: NotificationToggle toggle state, запрос к API
    });
    it('отправляет запрос подтверждения email', () => {
      // Test: ContactsBlock кнопка подтверждения → POST /api/email/verify/request
    });
  });
  
  describe('О нас', () => {
    it('копирует версию приложения', () => {
      // Test: AppInfo copyButton → clipboard API
    });
    it('загружает ссылки из конфигурации', () => {
      // Test: InfoLinks берут URL из config/aboutLinks.js
    });
  });
});
```

### 1.5 Проверка регрессии (Regression tests)

**Не ломать (тесты):**
- ✅ Auth: login/logout работают
- ✅ Header: логотип, навигация, иконки
- ✅ Existing Profile: если уже есть
- ✅ Orders: существующая система заказов не затронута
- ✅ Bottom Sheets: CartSheet, PaymentMethodsSheet продолжают работать

---

## READY для PHASE 2?

**Чек-лист перед PHASE 2 (BUILD/RED):**

- [ ] Backend-контракты согласованы и документированы
- [ ] Структура файлов определена и согласована
- [ ] Макеты артефактов сохранены в `personal_cabinet_lk_mockups/screenshots/`
- [ ] Уточнены пути к файлам в структуре проекта (app/frontend vs src, и т.д.)
- [ ] Определены существующие компоненты для повторного использования
- [ ] Тестовая структура подготовлена (краткий RED-фреймворк)

**Когда будет ready:**
- Backend подтвердит все API-контракты
- Уточнятся пути в файловой структуре
- Будут готовы скриншоты/макеты в папке артефактов

---

## Команды для PHASE 1

```bash
# Проверка структуры
find app/frontend/routes -type f -name "*.svelte" | grep -i profile
find app/frontend/components -name "*Sheet.svelte" -o -name "*Header.svelte"

# Проверка конфигурации
grep -r "config\|constants" app/frontend/lib --include="*.js" | head -10

# Проверка тестов
find test -name "*.test.*" -o -name "*test.mjs" | head -10

# Type check
npx tsc --noEmit

# Просмотр зависимостей в package.json
grep -A5 -B5 "svelte\|vitest\|playwright" package.json
```

---

## Статус: PHASE 1 (SPEC & ANALYSIS)

**Дата начала**: 2026-08-19  
**Ожидаемое завершение**: когда backend-контракты согласованы  
**Блокеры**: API-контракты
