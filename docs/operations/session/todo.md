# todo — #80 Registration UI/UX + Callcheck cascade

| Поле | Значение |
|------|----------|
| **CBR** | #80 · [ТЗ](../milestones/veha_2/requirements/customer_tasks/Регистрация%20PWA%20UI%20UX%20и%20каскад%20Callcheck%20x2%20SMS.md) |
| **Тип** | Fix / hot-path витрина · phone auth + CartSheet |
| **Цель** | P0: скрыть сумму при клавиатуре; копирайт Callcheck; переход после confirmed |
| **Point A** | `tenant_id` = `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **Ветка** | `develop` |
| **Артефакты** | [`…/registration_callcheck_cascade_ui_ux/`](../milestones/veha_2/artifacts/registration_callcheck_cascade_ui_ux/) |

## SBR

- [x] **SPEC** (`9c28d388`)
- [x] **RED** (`cbd1d8a4`)
- [x] **GREEN** (`61593bb2`)
- [x] **/regress** — JS 33/0 · rails 23/0
- [x] **REVIEW** — bugbot fix · security OK · push `8e0138c6` · CI `34099718956`

## Local + REVIEW

- bugbot: clear poll error after success
- security: no medium+
- Entire: `01M1XDGFW23WY77ZRW73D5KGT4`
