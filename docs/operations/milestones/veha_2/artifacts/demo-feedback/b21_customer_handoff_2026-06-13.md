# B2.1 ревизия — пакет для приёмки заказчиком

**Дата:** 2026-06-13 · **Стенд:** https://coffeeos.fly.dev/barista  
**Логин:** `barista-a@demo.coffeeos.local` / `demo123456` (demo A)

## Что смотреть (5 минут)

Откройте папку со скринами (прогон 1.1–1.4):

[`screenshots/b21_revision_customer_mcp_2026-06-13/`](screenshots/b21_revision_customer_mcp_2026-06-13/)

| # | Проверка | Файл |
|---|----------|------|
| 1.1 | Сетка **2×3**, 6 карточек — **не** три колонки «Новые/Готовится/Готовы» | `01_board_6_slots_fly.png` |
| 1.2 | Тап: **белая** → **жёлтая** → **пропала** с табло | `02` … `04` |
| 1.3 | **Live без F5:** заказ с витрины сам появился на табло | `05_live_before_fly.png` → `06_live_new_order_fly.png` |
| 1.4 | **Лимит 6:** при 6 заказах 7-й не добавляется | `07_limit_6_full_board_fly.png` |

## Артефакт приёмки (ops)

[`b21_revision_acceptance_2026-06-12.json`](b21_revision_acceptance_2026-06-12.json) — `"verdict": "PASS"`, `"status": "PASS"`.

## После OK заказчика

- В репо: `customer_signoff: true` в JSON + галочки «Заказчик» в [`B2_1_barista_order_board.md`](../../requirements/customer_tasks/B2_1_barista_order_board.md).
- Следующая задача: **B2.2** (меню + создать).

## Вопросы (не блокируют приёмку ревизии)

| # | Вопрос | Статус |
|---|--------|--------|
| Q1 | Имя vs телефон на карточке (checkout email-first) | ждём ответ |
| Q2 | Поведение 7-го заказа (очередь / скрыт) | ждём ответ |
| Q3 | Overlay отмены заказа — оставляем из MVP? | ждём ответ |
