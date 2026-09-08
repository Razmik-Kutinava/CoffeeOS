# todo — #80 Callcheck → leave wizard (verify-first)

| Поле | Значение |
|------|----------|
| **CBR** | #80 Callcheck leave wizard |
| **Fly** | v492 · `SHOP_OTP_LOG_FALLBACK=false` |
| **Артефакт** | `…/mcp/fly_v492_2026-09-08/` |
| **Режим** | verify-first · код только при FAIL leave-wizard |

## Slices

| Slice | Статус |
|-------|--------|
| **V** | [ ] V0–V1 **PASS** · V2 **NOT CONFIRMED** (sync «звоню» → 200 confirmed:false → SMS 204) · V3 n/a |
| **F** | [ ] n/a — нет FAIL `confirmed→leave` |
| **R** | [ ] |

## SBR

- [x] SPEC
- [ ] Slice V live PASS (нужен звонок в окне ~40с)
- [ ] RED / GREEN — только после FAIL leave-wizard
- [ ] REVIEW

## Файлы (ожидаемо) — только при FAIL

- `app/frontend/lib/phoneAuthCascade.js`
- `app/frontend/components/PhoneAuthCodeStep.svelte`
- `app/frontend/components/PhoneAuthWizard.svelte`
- `app/controllers/shop/api/phone_otp_controller.rb`
- `app/services/shop/phone_otp.rb`
- `app/services/shop/phone_verified_customer_linker.rb`

## Не ломать

- SMS fallback · rate limits · session/RLS · Callcheck≠FlashCall · guest checkout

## Проверка

```bash
node --test test/javascript/phone_auth*.mjs test/javascript/*callcheck*.mjs
ruby bin/rails test test/services/shop/phone_otp* test/integration/shop/api/*phone_otp*
# + live V
```

## Note

SMS.ru **204** на fallback — ops кабинет «Отправители», не Slice F leave-wizard.
