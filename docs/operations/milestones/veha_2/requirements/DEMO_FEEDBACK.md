# Фидбек заказчика после демо (В2)

**Зачем:** очередь правок из PDF «Прогонка сценариев» заказчика (все разделы в файле ниже).

**Источник:** PDF [`artifacts/demo-feedback/customer_qa_prog10_2026-06.pdf`](artifacts/demo-feedback/customer_qa_prog10_2026-06.pdf) (продолжение В1: [`../veha_1/artifacts/customer_live_qa_block1_2026-05-30.pdf`](../veha_1/artifacts/customer_live_qa_block1_2026-05-30.pdf)).

**Сейчас (2026-06-06):** **§2.3 закрыт** — апрув заказчика. Следующий фокус: **блок 2** (табло баристы) → [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](CUSTOMER_BUSINESS_REQUIREMENTS.md).

**Честно:** §1–3 в таблице ниже — **done** *(выборочно)*. §2.3 — **done** *(этапы 1–5, MCP)*.

**Связь:** [`CHECKLIST.md`](CHECKLIST.md) § E · [`SESSION_STATE.md`](../../session/SESSION_STATE.md) · прогон 10 [`QA_ACCEPTANCE_RUN.md`](QA_ACCEPTANCE_RUN.md).  
**Активный чеклист:** [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](CUSTOMER_BUSINESS_REQUIREMENTS.md).

---

## Правила

1. Одна строка = одна правка (или связанный пакет UI).
2. Статус: `open` → `in_progress` → `done` / `wontfix`.
3. Блокеры — `blocker` + PR/коммит.
4. Техдолг В3 — не дублировать здесь (`PRACTICES`, `veha_3`).

---

## Очередь (PDF §1–3)

