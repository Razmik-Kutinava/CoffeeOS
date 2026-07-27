# Интеграция Т-Кассы (СБП + Токенизация) в PWA CODE:BLACK

**Дата интейка:** 2026-07-27
**Источник:** текст заказчика (передан владельцем в чат)
**Артефакты:** docs/operations/milestones/veha_2/artifacts/codeblack_t_kassa_sbp_tokenization/
**Связь с v2:** предшествующий эпик — [`Интеграция оплаты СБП Deep Link и токенизации карт Т-Касса v2.md`](Интеграция%20оплаты%20СБП%20Deep%20Link%20и%20токенизации%20карт%20Т-Касса%20v2.md) (бэкенд Init/GetQr/webhook/UI SBP на Fly v394). Это **ревизия** с акцентом на PWA lifecycle.

---

## Текст заказчика (дословно)

# Интеграция Т-Кассы (СБП + Токенизация) в PWA CODE:BLACK

Бизнес-цель: Реализация кастомного платежного слоя без использования стандартных виджетов/iframe для сохранения строгой темной минималистичной (терминальной) эстетики. Обеспечение оплаты в 2 тапа (СБП) и в 1 тап (RebillId) с бесшовным восстановлением сессии PWA после редиректа в нативное банковское приложение.

## Глобальные ограничения
- Запрещено использовать стандартные iframe или готовые UI-виджеты Т-Банка/Т-Кассы.
- Запрещено отступать от глобальной цветовой схемы: строгая темная тема, монохром, моноширинный шрифт для технических элементов.
- Обязательна валидация SHA-256 подписи (Token) для всех входящих webhook и исходящих запросов к API Т-Кассы.
- Запрещено хранение чувствительных платежных данных на клиенте (только `orderId`, `timestamp` и маскированный `RebillId`).

## Сценарии и чек-лист (Для todo.md)

### 1. Backend: Инициация СБП (Динамический Deep Link)
- [ ] Шаг 1.1: Реализовать `POST /api/v1/payments/sbp/init`
  - Given: Валидный `orderId` и данные пользователя.
  - When: Отправлен запрос с payload `{ orderId: string }`.
  - Then: Бэкенд вызывает `/v2/Init` (Amount в копейках, OrderId, CustomerKey, Receipt с массивом Items по 54-ФЗ). Получает `PaymentId`. Вызывает `/v2/GetQr` с `{ PaymentId, DataType: "PAYMENT_LINK" }`. Возвращает `{ success: true, paymentUrl: "https://qr.nspk.ru/...", orderId }`. Обрабатывает 400/500 ошибки от Т-Кассы.

### 2. Backend: Токенизация и повторные списания
- [ ] Шаг 2.1: Реализовать `POST /api/v1/payments/card/init`
  - Given: Валидный `orderId` и `CustomerKey`.
  - When: Отправлен запрос с payload `{ orderId: string }`.
  - Then: Бэкенд вызывает `/v2/Init` с параметром `Recurrent: "Y"`. Возвращает `PaymentURL` для первичного ввода карты.
- [ ] Шаг 2.2: Реализовать `POST /api/v1/payments/charge-recurrent`
  - Given: Сохраненный `RebillId` у пользователя.
  - When: Отправлен запрос с payload `{ orderId: string, rebillId: string }`.
  - Then: Бэкенд вызывает `/v2/Init`, затем `/v2/Charge` с `PaymentId` и `RebillId`. Списание происходит без участия UI. Возвращает результат операции.

### 3. Backend: Webhook и статусы
- [ ] Шаг 3.1: Реализовать обработчик `POST /api/v1/payments/webhook`
  - Given: Входящий запрос от Т-Банка.
  - When: Получен payload с параметрами платежа.
  - Then: Валидируется SHA-256 подпись (Token). При статусе `CONFIRMED`: статус заказа в БД меняется на `PAID`, `RebillId` сохраняется в профиле пользователя, отправляется событие успеха через WebSocket / Long Polling.
- [ ] Шаг 3.2: Реализовать `GET /api/v1/payments/status/:orderId`
  - Given: Существующий `orderId`.
  - When: Запрошен статус.
  - Then: Возвращается `{ status: "PENDING" | "CONFIRMED" | "REJECTED" | "CANCELED" }`.

### 4. Frontend: PWA Lifecycle и State Management
- [ ] Шаг 4.1: Реализовать сохранение состояния перед редиректом
  - Given: Пользователь нажимает кнопку оплаты СБП.
  - When: Получен `paymentUrl` от бэкенда.
  - Then: В `localStorage` записывается `codeblack_pending_order` (`{ orderId, timestamp: Date.now() }`). UI переводится в статус `WAITING_FOR_BANK`. Выполняется `window.location.href = paymentUrl`.
