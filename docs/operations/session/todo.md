# todo — #71 Slice A · CRM sync после оплаты

| Поле | Значение |
|------|----------|
| **CBR** | #71 Email-сбор · ST-9 |
| **CRM provider** | **Brevo Contacts** (`BREVO_API_KEY`) |
| **Point A** | `2fdee1ac-4674-41ee-b89e-87b45643f789` |
| **OUT** | UI email · Slice B bounce opt-out · payments |

## SBR

- [x] **SPEC**
- [x] **RED** (`6b3d714b`)
- [x] **GREEN** (`cb1e336d` · Entire `01M1ZZXV23N5BFK4SGDQV0H4KG`)
- [x] **regress** PASS (20/0)
- [x] **REVIEW** — bugbot `retry_on` · security OK · CI [34207477722](https://github.com/Razmik-Kutinava/CoffeeOS/actions/runs/34207477722) green
- [ ] **deploy** — только апрув владельца

## Bugbot / CI tip

- `retry_on` — `fecee7e3`
- rubocop `[ list_id.to_i ]` + B2.2 menu `@categories` grouping — `e247f9b1`
