# todo — TASK-PERSONAL-CABINET: Доработка личного кабинета в PWA

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 0: Intake | PHASE 1: SPEC | PHASE 2: BUILD (RED) |

**CBR:** TASK-PERSONAL-CABINET  
**ТЗ:** [`customer_tasks/TASK-PERSONAL-CABINET.md`](../milestones/veha_2/requirements/customer_tasks/TASK-PERSONAL-CABINET.md)  
**Детали PHASE 0-1:** [`TASK-PERSONAL-CABINET-PHASE0-1.md`](./TASK-PERSONAL-CABINET-PHASE0-1.md)

---

## Цель (1 предложение)

Завершить пользовательский сценарий личного кабинета в PWA: просмотр истории заказов, просмотр деталей заказа, управление профилем и контактами, переход к информации о приложении, UI и UX по макетам без самостоятельного изобретения паттернов.

---

## Acceptance Criteria (31 subtask) — сводка критических

### Главный экран ЛК (subtasks 1-8)
- [ ] Маршрут и экран главного ЛК
- [ ] Шапка с аватаром и именем пользователя
- [ ] Контейнер PLG-блоков (без логики)
- [ ] Загрузка истории заказов по API
- [ ] Отображение элемента истории
- [ ] Обработка пустой истории
- [ ] Обработка ошибки загрузки

### Деталь заказа (subtasks 9-13)
- [ ] Маршрут экрана деталей
- [ ] Структура экрана (дата, товары, суммы)
- [ ] Визуальное состояние без ОФД
- [ ] Кнопка ПОВТОРИТЬ (no logic)
- [ ] Запрет на ОФД-интеграцию в коде

### Профиль/Настройки (subtasks 14-24)
- [ ] Экран профиля с формой
- [ ] Редактирование имени + сохранение
- [ ] Тумблер уведомлений
- [ ] Блок контактов (email, телефон)
- [ ] Подтверждение email
- [ ] Подтверждение телефона
- [ ] Bottom sheet «Написать нам» (Telegram + Email)
- [ ] Переход в Telegram-бота (уже сделан в TASK-TELEGRAM-SUPPORT)
- [ ] Email-сценарий обратной связи
- [ ] Logout

### Экран «О нас» (subtasks 25-29)
- [ ] Версия и build-код
- [ ] Копирование информации
- [ ] Конфигурация URL
- [ ] Все ссылки (политика, оферта, прочие)
- [ ] Footer (копирайт, email)

### Финальная проверка (subtasks 30-31)
- [ ] Соответствие UI макетам
- [ ] Отсутствие ОФД, PLG-логики, подписки

---

## Файлы (ожидаемо) — 15–20 путей

### Маршруты
1. `app/frontend/routes/personal-account/+page.svelte` (или `/profile/+page.svelte`)
2. `app/frontend/routes/personal-account/orders/+page.svelte` (история)
3. `app/frontend/routes/personal-account/orders/[orderId]/+page.svelte` (деталь)
4. `app/frontend/routes/personal-account/settings/+page.svelte` (профиль)
5. `app/frontend/routes/personal-account/about/+page.svelte` (о нас)

### Компоненты
6. `app/frontend/components/PersonalAccount/PersonalAccountHeader.svelte`
7. `app/frontend/components/PersonalAccount/OrderHistory.svelte`
8. `app/frontend/components/PersonalAccount/OrderHistoryItem.svelte`
9. `app/frontend/components/PersonalAccount/PLGContainer.svelte`
10. `app/frontend/components/Profile/ProfileForm.svelte`
11. `app/frontend/components/Profile/NotificationToggle.svelte`
12. `app/frontend/components/Profile/ContactsBlock.svelte`
13. `app/frontend/components/OrderDetail/OrderHeader.svelte`
14. `app/frontend/components/OrderDetail/OrderItems.svelte`
15. `app/frontend/components/OrderDetail/RepeatButton.svelte`
16. `app/frontend/components/About/AppInfo.svelte`
17. `app/frontend/components/About/CopyButton.svelte`
18. `app/frontend/components/About/InfoLinks.svelte`
19. `app/frontend/components/About/Footer.svelte`

