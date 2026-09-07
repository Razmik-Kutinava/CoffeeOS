# MCP Plan — #26 step5: inline при отказе банка (Point A)

**Для агента:** выполнить **после** одного общего `fly deploy` (этот агент **не** деплоит).  
**Не** Local-only: только Fly Point A.

| Поле | Значение |
|------|----------|
| **CBR / задача** | #26 QA reopen · шаг 5 (ошибка оплаты → надпись пользователю) |
| **ТЗ** | [`customer_tasks/Главный экран — повторный заказ (невалидный токен)…`](../../requirements/customer_tasks/Главный%20экран%20—%20повторный%20заказ%20(невалидный%20токен)%20BottomSheet%20выбора%20способа%20оплаты.md) |
| **UX-тексты** | [`Понятные сообщения пользователю при ошибке оплаты.md`](../../requirements/customer_tasks/Понятные%20сообщения%20пользователю%20при%20ошибке%20оплаты.md) |
| **Код (уже на develop)** | GREEN `32c79960` · REVIEW CI green |
| **Point A** | `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Артефакты out** | `docs/operations/milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/mcp/fly_vXXX_YYYY-MM-DD/` |
| **QA as-is баг** | `screenshots/qa_2026-09-06/01_bug_sheet_pay_no_inline_bank_error_message.png` |

---

## Premortem (что чинили)

| Было (баг заказчика) | Стало (ожидание MCP) |
|----------------------|----------------------|
| Банк отбивает карту, **нет** пояснения над CTA | Inline `data-testid="payment-method-inline-error"` с понятным текстом |
| После отказа снова «Оплатить» без текста | Шторка **не** закрывается; выбранная карта **остаётся** selected |
| Auto-open NewCardForm стирал copy | Форма новой карты **не** открывается сама; открытие — по клику CTA / «Картой +» |

**Канон текстов (строго, без ErrorCode / «Failed to fetch»):**

| FSM | Текст в inline (и/или на CTA) |
|-----|-------------------------------|
| Карта / недостаточно средств / блок / срок | `Недостаточно средств, или карта заблокирована банком, или истёк срок действия карты` |
| Сеть | `Нет связи. Повторить` |
| Сбой банка / 5xx | `Сбой банка: позже` |

---

## Preflight (до сценариев)

1. Подтвердить **Fly release** после общего deploy (`fly status` / release notes) — код `32c79960+` на стенде.
2. Открыть витрину Point A: shop URL с `tenant_id=2fdee1ac-4674-41ee-b89e-87b45643f789`.
3. Viewport mobile (~390×844).
4. Гость/сессия с **сохранённой картой** (лучше карта с малым балансом / известный decline — как *5953 historically; иначе любая saved card + живой decline банка).
5. Корзина непустая (дешёвый товар Point A ок).

---

## Сценарии MCP (обязательные)

### M1 — Открыть шторку «Способ оплаты»

| | |
|--|--|
| **Given** | Главный / checkout · есть saved card · корзина готова к оплате |
| **When** | Открыть pay-stack / PaymentMethodsSheet (через «Оплатить» / «Добавить карту» / repeat → sheet — любой канон-вход в `#/checkout` pay-stack) |
| **Then** | Заголовок «Способ оплаты» · список карт · «СБП» · «Картой +» · CTA видна · **ещё нет** `payment-method-inline-error` |
| **Evidence** | screenshot `01_sheet_open_before_pay.png` |
| **PASS/FAIL** | |

### M2 — Отказ банка → inline (P0 / суть #26 step5)

