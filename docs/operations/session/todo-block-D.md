# todo — #93 TASK_93-D: История заказов / ЛК список (per_page)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-D** |
| **Тип** | SBR · shop API history / ЛК |
| **Статус** | **REVIEW** · push `13d18fbf` · CI watch · Entire `01M2STB3BHJ65BAYQM492QTT7P` |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | бриф чата TASK_93-D · зонтик [`TASK-93-Critical-path-hardening.md`](../milestones/veha_2/requirements/customer_tasks/TASK-93-Critical-path-hardening.md) карта D |
| **GATES** | [`GATES-block-D.md`](../milestones/veha_2/artifacts/critical_path_hardening/GATES-block-D.md) |
| **Цель** | Default `per_page=20` (не 1); max 50; ЛК / «сегодня» показывают пачку |
| **OUT** | active sheet · Quick Repeat · load-more · A–C/E/F · deploy (L) |

## SBR

- [x] PHASE 0 `/start`
- [x] `/unlazy` — GATES D
- [x] PHASE 1 `/spec`
- [x] PHASE 2 RED — `faca7e3c`
- [x] PHASE 2 GREEN — `9d2b98a8`
- [x] `/regress` — 20/0
- [x] PHASE 3 `/review` — D1–D3 PASS · push · **без deploy**

## REVIEW-таблица

```
D1 T-D1a T-D1b T-D1c T-D1d   PASS
D2 клиент / grep             PASS
D3 T-D3a T-D3b               PASS
```

## DoD

- [x] Default 20 · T-D* PASS · D2 · max 50 · REVIEW-таблица
- [ ] Deploy = TASK_93-L