### Конфигурация & API
20. `app/frontend/lib/config/aboutLinks.js` (конфигурация URL)
21. `app/frontend/lib/api/orders.js` (запросы истории и деталей)
22. `app/frontend/lib/api/profile.js` (запросы профиля)
23. `app/frontend/lib/api/contacts.js` (подтверждение email/phone)

### Тесты
24. `test/integration/TASK-PERSONAL-CABINET.test.ts` (интеграционные)

### Уже созданы (из TASK-TELEGRAM-SUPPORT)
- `app/frontend/components/SupportContactSheet.svelte`
- `app/frontend/lib/supportConfig.js`
- `app/frontend/lib/deepLink.js`

---

## Blast-radius (+3–4)

- **`app/frontend/components/Header.svelte`** — *уже изменен для TASK-TELEGRAM-SUPPORT (иконка чата)*
- **`app/frontend/routes/Profile.svelte`** — *уже изменен для TASK-TELEGRAM-SUPPORT (кнопка "Написать нам")*
- **Существующие bottom sheets** — *паттерн изучения*
- **`app/frontend/lib/config/` или константы** — *интеграция с аутентификацией и состоянием пользователя*

---

## Не ломать (ФИКСИРОВАНО)

- ✅ Auth: login/logout механизм
- ✅ Routing: существующие маршруты PWA
- ✅ Orders: существующая система заказов (только чтение для истории и деталей)
- ✅ Payments: платежные сценарии и checkout
- ✅ ОФД: интеграция банка остается нетронутой
- ✅ PLG-механизм: только контейнер конфигурации, БЕЗ логики
- ✅ Notification/Push: существующий механизм
- ✅ Bottom Sheet паттерн: CartSheet, PaymentMethodsSheet работают
- ✅ Telegram/Instagram WebView: нет изменений

---

## Проверка

```bash
# Unit-тесты
npm test test/integration/TASK-PERSONAL-CABINET.test.ts

# Type check
npx tsc --noEmit

# Production build
npm run build

# Ручная проверка
# - Desktop: все экраны по макетам
# - Mobile: responsive, bottom sheets, deep links
# - Devices: с Telegram и без
# - API: все запросы согласованы
```

---

## Риски / заметки

1. **Backend-контракты БЛОКИРУЮТ**: нужно согласовать API истории, профиля, контактов
2. **Пути файлов**: зависят от существующей структуры (app/frontend vs src)
3. **Состояние пользователя**: нужно интегрировать с существующим auth-store
4. **Конфигурация URL**: единая точка в `config/aboutLinks.js`
5. **ОФД**: строго запрещено, но убедиться в коде что нет импортов
6. **PLG-контейнер**: должен быть пуст и принимать конфигурацию (не render контент)
7. **Макеты**: артефакты в `personal_cabinet_lk_mockups/` — источник истины

---

## PHASE 0 ✅ (Completed)

- ✅ Требования документированы
- ✅ Макеты артефакты созданы
- ✅ Открытые вопросы определены
- ✅ Структура файлов спланирована

## PHASE 1 📋 (In Progress)

- 📋 Анализ существующей структуры (app/frontend пути)
- 📋 Согласование backend-контрактов (API)
- 📋 Подготовка RED-тестов (TDD)
- 📋 Детализация компонентов и зависимостей

## PHASE 2 ⏳ (Pending)

- ⏳ BUILD: RED (тесты упадут)
- ⏳ BUILD: GREEN (реализация)

## PHASE 3 ⏳ (Pending)

- ⏳ REVIEW: CI green
- ⏳ REVIEW: Security scan
- ⏳ REVIEW: Целая пояснительная записка
- ⏳ PUSH: git push develop

---

**Дата начала PHASE 0**: 2026-08-19  
**Статус**: PHASE 0 завершена, PHASE 1 активна  
**Блокер**: Backend-контракты (требуют clarification)
