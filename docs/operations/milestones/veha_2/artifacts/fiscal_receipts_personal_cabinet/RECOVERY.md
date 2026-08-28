# #73 — восстановление пропущенного fiscal notification

**Subtask 23** · ops runbook · 2026-08-28

## Когда применять

- Оплата `CONFIRMED`, в ЛК «Чек формируется» дольше разумного окна (обычно 5–15 мин).
- В `fiscal_receipts` нет строки для `payment_id` / `order_id`.
- В Fly logs нет `[Tbank::Callback] Fiscal RECEIPT` для этого `PaymentId`.

## Диагностика

1. **Fly logs:** `fly logs -a coffeeos` — искать `PaymentId`, `OrderId`, `Status=RECEIPT`.
2. **Neon:** `SELECT * FROM fiscal_receipts WHERE order_id = '…' ORDER BY created_at DESC;`
3. **Кабинет Т-Банка:** раздел уведомлений / архив — есть ли доставка fiscal notify на NotificationURL.
4. **Настройка терминала:** fiscal notifications **включены** на `https://coffeeos.fly.dev/callbacks/tbank`.

## Восстановление

| Шаг | Действие |
|-----|----------|
| 1 | Убедиться, что webhook path жив: invalid Token → **401**, тестовый `Status=NEW` → **200 OK** plain |
| 2 | В кабинете Т-Банка найти уведомление в архиве (срок хранения по доке банка: ретраи час → сутки → месяц) |
| 3 | Если payload есть — **повторная доставка** из кабинета или ручной `POST /callbacks/tbank` с валидным Token (только staging/test, не prod без апрува) |
| 4 | Идемпотентность: повтор не создаст дубликат (`ofd_receipt_id` unique) |
| 5 | Если архив пуст / срок истёк — эскалация в поддержку Т-Банка с `PaymentId`, `OrderId`, время оплаты |

## Out of scope

- Запрос чека через несуществующий API кассы по `PaymentId`.
- Генерация QR по ФН/ФД/ФП в PWA.
