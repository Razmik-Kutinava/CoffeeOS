# NotificationFiscalization — схема (офиц. дока Т-Банк)

**Источник:** https://developer.tbank.ru/eacq/intro/developer/notification § «Фискализация (NotificationFiscalization)»  
**Дата фиксации:** 2026-08-27 (CoffeeOS #73)

## Детект

| Поле | Значение |
|------|----------|
| `Status` | всегда **`RECEIPT`** (статус фискализации) |
| Endpoint | тот же `NotificationURL` терминала → у нас `POST /callbacks/tbank` |

## Ключевые поля (сохраняем)

| Поле | Назначение |
|------|------------|
| `PaymentId` / `OrderId` | mapping на внутренний payment/order |
| `Url` | ссылка на копию чека |
| `FnNumber` | номер ФН |
| `FiscalDocumentNumber` | ФД |
| `FiscalDocumentAttribute` | ФП |
| `Type` | признак расчёта (приход / возврат / …) |
| `Receipt` | вложенный объект (в Token **не** входит) |
| raw JSON | весь payload для диагностики |

## Идемпотентность

Комбинация: `PaymentId` + `FnNumber` + `FiscalDocumentNumber` + `FiscalDocumentAttribute` → `ofd_receipt_id`.

## Ответ

HTTP 200, тело **`OK`** (plain text).

Пример payload: [`notification_fiscalization.example.json`](notification_fiscalization.example.json)