| Дата | Источник | Сценарий / экран | Суть | Статус | PR / коммит |
|------|----------|------------------|------|--------|-------------|
| 2026-06-04 | заказчик B1.7 | cart / каталог / `#/product` | **BR-5 регрессия:** второй товар — баннер/DOM корзины | **done** *(Fly MCP 7/7 + catalog + quick-add)* | [b17_br5_regression_post_deploy_2026-06-04.json](artifacts/demo-feedback/b17_br5_regression_post_deploy_2026-06-04.json) |
| 2026-06-04 | заказчик (чат) B1.1 | экран статуса гостя `#/order/...` | **Баг-1:** без F5 статус не обновляется после тапа баристы | **done** 2026-06-13 | [`b11_bug1_guest_ws_2026-06-13.json`](artifacts/demo-feedback/b11_bug1_guest_ws_2026-06-13.json) |
| 2026-06-15 | заказчик B1.10 | shop шапка | Убрать «Блог» из навигации, LCP ≤ 1.5 с | **done** *(Fly MCP PASS)* | [`b110_blog_nav_post_deploy_2026-06-15.json`](artifacts/demo-feedback/b110_blog_nav_post_deploy_2026-06-15.json) |
| 2026-06-16 | заказчик B1.9 | `#/product` карточка | Toggle модификаторов, убрать «обязательно» | **done** *(Fly MCP 6/6)* | [`b19_modifier_toggle_post_deploy_2026-06-15.json`](artifacts/demo-feedback/b19_modifier_toggle_post_deploy_2026-06-15.json) |
| 2026-06-15 | заказчик B1.7 | cart / product | **Баг-5 (v1):** второй разный товар — stale `Product.svelte` | **done** *(Fly MCP PASS)* · **регрессия 2026-06-04** | [`b17_cart_second_product_post_deploy_2026-06-15.json`](artifacts/demo-feedback/b17_cart_second_product_post_deploy_2026-06-15.json) |
| 2026-06-14 | B1.7 | localStorage витрины | TTL 24ч для профиля/корзины/каталога | **done** | [`b17_localstorage_ttl_2026-06-14.json`](artifacts/demo-feedback/b17_localstorage_ttl_2026-06-14.json) |
| 2026-06-14 | заказчик B1.7 | cart/add | **Баг-4:** 500 при «В корзину» (cookie overflow) | **done** | [`b17_cart_cookie_overflow_2026-06-14.json`](artifacts/demo-feedback/b17_cart_cookie_overflow_2026-06-14.json) |
| 2026-06-13 | заказчик (видео) B1.7 | checkout `#/checkout` | **Баг-3:** «сессия истекла» при повторном заходе после OTP | **done** 2026-06-14 (permanent) | [`b17_checkout_session_2026-06-14.json`](artifacts/demo-feedback/b17_checkout_session_2026-06-14.json) |
| 2026-06-02 | заказчик PDF §3.6 | franchise / УК | **Баг:** франчайзи «нет» — вход или создание из УК | done *(MCP post-deploy)* | [`mcp_post_deploy_fly_2026-06-03.json`](artifacts/demo-feedback/mcp_post_deploy_fly_2026-06-03.json) §franchise |
| 2026-06-02 | заказчик PDF §2.2 | shop UI | Стрелка назад, свайп, +1 товар — проверить/допилить | done *(PDF)* | назад/свайп/+1 — ок по прогонке; платные модификаторы — код `51e4d22+` |
| 2026-06-03 | заказчик PDF §2.2 | shop модификаторы | Платные допки +15/+20/+40, пересчёт корзины/оплаты | done *(MCP)* | [`mcp_section_2_2_fly_2026-06-03.json`](artifacts/demo-feedback/mcp_section_2_2_fly_2026-06-03.json) — кордиал → **199₽** |
| 2026-06-06 | заказчик (чат) | shop §2.3 оплата | Полная приёмка §2.3 этапы 1–5 + UI iframe | **done** *(апрув)* | [`mcp_section_2_3_stage5_3_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json) |
| 2026-06-04 | заказчик PDF §2.3 | shop оплата | ФИО до кнопки; «Идёт оплата…»; корзина после возврата с банка | **done** *(MCP)* | [`mcp_section_2_3_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_3_fly_2026-06-04.json) post-deploy |
| 2026-06-04 | заказчик PDF §2.4 | shop оплата | Двойной «Оплатить» — один заказ | **done** *(MCP+БД Fly)* | [`mcp_section_2_4_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_4_fly_2026-06-04.json) `db_orders_count: 1`; код `11ab05f` |
| 2026-06-04 | заказчик PDF §2.5 | shop | Медленный интернет: крутилка; тест в подвале | **done** *(MCP Slow 3G)* | [`mcp_section_2_5_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_5_fly_2026-06-04.json); boot skeleton `home.html.erb` |
| 2026-06-02 | заказчик PDF §1.2 | `/manager` шапка | GM видит **«Офис-менеджер»** вместо **«Управляющий точки»** | done | Fly MCP post-deploy: **«Управляющий точки»** |
| 2026-06-02 | QA §1.2 | gm-a / gm-b Fly | Изоляция A/B: цены 179 vs 189, A не видит B | done *(MCP)* | [`mcp_section_1_2_fly_2026-06-02.json`](artifacts/demo-feedback/mcp_section_1_2_fly_2026-06-02.json) |
| 2026-06-02 | заказчик PDF §1.3 | смена / UI | Неясно где открыть/закрыть смену; в демо смена открывалась сама | done *(MCP post-deploy)* | [`mcp_post_deploy_fly_2026-06-03.json`](artifacts/demo-feedback/mcp_post_deploy_fly_2026-06-03.json) §shift; кнопка «Открыть смену» на Fly |
| 2026-06-03 | заказчик PDF §1.4 | склад цеха vs точка | Ожидали минус на **цехе**, списание только на **точке** | done *(MCP post-deploy)* | [`mcp_post_deploy_fly_2026-06-03.json`](artifacts/demo-feedback/mcp_post_deploy_fly_2026-06-03.json) §inventory + [`mcp_section_1_4_fly_2026-06-03.json`](artifacts/demo-feedback/mcp_section_1_4_fly_2026-06-03.json) |
| 2026-06-02 | заказчик PDF §2.1 | shop витрина A | Меню: каталог → категория → карточка (название, цена, модификаторы; скрин заказчика = карточка) | done *(MCP)* | [`mcp_section_2_1_fly_2026-06-02.json`](artifacts/demo-feedback/mcp_section_2_1_fly_2026-06-02.json) |
| 2026-06-04 | заказчик (чат) | УК vs franchise / staff | У **франчайзи** скрыт «Персонал»; у **GM** — виден | **done** *(MCP Fly)* | `7311338`, `62ced8e`; [`mcp_franchise_staff_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_franchise_staff_fly_2026-06-04.json) |
| 2026-06-04 | команда / заказчик | shop витрина | **Подсказки онбординга** (баннер, подсветка, блок «В корзину») | **done** *(MCP Fly)* | `6c5cc0b` — `Product.svelte`; баннер на карточке Бразилия post-deploy |
| 2026-06-04 | команда (чат) | УК → Меню → витрины A/B | PTS + `per_page` API; UK create товар+модификаторы | **done** *(API)* | `589e397`; MCP UK `OPS-AUTO-175630` на A/B API |
| 2026-06-04 | команда (чат) | shop витрина A/B | **Автообновление меню без F5** (~8 s) | **done** *(MCP+Fly)* | `e398981`+`1861f4f`; [`mcp_uk_menu_autorefresh_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_uk_menu_autorefresh_fly_2026-06-04.json); handoff [`HANDOFF_UK_MENU_VITRINA.md`](HANDOFF_UK_MENU_VITRINA.md) |
| 2026-06-04 | команда (чат) | УК → Меню → A/B | Новый товар+модификаторы в **браузере** → API A/B сразу | **done** *(Fly)* | `OPS-POSTDEPLOY-001` на A/B после deploy `1861f4f`; см. handoff |
| 2026-06-07 | заказчик (чат) | УК → Меню → товар | Не сохраняет цену **2,95 ₽** — браузер «Введите URL» на поле фото | **done** | `type="url"` → `text`; см. § «УК: фото товара» ниже |

