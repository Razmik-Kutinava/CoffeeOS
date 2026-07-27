# todo — Связка профилей Email ↔ Phone + управление данными в PWA

> **ТЗ:** [`customer_tasks/Связка профилей Email Phone и управление данными пользователя в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Связка%20профилей%20Email%20Phone%20и%20управление%20данными%20пользователя%20в%20PWA.md)  
> **Артефакты:** [`artifacts/profile_email_phone_merge/`](../milestones/veha_2/artifacts/profile_email_phone_merge/)

## Текущая фаза

**PHASE 3: REVIEW** — GREEN done · ждём push/MCP по апруву

- [x] PHASE 0: Intake
- [x] PHASE 1: SPEC
- [x] PHASE 2: RED/GREEN (реализация в одном проходе по «ебашь»)
- [x] Регрессия зоны shop/order + phone/email OTP
- [ ] Push / Fly deploy / MCP — только по явному апруву
- [ ] Апрув заказчика

## Чек-лист

### Бэкенд
- [x] Шаг 0: DDL `email_verified` / `phone_verified`
- [x] Шаг 1: GET `/shop/api/profile` + 401
- [x] Шаг 2: PATCH `/shop/api/profile`
- [x] Шаг 3–4: POST `link_email` (clean + merge)
- [x] Шаг 5: POST `link_phone` + soft-merge в linkers
- [x] Шаг 6: `Shop::OrderCreator` autofill из профиля

### Фронтенд
- [x] Шаг 7: Экран профиля (контакты + verified + имена + toast)
- [x] Шаг 8: OTP-допривязка без reload
- [x] Шаг 9: Autofill checkout + «Сохранить в профиль»
