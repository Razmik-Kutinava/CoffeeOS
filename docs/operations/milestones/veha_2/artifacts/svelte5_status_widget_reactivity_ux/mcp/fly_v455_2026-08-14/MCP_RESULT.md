# MCP Point A — Fly v455 (N+1 + Sentry filter + #63 UX)

**Дата:** 2026-08-14  
**Стенд:** Point A `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`  
**Deploy:** `deployment-01KZZXM710GG6FWTXYN47PBBHC` · version **455**  
**Сессия:** Aram `2bc3…4c` (смотреть профиль OK · **не** OTP / PAN / имя)

| Check | Вердикт | Evidence |
|-------|---------|----------|
| `/up` | **PASS** | 200 |
| Bundle `#63` | **PASS** | `application-C1-JEZDS.js`: `userDismissed` + `status-widget-dismiss` |
| Каталог Point A | **PASS** | адрес «Москва, ул. Ленина, 10» · часы · 15 карточек · «повторить» |
| Product: статус скрыт | **PASS** | `#/product/d4ff4994-…` Brazil 179₽ · sheet absent |
| Checkout: статус скрыт | **PASS** | `#/checkout` · `checkout-page` · h1 «Оформление» · sheet absent |
| Pay stack UI | **PASS** | stacked sheet · СБП · `*8782` · `*5953` · «Картой +» · без inline error / retry |
| Profile: статус скрыт | **PASS** | `#/profile` Aram · sheet absent · контакты не правили |
| Catalog restore | **PASS** | `#/` · 15 карточек · repeat · адрес |
| Dismiss X | **skip** | активного заказа нет; оплату картой Арама не проводили |
| Cleanup | **PASS** | тестовая строка Brazil удалена · CTA `+0₽` disabled (empty cart by design) |

**Не ломали:** Cable/peek корзины · stacked pay · Quick Repeat · профиль заказчика.

**Косяки на коде:** не найдены. 2₽/3₽ в «Черный» / «повторить» — демо-цены Point A, не регресс v455. Пустой peek `+0₽` disabled — канон `CartSheet` empty + checkoutBar.

**Скрин:** `01_catalog_cart_179.png` (корзина Brazil 179 до cleanup).