### §2.2 — приёмка (MCP Fly)

| Критерий | Статус |
|----------|--------|
| +15/+20/+40 на карточке Fly | **PASS** |
| Выбор кордиала → **199₽** (179+20) | **PASS** |
| Корзина: `(+20₽)`, Итого **199₽** | **PASS** |
| Подсказки онбординга | **PASS** post-deploy (`6c5cc0b`) |

### §2.1 — приёмка (MCP Fly)

| Критерий | Статус |
|----------|--------|
| Каталог: категории + карточки на Fly | **PASS** |
| Категория «Черный»: список товаров | **PASS** |
| Карточка Бразилия: название, 179₽, модификаторы | **PASS** |

### §1.2 — приёмка (MCP Fly)

| Критерий | Статус |
|----------|--------|
| Разные цены A/B на Fly | **PASS** (179 / 189) |
| gm-a не видит Point B / заказы B | **PASS** |
| Подпись роли GM на Fly | **PASS** (post-deploy MCP) |

---

## Post-deploy MCP (2026-06-03) — выполнено

| Блок | Артефакт | Статус |
|------|----------|--------|
| §1.x + shop A↔B + franchise | [`mcp_post_deploy_fly_2026-06-03.json`](artifacts/demo-feedback/mcp_post_deploy_fly_2026-06-03.json) | **PASS** |
| §2.1 меню | [`mcp_section_2_1_fly_2026-06-02.json`](artifacts/demo-feedback/mcp_section_2_1_fly_2026-06-02.json) | **PASS** |
| §2.2 модификаторы (+15/+20/+40, 199₽) | [`mcp_section_2_2_fly_2026-06-03.json`](artifacts/demo-feedback/mcp_section_2_2_fly_2026-06-03.json) | **PASS** |

### §2.3 — приёмка техпрогона (Fly, 2026-06-04 … 2026-06-06)

| Критерий | Статус / артефакт |
|----------|-------------------|
| Без ФИО кнопка неактивна | **PASS** — stage 1 |
| С ФИО → «Идёт оплата…» → T-Bank iframe | **PASS** — stage 4 |
| Назад с банка → корзина с товаром | **PASS** |
| Заказ виден после банка (reconnect) | **PASS** — [`mcp_section_2_3_stage2_2026-06-04.json`](artifacts/demo-feedback/mcp_section_2_3_stage2_2026-06-04.json) |
| Успех оплаты → webhook → `accepted` | **PASS** — [`mcp_section_2_3_stage5_1_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_1_2026-06-06.json) |
| История за сегодня после card оплаты | **PASS** — [`mcp_section_2_3_stage5_2_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_2_2026-06-06.json) |

### §2.3 — итог (**done**, апрув 2026-06-06)

