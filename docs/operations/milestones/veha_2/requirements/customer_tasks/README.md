# Задачи заказчика (отдельные ТЗ)

Полные тексты требований заказчика — **здесь**. В [`CUSTOMER_BUSINESS_REQUIREMENTS.md`](../CUSTOMER_BUSINESS_REQUIREMENTS.md) — только индекс, потоки и последовательность.

| ID | Задача | Статус | Файл |
|----|--------|--------|------|
| **B1.7** | Доработка экрана оформления заказа (checkout) | **закрыта** · апрув `[x]` 2026-06-04 | [B1_7_checkout_order_screen.md](B1_7_checkout_order_screen.md) |
| **B1.10** | Убрать «Блог» из навигации витрины | **закрыта** · апрув `[x]` 2026-06-18 | [B1_10_remove_blog_nav.md](B1_10_remove_blog_nav.md) |
| **B2.1** | **B2-S1:** звук нового заказа на табло | **CLOSED OPS** · MCP 9/9 · deploy `[x]` 2026-06-17 · апрув `[ ]` | [B2_1_barista_order_board.md](B2_1_barista_order_board.md) § B2-S1 |
| **B1.9** | Toggle-модификаторы на карточке товара | **закрыта** · апрув `[x]` 2026-06-18 | [B1_9_product_modifier_toggle.md](B1_9_product_modifier_toggle.md) |
| B1.1 | Экран уведомления заказа + прогресс-бар | PASS 2026-06-10 · ревизия R0–R4 Fly `[x]` · заказчик `[x]` 2026-06-18 | [B1_1_order_status_progress.md](B1_1_order_status_progress.md) |
| **B2.1** | **Табло бариста — интерактивная карточка** | **закрыта** · апрув `[x]` 2026-06-18 | [B2_1_barista_order_board.md](B2_1_barista_order_board.md) |
| **B1.11** | **Режим работы точки** (УК → витрина → табло) | код MVP `[x]` · **B1.11-BUG-OVERNIGHT** open · апрув `[ ]` | [B1_11_tenant_operating_hours.md](B1_11_tenant_operating_hours.md) |
| **UserCards wipe→new** | Сохранение карты после оплаты (`save_card=true`) — **чистый лист** | ТЗ `[x]` · код снесён · реализация `[ ]` | [Исправление сохранения карты в UserCards после успешной оплаты.md](Исправление%20сохранения%20карты%20в%20UserCards%20после%20успешной%20оплаты.md) |
| **B1.13** | **Новая навигация витрины** — эпик S1–S4 | **rev2** `[x]` апрув 2026-07-01 · **S4-канон** docs `[x]` · **S4 код** `[ ]` | [B1_13_shop_nav_profile_header.md](B1_13_shop_nav_profile_header.md) |
| **B1.14** | **Адрес точки + выбор точки** в шапке витрины (заказчик «задача 2») | **B1.14-3 Header** `[x]` 2026-06-23 · cart `[ ]` | [B1_14_shop_tenant_address_header.md](B1_14_shop_tenant_address_header.md) |
| B2.2 | Объединить «Меню» + «Создать» | **ТЗ** 2026-06-10 · реализация `[ ]` | [B2_2_barista_menu_create_merge.md](B2_2_barista_menu_create_merge.md) |
| **B1.4** | **PWA витрины** (install, offline) | **OPS_PASS** 2026-06-12 · заказчик `[ ]` | [B1_4_pwa_shop.md](B1_4_pwa_shop.md) |
| **Hidden mode cards** | Режим **hidden**: crop превью товаров (эталон vs «как сейчас») | **ТЗ `[x]`** · скрины `[x]` · код `[ ]` · апрув `[ ]` | [Исправление режима отображения Hidden для карточек товаров.md](Исправление%20режима%20отображения%20Hidden%20для%20карточек%20товаров.md) |

**Порядок работ:** апрув ТЗ Hidden → **go** код · новое ТЗ UserCards (после `go`) · **B1.13 S4** · **B1.14-4** · **B2.2** · **B1.4**.

