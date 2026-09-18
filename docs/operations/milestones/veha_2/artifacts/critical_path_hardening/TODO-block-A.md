# todo — #93 TASK_93-A: Деньги ↔ заказ (склад + webhook)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#93** · **TASK_93-A** |
| **Тип** | SBR · hot-path оплата / склад |
| **Статус** | **REGRESS PASS** · Next: `/review` |
| **RED** | `fc97a432` |
| **GREEN** | `bba068f9` |
| **Entire** | `01M2SSQXT1V67AK260SH1P9RAX` |
| **Ветка** | `develop` |
| **ТЗ** | [`TASK-93-Critical-path-hardening.md`](../../requirements/customer_tasks/TASK-93-Critical-path-hardening.md) § Блок A |
| **GATES** | [`GATES-block-A.md`](GATES-block-A.md) |

## SBR

- [x] PHASE 0–2 · RED `fc97a432` · GREEN `bba068f9`
- [x] `/regress` — G1 **40/0** · G2 **139/0** PASS
- [ ] PHASE 3 `/review` — таблица A1–A6 · push · **без deploy**

## Проверка (результат)

| Команда | Результат |
|---------|-----------|
| G1 matrix (updater/deduction/callback job/tbank ctrl/block_f) | **40 runs, 0 fail** |
| G2 `test/services/payments/` + `callbacks/` + `jobs/payments/` | **139 runs, 0 fail** |

## Next

`/review` — Fly MCP Point A только в блоке L (не DoD A)
