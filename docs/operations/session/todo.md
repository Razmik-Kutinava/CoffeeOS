# todo — #86 SBP PWA recovery after bank (EXT)

| Поле | Значение |
|------|----------|
| **ID** | CBR **#86** |
| **Тип** | SBR · EXT CODE:BLACK (recovery после СБП/банка) |
| **Приоритет** | high |
| **Ветка** | `develop` |
| **Канон** | `@spec-build-review` · `@coffeeos-commit-ops` · `@coffeeos-dev-gates` |
| **ТЗ** | [`TASK-86-Восстановление PWA после оплаты СБП-EXT.md`](../milestones/veha_2/requirements/customer_tasks/TASK-86-Восстановление%20PWA%20после%20оплаты%20СБП-EXT.md) |
| **Google** | https://docs.google.com/document/d/1i12UGabEH3UJQrR9y7tQS9ONZMvOxG_ARCg3bKcdDoU/edit?usp=drivesdk |
| **Артефакты** | [`artifacts/sbp_pwa_recovery_after_bank_ext/`](../milestones/veha_2/artifacts/sbp_pwa_recovery_after_bank_ext/) |
| **Статус** | PHASE 0 intake `[x]` · Spec в Google · **ждёт `/spec`** → todo SBR |
| **OUT** | надписи автоплатежа / 11·8 СБП → #79 · SMS-ссылка → каскад (отдельная задача) |

## SBR

- [x] PHASE 0 intake (док + CBR + artifacts)
- [ ] PHASE 1 `/spec` — канон в этом todo (файлы / Не ломать / Проверка / DoD)
- [ ] `/sbr` RED → GREEN → REVIEW (+ device Android/iOS без SKIP)

## Не ломать (черновик до `/spec`)

1. Card/Rebill · webhook Т-Кассы · payment protocol
2. OrderStatusSheet / active orders · CartSheet · guest reconnect
3. COMPONENT_MAP до зелёного Review

## Проверка

После `/spec` — unit/integration/E2E + device Android/iOS (SKIP ≠ PASS).
