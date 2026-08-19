# todo — TASK-TELEGRAM-SUPPORT: Связь через Telegram-бота поддержки в ЛК

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| PHASE 0: Intake | PHASE 1: SPEC | PHASE 2: BUILD (RED) при намерении работать |

**CBR:** TASK-TELEGRAM-SUPPORT  
**ТЗ:** [`customer_tasks/TASK-TELEGRAM-SUPPORT.md`](../milestones/veha_2/requirements/customer_tasks/TASK-TELEGRAM-SUPPORT.md)

---

## Цель (1 предложение)

Добавить в личный кабинет PWA канал связи с поддержкой через Telegram-бота из двух точек входа (иконка чата в шапке ЛК и кнопка «Написать нам» в профиле), используя deep link без передачи пользовательских данных.

---

## Acceptance Criteria (12 пунктов)

- [ ] Иконка-чата на главном экране ЛК открывает bottom sheet с вариантами Email/Telegram
- [ ] Кнопка «Написать нам» на экране профиля открывает такой же bottom sheet
- [ ] Выбор Telegram из любой точки открывает `https://t.me/code_black_support_bot`
- [ ] Telegram-ссылка не содержит пользовательских или заказных параметров
- [ ] Встроенный Telegram Web App/iframe не используется
- [ ] На мобильном устройстве deep link передается нативному Telegram при его наличии
- [ ] На desktop проверено открытие Telegram Web в новой вкладке
- [ ] Email-канал не реализуется в рамках этой задачи
- [ ] Профиль пользователя продолжает работать без изменений
- [ ] История заказов не затрагивается
- [ ] Авторизация и logout не меняются
- [ ] Регрессия: bottom sheet, header, profile работают корректно

---

## Файлы (ожидаемо) — 2–7 путей

### Основные
1. **`app/frontend/components/Header.svelte`** — иконка-чата в шапке главного экрана ЛК + обработчик клика
2. **`app/frontend/routes/Profile.svelte`** — кнопка «Написать нам» + обработчик клика
3. **`app/frontend/components/SupportContactSheet.svelte`** — **новый** компонент bottom sheet с вариантами Email/Telegram

### Конфигурация & вспомогательные
4. **`app/frontend/lib/config.js` или `constants.js`** — конфигурация URL поддержки `SUPPORT_TELEGRAM_BOT_URL`
5. **`app/frontend/lib/deepLink.js` или `utils/deepLink.js`** — **новый** или расширить: утилита открытия deep link (без параметров пользователя)

### Тесты
6. **`test/javascript/telegram_support_test.mjs`** — **новый**: unit-тесты deep link, конфиг, компонент открытия
7. **`test/integration/telegram_support_integration_test.mjs`** — **новый**: интеграционные тесты открытия шторки из Header и Profile

---

## Blast-radius (+1–2)

- **`app/frontend/components/CartSheet.svelte` / другие Bottom Sheet компоненты** — *почему: необходимо изучить паттерн существующих шторок для единообразия UI/UX*
- **`app/frontend/lib/stores/`** — *почему: может потребоваться store для состояния шторки поддержки (open/close)*

---

## Не ломать

- Header: иконки, логотип, навигация, мобильный/desktop layout
- Profile: форма профиля, avatar, кнопки logout, выход, история заказов
- Bottom Sheet паттерн: существующие шторки (CartSheet, PaymentMethodsSheet, OrderStatusSheet) продолжают работать
- Авторизация: login/logout не меняются
- Интеграция email (на будущее) — не реализуется, но структура допускает расширение

---

## Проверка

```bash
# Юнит-тесты
npm test test/javascript/telegram_support_test.mjs

# Интеграционные тесты (если есть)
npm test test/javascript/telegram_support_integration_test.mjs

# Type check
npx tsc --noEmit

# Мобильный (ручной): Chrome DevTools, установленный Telegram + без Telegram
# Desktop (ручной): Chrome, Firefox
```

**Ручная проверка:**
- Мобильный браузер + установленный Telegram: deep link передается нативному клиенту
- Мобильный браузер без Telegram: открывается Telegram Web
- Desktop браузер: Telegram Web в новой вкладке
- Проверить URL в DevTools — **без user_id, phone, order_id**

---

## Риски / заметки

- Deep link в браузере зависит от ОС и браузера — не гарантировать одинаковое поведение везде, но документировать
- Конфигурация URL должна быть единой точкой — `SUPPORT_TELEGRAM_BOT_URL` в одном файле
- Bottom Sheet должна закрываться по свайпу и по клику вне (паттерн, как в CartSheet)
- Email вариант: оставить disabled или как визуальный элемент без обработчика (для будущей реализации)
- Не трогать `shopWebView.js`, `shopWebViewLayout.js` (#67, #66) и прочие компоненты витрины

---

## Фазы SBR

- [x] PHASE 0: Intake — создан файл задачи в customer_tasks/
- [x] PHASE 1: SPEC — анализ файлов, todo.md, шапка SESSION_STATE
- [ ] PHASE 2: RED — написание тестов (падающие)
- [ ] PHASE 2: GREEN — реализация + регрессия
- [ ] PHASE 3: REVIEW — local тесты, bugbot, security-review, push CI, deploy

---

## Subtask'и TDD (чек-лист)

- [ ] **Subtask 1:** Подключить Telegram-ссылку через конфигурацию (SUPPORT_TELEGRAM_BOT_URL)
- [ ] **Subtask 2:** Реализовать открытие шторки из иконки-чата в Header
- [ ] **Subtask 3:** Реализовать Telegram-вариант в шторке главного экрана
- [ ] **Subtask 4:** Сохранить email-вариант без реализации (disabled/placeholder)
- [ ] **Subtask 5:** Реализовать открытие шторки из Profile кнопки «Написать нам»
- [ ] **Subtask 6:** Реализовать Telegram-вариант в шторке Profile
- [ ] **Subtask 7:** Исключить встроенный Telegram Web App / iframe
- [ ] **Subtask 8:** Проверить мобильный deep link (с Telegram и без)
- [ ] **Subtask 9:** Проверить desktop deep link
- [ ] **Subtask 10:** Проверить отсутствие контекстных параметров в URL
- [ ] **Subtask 11:** Проверить единообразие двух точек входа (шапка & профиль)
- [ ] **Subtask 12:** Регрессионная проверка ЛК (профиль, заказы, logout)
