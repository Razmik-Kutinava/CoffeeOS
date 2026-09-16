# todo — #91 TASK_89-UI-EXT phone input UI/UX

| Поле | Значение |
|------|----------|
| **ID** | CBR **#91** (Google: TASK_89-UI-EXT) |
| **Статус** | **intake + unlazy** 2026-09-16 · G1–G4 baseline PASS · ждёт `/spec` |
| **GATES** | [`session/GATES.md`](GATES.md) · G5 Fly MCP после REVIEW/deploy |
| **ТЗ** | [`TASK-89-UI-EXT-…md`](../milestones/veha_2/requirements/customer_tasks/TASK-89-UI-EXT-UI-UX-авторизации-PWA-экран-ввода-телефона.md) |
| **Google** | https://docs.google.com/document/d/1PTP5LIVgnj2QNpOMi4Md4Lb8Y8imvL3MQnsHhVNDQoc/edit?usp=drivesdk |
| **Артефакты** | `artifacts/pwa_auth_phone_input_ui_ux/` |

## SBR

- [x] PHASE 0 intake
- [ ] PHASE 1 `/spec`
- [ ] PHASE 2 RED/GREEN
- [ ] PHASE 3 `/review`

## Scope (из Google Doc)

1. Phone-auth: скрыть CTA с суммой заказа.
2. Phone-auth: скрыть preview/состав корзины.
3. Уменьшить толщину checkout-sheet (UX Guide).
4. Клавиатура: поле телефона доступно; скрытые элементы не занимают место.
5. После auth — обычный checkout UI.

## Не ломать

1. #89 Callcheck→SMS / linker / session / post-verify PaymentMethodsSheet.
2. #90 POSTCALL — не трогать (parked; после #91).
3. CartSheet thresholds вне phone-auth.
4. FlashCall / SMS cascade backend.

## Next

`/spec` → файлы Checkout / CartSheet / PhoneAuth* · тесты UI phone-auth.
