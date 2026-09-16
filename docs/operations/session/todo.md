# todo — #90 POSTCALL-EXT ROLLED BACK (wrong order)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#90** (Google: TASK_89-POSTCALL-EXT) |
| **Статус** | **ROLLED BACK** 2026-09-16 — сделали раньше UI-EXT, сломали очерёдность |
| **Почему** | Сначала **TASK_89-UI-EXT** (шторка / сумма), потом заново POSTCALL |
| **Код** | Откат `PhoneAuthCodeStep` / `phoneAuthCascade` / тесты #90 → pre-RED |
| **ТЗ** | [`TASK-89-POSTCALL-EXT-…md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-POSTCALL-EXT-Возврат%20в%20PWA%20после%20Callcheck%20и%20продолжение%20оплаты.md) — intake сохранён |
| **Google** | https://docs.google.com/document/d/1w2VKMPaYZdsJcqNkLrpSbJBPuLE-7Sm9giQ8DcJ0Bq0/edit?usp=drivesdk |

## SBR

- [x] PHASE 0 intake (док остаётся)
- [ ] PHASE 1 `/spec` — **заново после UI-EXT**
- [ ] PHASE 2 RED/GREEN — **не начинать**, пока UI-EXT не закрыт
- [ ] PHASE 3 `/review`

## Не ломать

1. #89 Callcheck→SMS + post-verify PaymentMethodsSheet (не трогать при rollback).
2. UI-EXT — другой агент / другая очередь.

## Next

Ждать закрытия **TASK_89-UI-EXT** → потом `/start` + `/spec` #90 заново.
