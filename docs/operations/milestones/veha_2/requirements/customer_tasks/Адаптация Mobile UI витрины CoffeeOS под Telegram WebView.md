# Адаптация Mobile UI витрины CoffeeOS под Telegram WebView

**Дата интейка:** 2026-08-15
**Источник:** текст заказчика (передан владельцем в чат)
**CBR:** #67
**Артефакты:** docs/operations/milestones/veha_2/artifacts/mobile_storefront_telegram_webview_ui/

---

## Текст заказчика (дословно)

Задача: Адаптация Mobile UI витрины CoffeeOS под Telegram WebView
Бизнес-цель:
После обеспечения базовой работоспособности мобильной витрины CoffeeOS внутри Telegram In-App Browser адаптировать мобильный интерфейс под фактические ограничения WebView, чтобы элементы интерфейса не перекрывались системными областями Telegram, клавиатурой или друг другом, а каталог, корзина и bottom sheet оставались полностью доступными для пользователя.
1. Связь с картой интеграций
Затронутые сервисы из @INTEGRATIONS.md:
Telegram In-App Browser / Telegram WebView.
CoffeeOS Mobile Storefront / PWA.
Зависимости от Задача: Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser:
WebView должен успешно загружать Svelte-приложение.
API, cookies/storage, tenant_id, CORS и CSP должны быть работоспособны.
TASK-049 изменяет преимущественно UI/layout behavior и не должен повторно решать backend/WebView compatibility проблемы из Задача: Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser.
Смежные модули, которые НЕЛЬЗЯ ломать:
каталог и карточки товаров;
корзина;
существующие bottom sheets;
checkout;
существующая мобильная версия вне Telegram;
tenant context;
API и состояние заказа.
2. Разрешенный и Запрещенный Scope
Разрешено менять/создавать
src/components/** — mobile UI, bottom sheet, cart и связанные компоненты.
src/routes/** — только layout/viewport поведение страниц мобильной витрины.
src/styles/**, src/app.css, либо эквивалентные global styles — CSS для viewport, safe-area, scroll и WebView.
src/lib/** — только UI utilities/hooks, связанные с viewport, keyboard и WebView layout.
tests/** — UI/component/integration tests TASK-049.
Строго запрещено менять
backend API;
prisma/schema.prisma и структуру БД;
auth/session business logic;
tenant resolution;
платежную бизнес-логику;
Telegram Bot API integration;
API contracts из Задача: Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser;
desktop layout без необходимости, подтвержденной regression test;
бизнес-логику корзины и оформления заказа.
3. Сценарии и Чек-лист (Gherkin)
Subtask 1: Зафиксировать корректный viewport мобильной витрины
Given: меню открыто внутри Telegram WebView на мобильном устройстве.
When: страница получает текущие размеры viewport.
Then: layout использует актуальную доступную область WebView и не рассчитывает высоту только от физического размера экрана.
Subtask 2: Обработать изменение высоты viewport
Given: пользователь находится в Telegram WebView.
When: доступная высота viewport изменяется.
Then: layout пересчитывается без появления пустой области, горизонтального/вертикального overflow или перекрытия контента.
Subtask 3: Зафиксировать корректное поведение sticky-элементов
Given: пользователь прокручивает каталог.
When: sticky header или другие sticky UI-элементы достигают границы viewport.
Then: они остаются в доступной области и не перекрываются системными областями Telegram.
Subtask 4: Адаптировать bottom sheet
Given: пользователь открывает bottom sheet внутри Telegram WebView.
When: sheet переходит в peek/expanded состояние.
Then: bottom sheet помещается в доступную область viewport и его содержимое остается доступным для взаимодействия.
Subtask 5: Обеспечить корректный scroll внутри bottom sheet
Given: содержимое bottom sheet превышает доступную высоту.
When: пользователь выполняет вертикальный scroll.
Then: прокручивается содержимое sheet, а не вся страница, если текущий UX предполагает внутренний scroll.
Subtask 6: Проверить отсутствие scroll-lock конфликтов
Given: открыт bottom sheet.
When: пользователь прокручивает область контента.
Then: body/page scroll не конфликтует со scroll bottom sheet и пользователь не получает "залипания" интерфейса.
Subtask 7: Адаптировать корзину под WebView viewport
Given: пользователь открывает корзину.
When: корзина отображается поверх витрины.
Then: нижняя и верхняя границы корзины находятся в пределах доступного viewport, а CTA остается видимым.
Subtask 8: Проверить safe-area
Given: устройство имеет системную safe-area.
When: отображается нижняя часть интерфейса, включая cart/bottom sheet/CTA.
Then: элементы получают необходимый safe-area inset и не оказываются под системными областями.
Subtask 9: Проверить верхнюю safe-area
Given: Telegram WebView предоставляет ограниченную верхнюю область.
When: отображается header/navigation.
Then: header не перекрывается системными элементами и сохраняет доступность интерактивных controls.
Subtask 10: Обработать появление клавиатуры
Given: пользователь открывает input внутри витрины или bottom sheet.
When: появляется системная клавиатура.
Then: активный input остается видимым, bottom sheet корректно изменяет доступную высоту, а клавиатура не перекрывает CTA или input.
Subtask 11: Обработать закрытие клавиатуры
Given: клавиатура была открыта.
When: пользователь закрывает клавиатуру.
Then: viewport и layout возвращаются в корректное состояние без оставшегося пустого пространства или смещенного bottom sheet.
Subtask 12: Проверить cart + keyboard combination
Given: корзина/bottom sheet содержит поле ввода и открыта клавиатура.
When: пользователь вводит данные.
Then: keyboard, input, cart content и CTA не перекрывают друг друга.
Subtask 13: Проверить полный scroll каталога
Given: каталог содержит количество товаров, превышающее высоту WebView.
When: пользователь прокручивает каталог от начала до конца.
Then: все товары и необходимые controls доступны, нижний контент не скрыт за fixed/sticky элементами.
Subtask 14: Проверить взаимодействие sticky + bottom sheet + cart
Given: пользователь находится в нижней части каталога.
When: открывает bottom sheet или корзину.
Then: overlay корректно располагается относительно viewport и sticky элементов, без двойного перекрытия или недоступных controls.
Subtask 15: Проверить orientation/resize behavior
Given: устройство изменяет доступный размер WebView.
When: происходит resize/orientation change.
Then: viewport, sticky elements, bottom sheet и cart пересчитывают размеры без визуального разрушения layout.
Subtask 16: Добавить regression tests для Mobile UI WebView
Given: UI адаптирован под Telegram WebView.
When: запускается набор тестов.
Then: тесты покрывают viewport, sticky, bottom sheet, cart, scroll, safe-area и keyboard behavior.
Subtask 17: Выполнить ручную проверку на реальном Telegram WebView
Given: Задача: Полноценная работа мобильной витрины CoffeeOS внутри Telegram In-App Browser завершен и витрина доступна внутри Telegram.
When: выполняются основные mobile UI сценарии на реальном устройстве.
Then: ни один критический UI-элемент не перекрывается Telegram WebView, safe-area или keyboard.
4. Команды TDD-проверки
Запуск тестов: npm test tests/integration/.test.ts
Проверка типов: npx tsc --noEmit
Acceptance: ручная проверка в Telegram In-App Browser на реальном мобильном устройстве обязательна.
5. Definition of Done
Viewport корректно определяется и пересчитывается.
Sticky-элементы не перекрываются WebView.
Bottom sheet полностью помещается в доступную область.
Внутренний scroll работает предсказуемо.
Корзина и CTA остаются доступными.
Safe-area учитывается сверху и снизу.
Клавиатура не перекрывает input и CTA.
После закрытия клавиатуры layout восстанавливается.
Resize/orientation не ломает UI.
Основной mobile UI вне Telegram не регрессировал.
regression tests проходят.
Реальная проверка в Telegram WebView пройдена.

TODO: 
Subtask 1: Зафиксировать корректный viewport мобильной витрины
Subtask 2: Обработать изменение высоты viewport
Subtask 3: Зафиксировать корректное поведение sticky-элементов
Subtask 4: Адаптировать bottom sheet
Subtask 5: Обеспечить корректный scroll внутри bottom sheet
Subtask 6: Проверить отсутствие scroll-lock конфликтов
Subtask 7: Адаптировать корзину под WebView viewport
Subtask 8: Проверить safe-area
Subtask 9: Проверить верхнюю safe-area
Subtask 10: Обработать появление клавиатуры
Subtask 11: Обработать закрытие клавиатуры
Subtask 12: Проверить cart + keyboard combination
Subtask 13: Проверить полный scroll каталога
Subtask 14: Проверить взаимодействие sticky + bottom sheet + cart
Subtask 15: Проверить orientation/resize behavior
Subtask 16: Добавить regression tests для Mobile UI WebView
Subtask 17: Выполнить ручную проверку на реальном Telegram WebView

INTEGRATIONS.md Update
##  Изменения в связке: Telegram In-App Browser / WebView → CoffeeOS Mobile UI

- **Точки входа:**
  - Mobile storefront, открытый внутри Telegram In-App Browser.
  - UI работает поверх существующего WebView runtime и API-контрактов TASK-048.
  - Новые backend endpoints для UI-адаптации не требуются.

- **Identity Mapping:**
  -  не изменяет identity mapping.
  - `tenant_id` и существующий `user_id` должны сохраняться без изменений.
  - UI viewport, safe-area, keyboard и WebView lifecycle не должны влиять на tenant/user context.

- **Handling Errors:**
  - Изменение viewport не должно приводить к потере UI state.
  - Открытие/закрытие клавиатуры не должно сбрасывать bottom sheet/cart state.
  - Resize/orientation не должен приводить к зависшему overlay или недоступному CTA.
  - Если WebView не предоставляет ожидаемый viewport/storage/browser API, UI должен использовать безопасный fallback.

- **Security:**
  - TASK-049 не изменяет authentication/security contract.
  - Не добавлять чувствительные данные в client-side viewport state.
  - Не использовать Telegram WebView-specific client data как замену серверной валидации tenant/user.

- **WebView UI Compatibility:**
  - Layout должен учитывать фактический visual viewport, а не только `window.innerHeight`.
  - Fixed/sticky/bottom-sheet элементы должны учитывать доступную WebView область.
  - Нижние и верхние safe-area inset должны учитываться для элементов, расположенных у границ viewport.
  - Появление виртуальной клавиатуры должно корректно менять доступную область для input/bottom sheet/cart.
  - Scroll-lock между body, каталогом, bottom sheet и cart не должен создавать недоступные состояния.
  - Адаптация UI не должна изменять поведение обычного мобильного браузера без необходимости.

---

## Заметки агента

- **CBR #67.** Серия TG/IG → `/shop`: задача 1 = #64, задача 2 = #65, задача 3 = #66 (runtime), **эта = задача 4 (Mobile UI)**. Задача 5 (UX/Performance) — отдельный диалог, не этот шаг.
- TASK-049 / TASK-048 в ТЗ заказчика = наша нумерация **#67 / #66**. Не плодить TASK-* в коде.
- Пути заказчика `src/components/**`, `src/routes/**`, `src/styles/**`, `src/lib/**`, `src/app.css`, `prisma/schema.prisma`, `npm test tests/integration/.test.ts`, `npx tsc --noEmit` — чужой стек. Канон CoffeeOS: `app/frontend/**` (Svelte) + `node --test test/javascript/*.mjs`. Prisma / tsc / backend API — **не трогать**.
- #66 уже даёт runtime: `shopWebView.js`, `--shop-vvh`, `viewport-fit=cover`, storage fallback. Эта задача **потребляет** `--shop-vvh` в layout (CartSheet/`vh`, Header, catalog padding). Не решать заново CORS/CSP/API/tenant/bot.
- `CartSheet.svelte` >700 строк — **не раздувать**. Высота/keyboard/safe-area → новый `shopWebViewLayout.js`; шторка только подставляет px.
- Канон одной шторки (`coffeeos-cart-sheet`): не второй `position:fixed` низ; peek/expanded/CTA — секции одной колонки.
- Catalog скролл = `window` + `handleCatalogScroll` (peek/hidden). Внутренний overflow шторки ≠ lock body так, чтобы сломать этот скролл.
- `initTelegram()` = Mini App SDK. In-App Browser по ссылке ≠ Mini App. Не подключать telegram.org SDK.
- Instagram — зона #64/#65; канон этой задачи — **Telegram WebView**. Chrome/Safari mobile не регрессировать.
- Подзадача 17: #66 на Fly ещё **без deploy**. Ручной Telegram — после апрува deploy #66 (или совместного), не блокер local GREEN.
- Приёмка hot-path: Fly **Point A** `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`. Контракт UI — `docs/integrations/shop-api.md` § Embedded browser (WebView UI), не отдельный секционный файл.