| | |
|--|--|
| **Given** | M1 · выбрана saved card (оранжевая рамка) |
| **When** | Тап CTA «Оплатить» → бэк/банк возвращает отказ по карте (недостаточно средств / CLIENT_ERROR / 422 с card ErrorCode) |
| **Then** | 1. BottomSheet **остаётся открытым** 2. Появляется **inline** над CTA: `data-testid="payment-method-inline-error"` 3. Текст = канон карты (см. таблицу выше) — **не** raw `Failed to fetch`, **не** ErrorCode (`1051` и т.п.) 4. Выбранная карта **всё ещё selected** 5. NewCardForm **не** открылась сама 6. CTA снова кликабельна (не залипла в loading) |
| **Evidence** | screenshot `02_decline_inline_error.png` · DOM assert testid · (опц.) network one_click 4xx |
| **PASS/FAIL** | |
| **Blocker если** | нет inline · sheet закрылся · сразу форма новой карты · сырой technical message |

### M3 — CTA после отказа → смена карты (не silent retry)

| | |
|--|--|
| **Given** | M2 (CLIENT_ERROR / card decline, inline виден) |
| **When** | Тап по CTA (кнопка в состоянии ошибки карты) |
| **Then** | Открывается флоу **новой карты** (`NewCardForm` / «Картой +» selected) — **не** повторное списание с той же карты без выбора |
| **Evidence** | screenshot `03_cta_opens_new_card.png` |
| **PASS/FAIL** | |

### M4 — Альтернатива: «Картой +» вручную

| | |
|--|--|
| **Given** | M2 · inline виден · saved card selected |
| **When** | Тап «Картой +» |
| **Then** | Форма новой карты · inline может сброситься при смене selection (ок) · sheet не закрыт |
| **Evidence** | screenshot `04_manual_card_plus.png` |
| **PASS/FAIL** | |

### M5 — Закрытие шторки (регресс шага 6)

| | |
|--|--|
| **Given** | Sheet открыт (после M2 или M1) |
| **When** | X или swipe down |
| **Then** | Sheet закрыт · возврат к peek/checkout без краша |
| **Evidence** | screenshot `05_sheet_closed.png` |
| **PASS/FAIL** | |

### M6 — Smoke: happy-path не сломан (мягкий)

| | |
|--|--|
| **Given** | Карта/сумма, с которой оплата **может** пройти (или SKIP с причиной) |
| **When** | Успешная оплата one_click |
| **Then** | Успех / редирект payment-result · **нет** ложного inline |
| **Evidence** | screenshot или `SKIP: no funded card on Point A` |
| **PASS/FAIL** | |

---

## Опционально (если успеете)

| ID | Что | Then |
|----|-----|------|
| M7 | Симулировать offline / abort → NET | Inline «Нет связи. Повторить» · CTA retry |
| M8 | 5xx / BANK_ERROR | Inline «Сбой банка: позже» |
| M9 | Регресс G1–G4 UI листа | Как канон `09_customer_payment_methods_sheet_canon_2026-08-13.png` |

---

## Запрещено / Не ломать (чеклист агента)

- [ ] Не трогать auth store / refresh-токены
- [ ] Не деплоить повторно без апрува (deploy уже сделан другим агентом)
- [ ] Не считать PASS Local-only
- [ ] Не PASS при technical leak в UI
- [ ] Не портить профиль заказчика тестовым OTP без нужды — Point A guest/demo

---

## Артефакты (обязательный выход)

Папка:

`docs/operations/milestones/veha_2/artifacts/repeat_order_invalid_token_payment_sheet/mcp/fly_v<VER>_<YYYY-MM-DD>/`

| Файл | Содержание |
|------|------------|
| `MCP_RESULT.md` | таблица M1–M6 PASS/FAIL/SKIP + Fly version + URL Point A + sha/release |
| `*.png` | скрины по сценариям |
| (опц.) `mcp_result.json` | machine-readable итог |

**DoD MCP для #26 step5:** **M2 = PASS** (остальное — желательно; M6 может SKIP с причиной).

---

## Отчёт агенту-владельцу (шаблон)

```
#26 step5 MCP Point A
Fly: v___ · release ___
M1 ___ · M2 ___ · M3 ___ · M4 ___ · M5 ___ · M6 ___
Artifacts: …/mcp/fly_v___/
Blockers: …
```

После PASS — обновить CBR #26 `MCP [x]` и строку в `artifacts/…/README.md` (история MCP).
