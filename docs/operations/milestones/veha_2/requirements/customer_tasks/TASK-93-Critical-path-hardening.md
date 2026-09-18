# TASK_93: Critical path hardening — деньги, витрина, ops

**ID заказчика:** TASK_93 · **CBR:** #93 · **Дата intake:** 2026-09-18  
**Источник:** готовое ТЗ (чат) под цепочку `/start` → `/spec` → `/sbr` → `/regress` → `/review`  
**Артефакты:** docs/operations/milestones/veha_2/artifacts/critical_path_hardening/  
**Нарезка:** TASK_93-A … TASK_93-L (блоки A–L). Не отдельные #94+.  
**Сейчас:** TASK_93-A — Блок A (деньги ↔ заказ)

---

## Текст заказчика (дословно)

## Зонтик (одно имя на все блоки)

| Поле | Значение |
|------|----------|
| **ID** | **TASK_93** |
| **Название** | Critical path hardening — деньги, витрина, ops |
| **CBR #** | `#93` |
| **Нарезка** | `TASK_93-A` … `TASK_93-L` (блоки A–L из плана). Не отдельные `#94+`. |
| **Сейчас делаем** | **TASK_93-A** — Блок A (деньги ↔ заказ) |
| **Дальше** | B → C → D → … → L (deploy) отдельными SBR-прогонами на том же `#93` |

Title чата: `Задача 93 — Critical path hardening (блок A)`.

---

# TASK_93-A — Блок A: Деньги ↔ заказ (склад + webhook)

## 1. Зачем

После hard-fail в `Inventory::OrderRecipeDeduction` (коммит `e02b527`) webhook `CONFIRMED` может **откатить** txn: деньги в банке есть, `payment`/`order` снова pending, бариста заказа не видит. Особенно на точках **без заведённого склада** (`find_or_create` → `qty=0` → Error).

## 2. Цель блока (одна фраза)

**Банк подтвердил оплату → у нас всегда `payment.succeeded` + заказ `accepted` (у баристы). Склад/рецепт никогда не откатывает оплату.** Проблемы склада → алерт/инцидент, не «тихая потеря денег».

## 3. Scope / Non-scope

**В scope (A1–A6):**
- `Callbacks::PaymentStatusUpdater`
- `Inventory::OrderRecipeDeduction` (+ политика missing/zero stock)
- Вызовы в `Barista::OrderCreationService`, `Shop::OrderCreator` (одинаковый soft-fail)
- Алерт при blank `Amount` / amount mismatch (T‑Bank path)
- Edge: succeeded на заказ не `pending_payment` (cancelled/closed)

**Вне scope (другие блоки TASK_93):** phone vs email, SMS host, per_page, Init race, RLS schema, cart cookie, OTP, push, deploy.

## 4. Продуктовые правила (зафиксировать в SPEC)

| Правило | Решение |
|---------|---------|
| R1 | Недостаток/отсутствие стока **не** откатывает `payment.succeeded` и `order.accepted` |
| R2 | Нет строки `IngredientTenantStock` / склад не заведён → **не** создавать ловушку `qty=0`→Error; **skip deduct** + алерт |
| R3 | Стока не хватает (строка есть) → **не deduct** + алерт; payment/order уже confirmed остаются |
| R4 | Happy path со стоком → deduct как сейчас |
| R5 | Barista create + Shop `OrderCreator` (сразу accepted) + PaymentStatusUpdater — **одна политика**: оплата/принятие заказа не откатывается из‑за склада |
| R6 | Blank `Amount` на CONFIRMED / GetState mismatch → **не silent**; лог + Sentry/`Rails.error.report` (или существующий audit). Поведение статуса платежа: **не ослаблять** проверку суммы без отдельного апрува — только видимость |
| R7 | `succeeded` пришёл, заказ уже `cancelled`/`closed` (не `pending_payment`) → **не quiet return**: `AdminAuditLog` (или аналог) + путь к refund **или** явный «needs_refund» флаг/джоба. Минимум DoD: алерт+audit, чтобы ops видел; полный auto-refund — если уже есть сервис, подключить; иначе зафиксировать `needs_manual_refund` в логе |

## 5. Файлы (ожидаемо) — для `/spec`

```
app/services/callbacks/payment_status_updater.rb
app/services/inventory/order_recipe_deduction.rb
app/services/barista/order_creation_service.rb
app/services/shop/order_creator.rb
app/services/payments/tbank_adapter.rb          # A4 blank Amount / matches?
app/services/payments/tbank_payment_sync.rb     # A4 GetState mismatch alert
app/controllers/callbacks/tbank_controller.rb   # только если алерт на входе webhook

test/services/callbacks/payment_status_updater_test.rb
test/services/inventory/order_recipe_deduction_test.rb
test/services/barista/order_creation_service_test.rb   # или существующий зеркальный
test/services/shop/order_creator_* / integration stock
test/jobs/payments/tbank_callback_job_test.rb
test/controllers/callbacks/tbank_controller_test.rb
test/integration/block_f_stock_flow_test.rb     # согласовать с новой политикой
```

