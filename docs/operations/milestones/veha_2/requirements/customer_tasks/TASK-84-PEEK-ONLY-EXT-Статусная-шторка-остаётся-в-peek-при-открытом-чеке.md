# TASK_84-PEEK-ONLY-EXT: Статусная шторка остаётся в peek при открытом чеке

**ID:** TASK_84-PEEK-ONLY-EXT · **семья:** TASK_84 · **Дата intake:** 2026-10-01  
**Источник:** владелец (чат 2026-10-01), сценарий по черновику агента — аудит TASK_83/84 § 6 «Только peek»  
**Расширяет:** [`TASK-84-RECEIPT-DISPLAY-EXT-…`](TASK-84-RECEIPT-DISPLAY-EXT-Восстановление-фактического-отображения-состава-чека-в-ActiveOrdersAccordion.md)  
**Реверсирует:** переход статусной шторки в `expanded` при открытом чеке (`OrderStatusSheet.svelte` `panelExpanded` → `ORDER_STATUS_SHEET_MODES.EXPANDED`, CSS `.oss__panel.expanded` / `.oss__panel.embedded.expanded`); защитный тест `test/integration/shop/order_status_sheet_mount_acceptance_test.rb` «…EXPANDED»  
**Тип:** дополнительная задача (EXT)  
**Статус:** SBR

---

## Сценарий владельца (дословно)

```gherkin
Сценарий: открытие чека не раскрывает шторку
  Дано на витрине есть активный заказ, шторка статуса в peek
  Когда пользователь нажимает «Состав заказа»
  Тогда шторка остаётся в peek (data-status-sheet-mode="peek", высота панели не растёт)
  И чек показывается внутри peek со своей прокруткой
  И Total Amount достижим прокруткой чека

Сценарий: закрытие чека
  Когда пользователь снова нажимает «Состав заказа»
  Тогда чек скрывается, шторка остаётся в peek
```

**Не трогать:** чек, ×, polling/Cable, CartSheet (если выбран вариант а).

## Решение по развилке

Вариант **(а)** — CartSheet не поднимается; чек вписывается в высоту peek (`fitReceiptInView`, минимум 64px) со своей прокруткой. Подъём CartSheet при открытом чеке — отдельная задача ([DEMO_FEEDBACK](../DEMO_FEEDBACK.md)).

## Subtask

- [x] 1. `statusSheetMode` при наличии заказов — только `peek` (открытый чек не даёт `expanded`)
- [x] 2. Высота панели при открытом чеке = высота peek (`min(22vh, 8.5rem)` embedded / `8.75rem` overlay); CSS роста `.expanded` удалён
- [x] 3. Панель при открытом чеке — scroll-контейнер (`overflow-y: auto`), чтобы чек вписывался в peek и `Total Amount` был достижим прокруткой чека
- [x] 4. Закрытие чека — шторка в peek
- [x] 5. Тесты: контракт «нет `expanded`» вместо «есть `EXPANDED`»; регрессия зоны шторки

**RED** `8f795504` (3 fail) → **GREEN** `8b75d868` · браузер 390×844 PASS — [MEASURE](../../artifacts/active_orders_receipt_display_restore/peek_only_2026-10-01/MEASURE.md)

## Scope

Разрешено: `app/frontend/components/OrderStatusSheet.svelte` (вычисление режима, класс панели, CSS панели); тесты.  
Запрещено: `ActiveOrdersAccordion.svelte` блок чека и `fitReceiptInView`, `lib/orderStatusSheet.js` (`ORDER_STATUS_SHEET_MODES` остаётся), `CartSheet.svelte`, backend, polling/Cable, `×`.