| Поле | Значение |
|------|----------|
| **Статус** | **done** — апрув заказчика («всё норм, если что позже вернётся») |
| Закрытие 5.3 | [`mcp_section_2_3_stage5_3_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_stage5_3_2026-06-06.json) |
| Сводка | [`mcp_section_2_3_summary_2026-06-06.json`](artifacts/demo-feedback/mcp_section_2_3_summary_2026-06-06.json) |
| Retest Fly | `fly:callback_smoke` order `b697b433-…`; `fly:stage5_2_smoke` order `38eed006-…` |
| Дальше | Блок 2 — табло баристы |

### §2.4 — приёмка (MCP Fly 2026-06-04)

| Критерий | Статус |
|----------|--------|
| 2× «Оплатить» → один редирект на Т-Банк | **PASS** |
| Второй клик при «Идёт оплата…» | **blocked** (кнопка disabled) |
| Подсчёт дублей заказов в БД на Fly | **PASS** (`db_orders_count: 1`, тел. `+79001112244`) |

### §2.5 — приёмка (MCP Fly Slow 3G, 2026-06-04)

| Критерий | Статус |
|----------|--------|
| При загрузке меню — скелетон, не белый экран | **PASS** (boot HTML + PageSkeleton, фон `#1a1a1a`) |
| Boot skeleton не залипает после загрузки | **PASS** post-deploy `ca6f2ef` — `boot_with_menu: 0` |
| Оверлей «Загрузка данных…» при долгом fetch (>5 с) | **код есть**; на Slow 3G меню <5 с |
| Тест в подвале (живой) | **не делали** — Slow 3G DevTools |

### §2 A↔B — приёмка (MCP Fly 2026-06-04)

| Критерий | Статус |
|----------|--------|
| Заказ на B в БД | **PASS** |
| На A заказа B нет | **PASS** |
| Возврат на B — заказ на месте (API + UI) | **PASS** |
| Fix legacy customer на чужой точке | **код** `CustomerSession` |

### Franchise / staff — приёмка (MCP Fly 2026-06-04)

| Критерий | Статус |
|----------|--------|
| `franchise@` — в сайдбаре нет «Персонал» | **PASS** |
| `franchise@` — `/manager/staff` → редирект `/manager` | **PASS** |
| `gm-a@` — «Персонал» в сайдбаре | **PASS** |
| Код + тест RBAC | `7311338`, `62ced8e` |

### Вне §2.3 / не блокирует закрытие (зафиксировано)

| Что | Почему |
|-----|--------|
| Стрелка «назад» на экране банка | UI Т-Банка, не наша витрина |
| 100% свой UI без iframe | PCI / отдельная задача |
| Реальное списание prod-картой в MCP | prod terminal + sandbox-карта → `ACTIVATION_ERROR` |
| SBP QR ручной прогон | Код есть; smoke не делали |
| §2.5 тест в подвале (физический) | **не делали** — только Slow 3G DevTools |

## УК: фото товара — «Введите URL» при сохранении (2026-06-07)

**Симптом:** заказчик меняет цену (например 295 → **2,95 ₽** для теста оплаты), жмёт «Сохранить» — браузер не отправляет форму, подсветка поля «Фото по ссылке», tooltip **«Введите URL»**.

**Причина:** после загрузки файла в БД путь **`/uploads/products/…`**, а в форме было `input type="url"` — HTML5 требует `https://…`. Фото **не обязательно** на сервере.

**Исправление (код):** `app/views/platform/menu/_category_section.html.erb`, `index.html.erb` — `type="text"`, подпись «необязательно».

**Обход до деплоя:** очистить поле «Фото по ссылке» → сохранить цену; или перезагрузить фото файлом.

**Проверка:** `bin/rails test test/integration/platform/uk_menu_product_image_url_form_test.rb`

---

## УК: где «пользователи» (для агента)

- В `/admin` **нет** пункта меню «Пользователи».
- Путь УК: **Точки** → карточка точки → **«Панель менеджера»** / **«Создать staff →»** → `/manager/staff` (список email + роли).
- Дашборд УК: ссылки **«Панель менеджера»** в таблице точек — то же самое.
- Франчайзи: только `/manager` (не `/admin`); **«Персонал» скрыт** — staff только у УК/GM (`7311338`, MCP [`mcp_franchise_staff_fly_2026-06-04.json`](artifacts/demo-feedback/mcp_franchise_staff_fly_2026-06-04.json)).

---

## Не баг (зафиксировано)

| Тема | Решение |
|------|---------|
| Смена на витрине/киоске без открытой смены | **wontfix до В2+** — в PDF «будет позже»; бариста со сменой — как в `ORDER_ENTRY_AUDIT` |
| Вход `franchise@` в §1.1 вместо `uk@` | Ожидание сценария УК — отдельно; `franchise@` = кабинет менеджера, не `/admin` |

---

## Закрытие §E

- PDF заказчика: [`customer_qa_prog10_2026-06.pdf`](artifacts/demo-feedback/customer_qa_prog10_2026-06.pdf) (+ `*_ru.pdf`) — **в репо, учтён**.
- Апрув по пунктам очереди — **не нужен** (внутренний достаточен).

---

## Шаблон новой строки

```
| YYYY-MM-DD | имя | где | что изменить | open | — |
```
