# todo — #33 clarification: fallback vs expanded (SPEC 2026-08-07)

**ТЗ:** [`customer_tasks/Интеграция виджета быстрой оплаты Т-Кассы и One-Click сценария в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Интеграция%20виджета%20быстрой%20оплаты%20Т-Кассы%20и%20One-Click%20сценария%20в%20PWA.md)  
**Артефакты:** [`tbank_widget_oneclick_fallback/`](../milestones/veha_2/artifacts/tbank_widget_oneclick_fallback/) · скрины `07` (as-is mixed), `08` (expanded = fullscreen)  
**Стек:** `RepeatSection` · `InlinePayFallback` · `widgetRepeatPayFlow.js` · `shopWidgetPayFsm.js`  
**Связанный:** #46 bank auth limit (`ErrorCode` 119) — GREEN `327e8767`; push/MCP отдельно

---

## Логи / as-is (2026-08-07)

| Источник | Факт |
|---|---|
| Fly `coffeeos` | `POST /callbacks/tbank` · `Status=REJECTED` · `ErrorCode=119` · `Pan=…5953` · `Amount=295` |
| MCP v439 | G7 live: rate-limit → не insufficient; unit G7 PASS |
| Код | `widgetRepeatPayFlow` на любой ERROR: `showFallbackMethods=true`; в `catch` ещё `showExpandedCards=true` |
| `RepeatSection` catch | сразу `showFallbackMethods` + `showExpandedCards` + `showNewCardForm` = true |

**Вывод:** после отказа банка UI сразу показывает **fallback (СБП / карта +)** и **expanded (Картой *5953)** вместе — это скрин **07** (не канон).

---

## Канон состояний (заказчик 2026-08-07)

| # | Состояние | UI | Скрин |
|---|---|---|---|
| S0 | Idle, карта есть | Одна кнопка оплаты; статусы банка **внутри** кнопки/плашки; **нет** СБП / «карта +» | 01–02 |
| S1 | Отказ карты (нет денег / 1051 / отказ эмитента / 119 card-related) | Плашка ошибки + **только** «СБП» и «карта +»; **без** списка карт / формы | 03 · as-is broken = **07** |
| S2 | Тап «карта +» | Expanded / fullscreen: сохранённые карты + «Картой +» + форма новой карты + «Оплатить» | **08** (= макет expanded, не дефолт) |

**Явно:** скрин **08** = режим expanded шторки, **не** базовый чекаут.

---

## Gaps

| ID | Gap | Prio | Статус |
|----|-----|------|--------|
| **F1** | На ERROR/FALLBACK: `showFallbackMethods=true`, **`showExpandedCards=false`**, **`showNewCardForm=false`** (пока не тап «карта +») | P0 | `[ ]` |
| **F2** | `onFallbackCardPlus` → expanded (карты + форма) — уже есть; закрепить тестом | P0 | `[ ]` |
| **F3** | `RepeatSection` catch не открывает expanded/form сразу | P0 | `[ ]` |
| R1 | Happy-path: с картой нет fallback до ошибки (регрессия) | MUST | `[ ]` |
| #46 | 119 → CLIENT_ERROR / clear PaymentId | related | **GREEN `[x]`** этот шаг (отдельный коммит) |

---

## План SBR

### RED
1. Тест `widgetRepeatPayFlow` / helper: reject → fallback methods **без** expanded/form  
2. Тест: после `card+` → expanded+form  
3. Коммит `test: … [RED]`

### GREEN
1. `widgetRepeatPayFlow.js` + `RepeatSection.svelte` catch — не ставить expanded/form на ошибке  
2. Регрессия JS widget/repeat + shop zone при касании  
3. Коммит `feat: … [GREEN]`

### REVIEW
Ops + отчёт: «макет expanded ≠ дефолт; чиним момент появления СБП/карта+ vs список карт»

---

## Exit Criteria

1. `[ ]` S1: ошибка → только статус + СБП/карта+  
2. `[ ]` S2: тап карта+ → expanded как скрин 08  
3. `[ ]` S0 регрессия: idle с картой без fallback  
4. `[ ]` Тесты зелёные · коммит GREEN · ops
