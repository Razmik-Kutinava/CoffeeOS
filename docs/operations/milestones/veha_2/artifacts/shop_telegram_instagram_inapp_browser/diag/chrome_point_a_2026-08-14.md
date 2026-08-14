# #64 diag — точка отказа /shop bootstrap

**Дата:** 2026-08-14  
**Point A:** `https://coffeeos.fly.dev/shop?tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`

## Chrome Desktop (эталон)

| Шаг | Результат |
|-----|-----------|
| HTML | 200, `shop-boot-skeleton` в исходнике |
| JS | `/vite/assets/application-*.js` `type="module"` + `crossorigin` · loaded |
| Mount | skeleton снят, каталог Point A (Ленина, 10) |
| API | меню на экране; GET categories не требует cookie (в сессии CDP `document.cookie` пустой) |

**Не причина в Chrome:** CORS, CSRF, потеря `tenant_id`, Fly HTML.

## Telegram / Instagram

Реальных устройств в этом шаге не было. Симптом ТЗ (вечный skeleton) совпадает с цепочкой:

HTML загрузился → **единственный boot-скрипт `type=module`** не исполнился или `mount(App)` бросил → `#app` не заменён.

На Fly: `Link: rel=modulepreload` + `<script type="module" crossorigin>`. Classic JS fallback до фикса отсутствовал.

Cookies/CORS/CSRF не доказаны: Chrome без cookie всё равно рисует меню.

## Исправление (без UA-веток)

- classic `shop-boot-watchdog` (не module) — ошибка + «Обновить», если skeleton жив >12с
- `application.js` try/catch вокруг mount
- Catalog: «Повторить»; storage throw не роняет `loadCatalog`
