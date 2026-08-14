# Изменения в связке: Telegram / Instagram In-App Browser → CoffeeOS /shop

**Дата интейка:** 2026-08-14
**Источник:** текст заказчика (передан владельцем в чат)
**CBR:** #65
**Артефакты:** docs/operations/milestones/veha_2/artifacts/telegram_instagram_inapp_shop_linkage/

---

## Текст заказчика (дословно)

Задача: Изменения в связке: Telegram / Instagram In-App Browser → CoffeeOS /shop
Точки входа:
GET /shop?tenant_id=<UUID> — публичная точка входа в витрину CoffeeOS.
GET /shop/api/categories?tenant_id=<UUID> — запрос каталога, выполняемый frontend после bootstrap.
Внешний источник перехода: ссылка из Telegram или Instagram, открытая во встроенном браузере соответствующего приложения.
Identity Mapping:
tenant_id из query-параметра /shop?tenant_id=<UUID> → внутренний tenant CoffeeOS.
Telegram/Instagram user_id, username, phone и другие внешние идентификаторы не используются как внутренний user_id в рамках /shop.
User-Agent и факт открытия страницы внутри Telegram/Instagram не являются основанием для авторизации.
Потеря, изменение или подмена tenant_id между внешней ссылкой, Rails /shop и /shop/api/categories должна рассматриваться как ошибка связки.
Handling Errors:
Если embedded browser не выполняет JavaScript bootstrap, первоначальный shop-boot-skeleton не должен оставаться бесконечно; приложение должно предоставить контролируемый error fallback.
Если /shop/api/categories возвращает 4xx/5xx или network error, frontend переводится в error state и предоставляет Повторить.
Если localStorage недоступен в Telegram/Instagram WebView, каталог продолжает работать напрямую через API без cache.
Если API недоступен, валидный catalog cache может использоваться как fallback.
Ошибка чтения/записи cache не должна самостоятельно ломать bootstrap или loadCatalog().
Если конкретная версия embedded browser объективно не может корректно выполнить /shop, допускается дополнительный fallback с предложением открыть URL во внешнем системном браузере.
Принудительный redirect из Telegram/Instagram в Chrome/Safari не является основным способом исправления.
Security:
Telegram и Instagram не являются доверенными authentication providers для /shop.
Не использовать Telegram/Instagram user identity, User-Agent или наличие embedded browser как основание для авторизации.
tenant_id должен проходить существующую серверную валидацию/resolution.
Не отключать глобальную CSRF-защиту.
Не добавлять глобальный CORS без доказанной необходимости.
Если причиной являются cookies/session/CSRF, изменение должно быть локальным для /shop и подтверждено диагностикой.
Не хранить Telegram/Instagram credentials, access tokens или секреты в frontend.
Секреты, если они когда-либо потребуются для серверной интеграции, должны храниться через .env, а не в исходном коде.
Compatibility:
Telegram Android In-App Browser/WebView.
Telegram iOS In-App Browser/WebView.
Instagram Android In-App Browser.
Instagram iOS In-App Browser.
Chrome Desktop.
Chrome Android.
Safari iOS.
Диагностическое правило:
Не считать Telegram или Instagram причиной проблемы только на основании User-Agent.
Сначала установить фактическую точку отказа:
HTML → JS bootstrap → Svelte mount → router → tenant_id → API → JSON → state → render.
Зафиксировать отличие между рабочим браузером и embedded browser.
Исправлять конкретную подтвержденную первопричину, а не добавлять platform-specific workaround.
Scope связки:
Изменения ограничиваются совместимостью публичной витрины /shop с embedded browsers.
Не изменяются контракты Telegram/Instagram.
Не изменяется идентификация пользователя через Telegram/Instagram.
Не затрагиваются платежи, авторизация, SMS/Callcheck и другие внешние интеграции, не связанные с открытием /shop.

---

## Заметки агента

- Серия TG/IG → `/shop`, **задача 2** (связка In-App → `/shop`). Задача 1 = CBR **#64** (открытие `/shop`; GREEN local; Fly MCP / TG-IG устройства ещё не закрыты — не смешивать).
- PHASE 0 only: код и SPEC (`todo.md`) не трогали. Дальше по `go` → PHASE 1 SPEC.
- Point A: `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`. Профиль заказчика не портить. Push/deploy только по апруву.
