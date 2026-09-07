# todo — #82 Cascade SMS ready + status sheet stuck

| Поле | Значение |
|------|----------|
| **CBR** | #82 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Каскад%20SMS%20после%20Заказ%20готов%20и%20шторка%20статуса%20на%20главном.md) |
| **Тип** | Fix / hot-path витрина · статусы + уведомления |
| **Цель** | hide-on-ready + SMS cascade presence; repeats после ready |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/order_ready_cascade_sms_status_sheet_fix/`](../milestones/veha_2/artifacts/order_ready_cascade_sms_status_sheet_fix/) |

## SBR

- [x] **SPEC** · **RED** · **GREEN** (`8cae376d`) · **/regress**
- [x] **REVIEW** — bugbot HIDE_REPEAT · security OK · CI [34101618655](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34101618655) green
- Entire: `01M1XDGFW23WY77ZRW73D5KGT4` на `959f2fa0`
- Next: deploy апрув · Fly MCP Point A

## Local /regress + REVIEW fix

- JS sheet+poll+frequent terminal: **33/0**
- rails frequent+cascade+active: **44/0**
- bugbot: HIDE_REPEAT без ready · medium presence mitigated by unsubscribe on hide
- security: no medium+
