# TASK_113: Устойчивость push-кода к недоступному хранилищу

**ID заказчика:** TASK_113 · **CBR:** #113 · **Дата intake:** 2026-10-29 (шаг 8 [очереди Push + SMS](../PUSH_SMS_QUEUE.md))  
**Источник:** Google Doc Spec (одна вкладка)  
**Артефакты:** нет (заказчик не прислал)  
**Google Doc:** https://docs.google.com/document/d/1rWjRNPguPkcFr3lZ4v9xvjDlW1FwtlLnKcwEws7qOyc/edit  
**Статус:** intake 2026-10-29 · без миграции (по тексту документа)

---

## Текст задачи (дословно) — Google Doc Spec

## TASK_113: Устойчивость push-кода к недоступному хранилищу
**Тип:** новая задача (для push сценарий не зафиксирован; требование #66 касается кеша каталога, он уже защищён: catalog.js:29-48, shopLocalStorage.js:29-40)
Бизнес-цель: если браузер или встроенный браузер ограничивает localStorage, панель активных заказов и кнопка уведомлений продолжают работать.

## 1. Карта интеграций — затронуто / нет
Затронуто: клиентское чтение и запись localStorage в сценарии уведомлений панели заказа.
Не затронуто: backend, /shop/api/push/register, VAPID/FCM, Service Worker, каскад, статусная модель.

## 2. Карта компонентов
orderStatusNotifyActions.js: :91 (геттер localStorage в параметре по умолчанию, до try на :98), :218 (то же до try на :225), :302 (геттер, try нет), :309 и :321 (getItem без try); :114 (запись после добавления Wallet pass внутри внешнего try: при ошибке гость видит тост ошибки, хотя pass уже добавлен).
ActiveOrdersAccordion.svelte вызывает resolveNotifyPrimaryInit внутри $derived и $effect (:65-68, :75-81).
Общий файл с TASK_90, TASK_99, TASK-PUSH-DIAG-GATE (и с TASK-IOS-PUSH-PATH по Wallet): да. Граница: только защита обращений к storage; сигнатуры, resumePushAfterSettings, recovery UI, ключ coffeeos_shop_push_registered_v1 и логика Wallet не меняются.
Новый компонент: нет.

## 3. Текущее поведение (факт, не требование)
Пять обращений выше выполняются без защиты. resolveNotifyPrimaryInit вызывается при рендере аккордеона, поэтому исключение возникает при рендере (влияние на всё приложение не проверено, error boundary не искали). В subscribeOrderPush геттер вычисляется до try: при исключении промис отклоняется до requestPermission (зависит от браузера, не проверялось). Доказательств, что это происходит на реальных устройствах, нет. Образцы защиты: shopGuestSession.js:4-36, firebasePush.js:157-161; тест shop_telegram_webview_test.mjs:138-152.

## 4. Scope
Разрешено: try/catch или маленькая локальная функция-обёртка внутри orderStatusNotifyActions.js; тесты.
Запрещено: подключать safeWebStorage; менять ключ и его семантику; менять recovery, armed, resumePushAfterSettings; менять логику Wallet; трогать firebasePush.js (уже защищён) и другие модули; вводить await или динамический импорт до вызова registerShopPush в subscribeOrderPush (инвариант TASK_99, orderStatusNotifyActions.js:226).
Решение владельца 2026-10-15: вариант А. Защита локальная (try/catch); запасное хранилище в этой задаче не подключается (вопрос закреплён за TASK-STORAGE-FALLBACK-EXT).

## 5. Gherkin
- [ ] Subtask 1: Given геттер localStorage бросает исключение, When рендерится панель с активным заказом, Then hasPushSubscription = false, рендер не ломается.
- [ ] Subtask 2: Given getItem бросает исключение, Then результат тот же.
- [ ] Subtask 3: Given storage недоступен, When гость нажимает push-CTA, Then subscribeOrderPush доходит до requestPermission, неудачная запись флага на результат не влияет.
- [ ] Subtask 4: Given storage недоступен, When гость добавляет Wallet pass, Then pass добавлен и ошибка записи флага не показывается как ошибка добавления.
- [ ] Subtask 5: Given storage исправен, Then поведение прежнее, существующие тесты order_status_push_subscribe зелёные.
- [ ] Subtask 6: Given флаг не записался, When гость вернулся на экран, Then кнопка уведомления может показаться снова, это допустимо.

## 6. TDD-проверка: команды
npm test -- --run (order_status_push_subscribe, active_orders_accordion); npm run lint; npm run typecheck.
Ручная проверка: Chrome с заблокированными данными сайта; Telegram WebView, если воспроизводится.
Приоритет низкий: доказательств проблемы на устройствах нет, правка дешёвая. Документ готов к билду.
## SBR: TASK-PUSH-STORAGE-SAFE (после Д2 и Д3)
## Файлы (ожидаемо): orderStatusNotifyActions.js (:91, :114, :218, :302, :309, :321), тесты
## Не ломать: resumePushAfterSettings, recovery UI TASK_90, ключ coffeeos_shop_push_registered_v1, логика Wallet, инвариант TASK_99
## Проверка: npm test -- --run (order_status_push_subscribe, active_orders_accordion); npm run lint; npm run typecheck
## DoD: Subtask 1–6, существующие тесты зелёные

---

## Заметки агента

- Метки в тексте → ID заказчика (по таблице меток [очереди](../PUSH_SMS_QUEUE.md)): TASK-PUSH-STORAGE-SAFE = эта задача (TASK_113, Д10); TASK-PUSH-DIAG-GATE = TASK_108 (Д3, шаг 7); TASK-IOS-PUSH-PATH = TASK_111 (Д8, шаг 11); TASK-STORAGE-FALLBACK-EXT = TASK_114 (Д11, Subtask 2–6 отложены); Д2 = Патч 2 TASK_90 (шаг 6).
- Сверка шапки с очередью (п. 4 «Как работать»): «после Д2 и Д3» = строка 8 очереди «Зависит от: 6, 7» (оба `done`); «Документ готов к билду» = статус `todo`; условий выкладки в документе нет — шаг входит в 🚀 2 по очереди. Расхождений нет.
- Номера строк в разделах 2–4 (`orderStatusNotifyActions.js` `:91`, `:114`, `:218`, `:226`, `:302`, `:309`, `:321`; `ActiveOrdersAccordion.svelte` `:65-68`, `:75-81`; `firebasePush.js:157-161`) написаны до шагов 6 и 7, которые меняли эти файлы, — сдвиг ожидаем, сверяем на `/spec`.
- Шаг 7 добавил `pushDiagFlag.js` со своей защитой хранилища (try/catch + память) — вне scope этой задачи (Scope запрещает трогать другие модули).
- Зона карты (`ActiveOrdersAccordion`, `orderStatusNotifyActions.js`) → на `/spec` читать `COMPONENT_MAP.md`.
- Прецедент шагов 6 и 7: команд `npm test -- --run` / `npm run lint` / `npm run typecheck` в проекте нет — JS-тесты `node --test test/javascript/*.mjs`, сборка `npx vite build`.
