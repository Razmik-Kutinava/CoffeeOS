# Fly v521 + v522 — hotfix «недоступное хранилище браузера» · 2026-10-29

**Итог: PASS.** FAIL приёмки v520 (TASK_113, сценарий d) закрыт. При заблокированных `localStorage` и `sessionStorage` (Safari «Блокировать все cookie») витрина стартует без `Uncaught SecurityError`, экран результата оплаты показывает нормальный текст вместо сырой ошибки, переход в банк по СБП и 3DS по карте больше не блокируются записью в хранилище (по коду и тестам; «Оплатить» не нажимали). Для обычного гостя ничего не изменилось.

**Коммиты:** `99615458` (`codeblackPendingOrder.js` + `shopSbpPay.js`) → v521 · `bd84d9fc` (`tbankPayment.js`, найдено на перепроверке v521) → v522 · миграций нет
**CI:** `99615458` — CI [40836276995](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40836276995) + Semgrep + CodeQL green · `bd84d9fc` — CI [40838489203](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40838489203) green со 2-й попытки (1-я: нестабильный `rack_attack_otp_verify_test.rb:20` — 422 вместо 429, JS-коммит Rails не трогает; повтор упавшей джобы — green) + Semgrep + CodeQL green
**Deploy:** v521 — [40837578068](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40837578068) (07:46–07:52 UTC) · v522 — [40839244297](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/40839244297) (08:01–08:05 UTC), web 1/1 health passing · апрув владельца 2026-10-29

## Что исправлено

| Файл | Было | Стало |
|---|---|---|
| `app/frontend/lib/codeblackPendingOrder.js` | `defaultStorage()` и `getItem`/`setItem`/`removeItem` без защиты → 2× `Uncaught (in promise) SecurityError` на старте витрины (`recoverPendingPayment`), падение `clearPendingOrder()` на экране результата оплаты | всё под `try/catch`; нет хранилища → нет pending, `loadPendingOrder` → `null` |
| `app/frontend/lib/shopSbpPay.js` | `beginSbpBankRedirect` пишет pending до `go(paymentUrl)` → исключение → `Checkout.svelte` показывал «сервис недоступен» при уже созданном заказе | запись pending в своём `try/catch`, переход в банк идёт всегда |
| `app/frontend/lib/tbankPayment.js` | `savePaymentSession` / `clearPaymentSession` без защиты → экран результата оплаты показывал «The operation is insecure.»; `savePaymentSession` до `try` в `handleThreeDsResponse` → 3DS не запускался | под `try/catch`, как соседний `loadPaymentSession` |

Остальные прямые обращения к `localStorage`/`sessionStorage` во фронте (`rg` по `app/frontend`) уже были под `try/catch` или через безопасные обёртки.

## Сценарии (прод, Chrome DevTools MCP, чистый гостевой профиль на каждый)

Подмена в init script: геттеры `window.localStorage` и `window.sessionStorage` бросают `DOMException SecurityError` (строже v520 — там только `localStorage`); счётчик обращений, слушатели `unhandledrejection` и `error`.

| Версия | Сценарий | Результат | Вердикт |
|---|---|---|---|
| v521 | витрина Point A, хранилище заблокировано | бандл `application-DZswKhN0.js`; 39 обращений к хранилищу — все бросили и пойманы; `unhandledrejection` 0, `error` 0; Console — только 401 `/profile` (гость) и 404 `/uploads/*`; `/shop/api/*` 200, beacon 204 ([P1](prod/P1_v521_task113_catalog_no_security_error.png)) | ✅ |
| v521 | `#/payment-result?status=fail&order_id=<несуществующий>`, хранилище заблокировано | Console чистый, но на экране сырой «The operation is insecure.» ([P0](prod/P0_v521_payment_result_raw_error_before.png)) → источник `tbankPayment.clearPaymentSession()` → `bd84d9fc` | ❌ → исправлено |
| v522 | витрина Point A, хранилище заблокировано | бандл `application-BXDVQbaC.js`; 39 обращений пойманы; `unhandledrejection` 0, `error` 0; Console — только 401/404 ([P2](prod/P2_v522_task113_storage_blocked_catalog_clean.png)) | ✅ |
| v522 | экран результата оплаты, хранилище заблокировано | «Оплата не завершена, попробовать снова» + «В каталог»; `unhandledrejection` 0, `error` 0; `POST /orders/<id>/abandon` 404 — заказа нет, вызов best-effort ([P3](prod/P3_v522_payment_result_storage_blocked_ok.png)) | ✅ |
| v522 | smoke: обычный профиль без подмен | каталог рисуется; `localStorage` — корзина, режим шторки, каталог, адрес точки; `sessionStorage` — снимок окружения; Console — только 401/404 | ✅ |

## Тесты

- Новые: 5 в `test/javascript/codeblack_pending_order_test.mjs` (заблокированный геттер, бросающие методы, переход в банк при заблокированном хранилище и при бросающем `savePending`, восстановление на холодном старте) — до правки 5 fail; 2 в новом `test/javascript/tbank_payment_session_test.mjs` — до правки 1 fail.
- Зона: JS `codeblack_pending_order` + `shop_sbp_pay` + `shop_sbp_autopay_checkout_ui` + `sbp_waiting_screen_transition` + `tbank_payment_session` 74/74 · `email_collection_test` 26/1 — известное legacy (ISSUES «JS legacy fails»), падает так же без правки · Rails `checkout_acceptance_cbr` + `checkout_ui_cleanup` + `order_status_acceptance_cbr` + `sbp_payment_ui` + `sbp_payment_return_ui` 30/0.

## Пачка приёмки

- **Fly logs** (буфер `fly logs --no-tail`, 08:06:26–08:06:43 UTC, 100 строк): 2xx 18, 4xx 1, **5xx 0**, Exception/FATAL 0
- **Sentry 1h:** 0 unresolved issues
- **Neon / УК:** skip — миграций нет, только фронт

## Не проверено здесь

- Переход в банк по СБП и 3DS по карте при заблокированном хранилище вживую — «Оплатить» не нажимаем; покрыто unit-тестами и чтением кода `Checkout.svelte`.
- Реальный Safari с «Блокировать все cookie» — эмуляция через init script в Chrome.
- Восстановление статуса оплаты после возврата из банка без хранилища — не работает и не может (pending некуда записать) — не проверялось.