- [ ] Шаг 4.2: Реализовать обработку возврата через `visibilitychange`
  - Given: Приложение было скрыто (уход в банк) и `codeblack_pending_order` существует.
  - When: `document.visibilityState === 'visible'`.
  - Then: Вызывается `checkOrderStatus(orderId)`. При финальном статусе (`CONFIRMED`/`REJECTED`) ключ `codeblack_pending_order` удаляется из `localStorage`.
- [ ] Шаг 4.3: Реализовать восстановление при холодном старте
  - Given: Инициализация PWA.
  - When: Приложение загружается.
  - Then: Проверяется `codeblack_pending_order`. Если `Date.now() - timestamp < 15 минут`, автоматически запрашивается `/api/v1/payments/status/:orderId` и рендерится соответствующий экран (Успех / Ошибка / Повтор оплаты).

### 5. Frontend: UI/UX компоненты (Стиль CODE:BLACK)
- [ ] Шаг 5.1: Реализовать экран чекаута
  - Given: Корзина оформлена.
  - When: Рендерится экран оплаты.
  - Then: Отображается кнопка `[ ОПЛАТИТЬ БЫСТРО (СБП) ]` (вызывает флоу СБП). Отображается запасная кнопка `Картой любого банка или сохраненная карта •••• 1234`. Если есть `RebillId`, активируется быстрый чек-аут в 1 тап.
- [ ] Шаг 5.2: Реализовать экран ожидания возврата из банка
  - Given: Статус `WAITING_FOR_BANK`.
  - When: Рендерится экран ожидания.
  - Then: Отображается текст "Завершите оплату в приложении банка и вернитесь в приложение". Присутствует вспомогательная кнопка `[ Я оплатил ]`, принудительно вызывающая `checkOrderStatus`.

## Стратегия тестирования
- Фреймворк: Jest / Vitest (Backend unit/integration), React Testing Library + Playwright (Frontend E2E).
- Путь к файлам тестов: `src/api/payments/__tests__/`, `src/features/checkout/__tests__/`, `e2e/payment-flow.spec.ts`.
- Критические кейсы:
  - Подделка SHA-256 токена в webhook (должен быть 403 Forbidden).
  - Истечение 15-минутного лимита `codeblack_pending_order` (должен игнорироваться).
  - Сетевая ошибка (500/400) при вызове `/v2/Init` или `/v2/GetQr` (должна корректно отображаться в UI).
  - Асинхронность: проверка, что `visibilitychange` не вызывает race condition при множественных срабатываниях.
  - Валидация структуры `Receipt` (массив Items, цены, кол-во, VAT, Taxation) перед отправкой в Т-Кассу.

## Exit Criteria (Критерии выхода)
1. Все новые тесты проходят (зеленый статус).
2. Линтер и тайпчекер (tsc) выполняются без ошибок.
3. Ссылка `https://qr.nspk.ru/...` корректно инициирует нативную шторку выбора банков на iOS и Android (проверено на реальных устройствах/эмуляторах).
4. Токен карт (`RebillId`) успешно сохраняется в БД при первой оплате и корректно списывает средства через `/v2/Charge` при повторном заказе.

---

## Заметки агента (интейк 2026-07-27)

- PHASE 0 only на момент создания дока: док + артефакты + CBR.
- Ревизия поверх v2 (Fly v394): бэкенд Init/GetQr/`sbp/init`, webhook, Recurrent/Charge, UI SBP CTA + poll на `#/payment-result` — **уже есть**.
- **Главный gap этой ревизии:** PWA lifecycle — `codeblack_pending_order`, `visibilitychange`, cold start ≤15 мин, экран `WAITING_FOR_BANK` + «Я оплатил».
- Стек CoffeeOS: Rails 8 + Svelte (не Jest/React-пути из ТЗ). Пути `/shop/api/...`, webhook `/callbacks/tbank`.

## Заметки агента (SPEC 2026-07-27)

→ [`docs/operations/session/todo.md`](../../../session/todo.md)

- 1–3 / 5.1 — **reuse** v2; 3.2 — тонкий `GET /shop/api/payments/status/:order_id`.
- Волна E1: LS pending + visibility guard + WAITING_FOR_BANK.
- Invalid Token webhook: канон **401** (не 403). Charge — через `one_click` + `card_id`, не raw RebillId с клиента.