## 6. Не ломать

1. Happy path: CONFIRMED → succeeded + accepted + deduct при достаточном стоке.  
2. Amount mismatch по-прежнему **не** подтверждает платёж.  
3. Subscription intent (#78) — по-прежнему closed + fulfill, не barista accepted.  
4. Failed/REJECTED → cancel + journal как сейчас.

## 7. Матрица приёмки A1–A6 ↔ тесты

Каждый пункт закрыт **конкретным** тестом. Блок A = **все** строки PASS.

### A1 — PaymentStatusUpdater не откатывает оплату

| ID | Тест (имя) | Arrange | Assert |
|----|------------|---------|--------|
| **T-A1a** | `succeeded accepts order even when recipe deduction would fail (insufficient stock)` | order `pending_payment` + items с рецептом; stock qty меньше needed; `PaymentStatusUpdater#call!(succeeded)` | `payment.status == succeeded`, `order.status == accepted`, stock **не** ушёл в минус; **нет** uncaught Error; есть лог/audit/incident о складе |
| **T-A1b** | `succeeded accepts order when stock row missing (no find_or_create trap)` | рецепт есть, **нет** `IngredientTenantStock`; updater succeeded | payment succeeded, order accepted; **не** создана строка qty=0 ради Error; алерт/audit есть |

Файл: `test/services/callbacks/payment_status_updater_test.rb`  
(доп.) через job: `test/jobs/payments/tbank_callback_job_test.rb` — CONFIRMED payload → те же финальные статусы при bad stock.

### A2 — Политика стока в OrderRecipeDeduction

| ID | Тест | Assert |
|----|------|--------|
| **T-A2a** | `skips deduct and reports when stock row absent` | нет raise «для rollback»; нет новой строки qty=0→fail; результат/side-effect алерта проверяем (counter `AdminAuditLog` / `Rails.error.report` stub) |
| **T-A2b** | `does not deduct when insufficient; signals shortfall` | qty не меняется; сигнал ошибки/soft-result (по выбранному API: Error ловится снаружи **или** Result) |
| **T-A2c** | `deducts when stock sufficient` | qty уменьшается как сейчас (регрессия) |

Файл: `test/services/inventory/order_recipe_deduction_test.rb`  
Обновить текущий `raises when stock is insufficient`: либо Error остаётся **только** как сигнал, либо callers обязаны rescue — но **updater/barista/shop** не откатывают бизнес-статус (см. A3).

### A3 — Одинаковое поведение barista + OrderCreator

| ID | Тест | Assert |
|----|------|--------|
| **T-A3a** | barista create accepted + insufficient/missing stock | заказ **создан/accepted** (или явный продуктовый 422 — но тогда **тот же** контракт, что shop; запрещено: barista soft, shop hard или наоборот без документа). **Канон блока:** заказ принимается, склад алертом — как payment path |
| **T-A3b** | shop OrderCreator flow с `order_status: accepted` + bad stock | order accepted / payment path не откатан; нет 500/`InFailedSqlTransaction` из-за deduction |

Зеркала: `test/services/barista/...`, `test/integration/block_f_stock_flow_test.rb` — **переписать** ожидание «hard-fail → shop 422», если оно противоречит R5.

### A4 — Blank Amount / mismatch не молчат

| ID | Тест | Assert |
|----|------|--------|
| **T-A4a** | `notification_amount_matches? false when Amount blank` | уже/оставить `false` |
| **T-A4b** | `reports error when CONFIRMED/GetState has blank Amount or mismatch` | при вызове sync/callback path с blank Amount или wrong Amount — `Rails.error.report` **или** `AdminAuditLog` / Sentry stub **вызван** (≥1); платёж **не** succeeded при mismatch (как сейчас) |

Файлы: `tbank_adapter_test`, `tbank_payment_sync_test`, `tbank_callback_job_test`.

### A5 — Сводка сценариев webhook (интеграция)

| ID | Тест | Assert |
|----|------|--------|
| **T-A5a** | CONFIRMED + empty/missing stock | succeeded + accepted |
| **T-A5b** | CONFIRMED + insufficient stock | succeeded + accepted; stock unchanged |
| **T-A5c** | CONFIRMED + enough stock | succeeded + accepted; stock deducted |

Желательно один файл: `test/integration/shop/payment_confirmed_stock_test.rb` **или** расширить `tbank_controller_test` / callback job — главное три сценария рядом.

### A6 — Succeeded на не-pending_payment

| ID | Тест | Assert |
|----|------|--------|
| **T-A6a** | `succeeded on cancelled order does not quiet-return without audit` | order `cancelled`, payment pending→updater succeeded | payment: зафиксировать явный исход (succeeded + `needs_refund` audit **или** не succeeded + failed с reason — выбрать одно в GREEN и держать); **обязательно** `AdminAuditLog`/эквивалент с reason вроде `payment_on_non_pending_order`; **запрещено** «статусы как были и ноль следов» |
| **T-A6b** | то же для `closed` | аналогично |

Если подключаете auto-refund сервис — **T-A6c**: enqueued refund job / вызов refund service. Без сервиса — T-A6a/b достаточно для закрытия A6 в рамках «явный fail + алерт».

## 8. Команды проверки (для todo «Проверка»)

```bash
bin/rails test test/services/callbacks/payment_status_updater_test.rb \
  test/services/inventory/order_recipe_deduction_test.rb \
  test/jobs/payments/tbank_callback_job_test.rb \
  test/controllers/callbacks/tbank_controller_test.rb \
  test/integration/block_f_stock_flow_test.rb
# + новые файлы A5/A6
```

Регресс зоны после GREEN:

```bash
bin/rails test test/services/payments/ test/services/callbacks/ test/jobs/payments/
```

## 9. Definition of Done — Блок A закрыт только если

- [ ] Все тесты **T-A1a … T-A6b** (и T-A5*) зелёные  
- [ ] В коде updater: deduction **не** откатывает `with_lock` txn оплаты  
- [ ] Нет пути `find_or_create(qty:0)` → Error на каждом заказе без склада  
- [ ] barista / OrderCreator / updater — одна политика (A3)  
- [ ] Blank Amount / mismatch — есть report/audit (A4)  
- [ ] cancelled/closed + succeeded — не quiet (A6)  
- [ ] `/regress` зоны payments/callbacks PASS  
- [ ] В отчёте REVIEW: таблица A1–A6 | тест ID | PASS  
- [ ] **Не** требуем deploy в DoD блока A (это **TASK_93-L**); но Local PASS обязателен  

**Блок A ≠ «написали rescue и забыли A6».** Нет строки в матрице → блок не закрыт.

## 10. SBR-цикл именно для 93-A

| Фаза | Что |
|------|-----|
| `/start` | intake: этот текст → `TASK-93-Critical-path-hardening.md` + секция **Блок A**; CBR строка `#93`; артефакты `artifacts/critical_path_hardening/` |
| `/spec` | todo: файлы + Не ломать + Проверка + чеклист A1–A6 |
| `/sbr` RED | только падающие T-A*; коммит `[RED]` |
| `/sbr` GREEN | реализация A1–A6; коммит `[GREEN]`; все T-A* зелёные |
| `/regress` | команды §8 |
| `/review` | таблица A1–A6 PASS; push PHASE 3; **deploy нет** без апрува |

---

## Карта остальных кусков того же TASK_93 (имена для следующих SBR)

| ID | Блок | Одна строка |
|----|------|-------------|
| TASK_93-A | Деньги ↔ заказ | **этот прогон** |
| TASK_93-B | Checkout phone vs email | identityReady = backend |
| TASK_93-C | SMS short link / hosts | живая ссылка |
| TASK_93-D | orders history per_page | default ≠ 1 |
| TASK_93-E | Init idempotency / txn | provider_payment_id |
| TASK_93-F | Events / StuckPayments | claim + GetState |
| TASK_93-G | GUC / RLS / structure | SET LOCAL + policies |
| TASK_93-H | Cart cookie overflow | не 500 |
| TASK_93-I | OTP / Rack::Attack store | shared limits |
| TASK_93-J | Push / worker / SMS_GRACE | async + cascade |
| TASK_93-K | Hygiene | blog sanitize, demo pwd, … |
| TASK_93-L | Deploy + Point A MCP | апрув |

---

## Как поймёшь, что A реально закрыт

Прогон одной командой по списку файлов §8 → **0 fail**, и в чате после REVIEW таблица:

```
A1 T-A1a T-A1b     PASS
A2 T-A2a T-A2b T-A2c PASS
A3 T-A3a T-A3b     PASS
A4 T-A4a T-A4b     PASS
A5 T-A5a T-A5b T-A5c PASS
A6 T-A6a T-A6b     PASS
```

Без этой таблицы блок не считать сделанным.

---

Дальше: переключись в Agent и скажи **`/start`** (или «intake TASK_93-A») — положит док + CBR. Потом **`/spec`** по этому тексту.  
Если номер `#93` занят/неудобен — скажи другой ID, текст тот же.
