# Artifacts — TASK_91 post-pay auto return → catalog + status model

Скрины / MCP / evidence для автоматического возврата на `#/` после завершения post-pay email-флоу.

**ТЗ:** [`../requirements/customer_tasks/TASK-91-Автоматический-возврат-на-каталог-после-post-pay-email.md`](../../requirements/customer_tasks/TASK-91-Автоматический-возврат-на-каталог-после-post-pay-email.md)  
**Google Doc:** https://docs.google.com/document/d/1nlWXyWV0UcV5X33i0owZixXRJl5d-nF_HwHdjjBVd2o/edit  
**Связь:** #71 email after pay · #35 Continue → catalog · заказчик п.9.2

## screenshots/

| Файл | Что |
|------|-----|
| `01_stuck_payment_result_receipt_to_catalog.png` | После оплаты через карточку: «✔ Чек сформирован» + ручной CTA «В каталог»; статусная модель не открыта |
| `02_desired_catalog_status_sheet.png` | Каталог `#/` + шторка статуса (принят/оплачен/…); эталон желаемого конца |
| `03_status_model_after_autopay_or_cancel_case.png` | Статусная модель поверх каталога (заказчик: автоплатёж/повтор без «В каталог»; на кадре также кейс отмены/возврата) |

Источник: чат заказчика 2026-09-17 (повторная выгрузка скринов).

**GATES (unlazy TASK_91):** [`GATES.md`](GATES.md) — G1–G3 met · G4 Fly pending (session `GATES.md` может быть у другой задачи).

## mcp/

Fly MCP Point A — после REVIEW/deploy.
