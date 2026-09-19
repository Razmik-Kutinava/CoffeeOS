# todo — Патч 2: ЛК · «Tg» → «Telegram» (Subtask 21)

| Поле | Значение |
|------|----------|
| **ID** | **#69** · **Патч 2** · 2026-09-17 · patch v1 |
| **Тип** | SBR · патч · ЛК bottom sheet «Написать нам» |
| **Статус** | **REVIEW · CI green** · deploy апрув |
| **Ветка** | `develop` |
| **ТЗ** | [`Доработка личного кабинета (ЛК) в PWA.md`](../milestones/veha_2/requirements/customer_tasks/Доработка%20личного%20кабинета%20(ЛК)%20в%20PWA.md) · секция **Патч 2: 2026-09-17** → **Исправленный сценарий** |
| **Артефакт** | [`screenshots/patch2_2026-09-17_fig2_telegram_label.png`](../milestones/veha_2/artifacts/pwa_personal_account_lk/screenshots/patch2_2026-09-17_fig2_telegram_label.png) · рис.2 |
| **Google Doc** | https://docs.google.com/document/d/1yH1DzM48Bcg43X9lT_37WVICKUkmFLGETduYX3eOpzo/edit |
| **Entire** | `01M2WSS8C919PDRPZJ8ECAH6WP` на `3bae4b26` |

## SBR

- [x] PHASE 0 /start — Google Doc · customer_tasks · рис.2 в artifacts
- [x] PHASE 1 SPEC — только Исправленный сценарий (Subtask 21 patch v1)
- [x] PHASE 2 RED — тест подписи Telegram [TDD] · `098b4c24`
- [x] PHASE 2 GREEN — `ContactSupportSheet`: «Tg» → «Telegram» · `4f8ee541`
- [x] `/regress` (Проверка) · `node --test test/javascript/telegram_support_test.mjs` · 14/14
- [x] PHASE 3 `/review` — Local PASS · bugbot no bugs · security no med+ · Entire attach · CI green `35442696778`

## Файлы (ожидаемо)

1. `app/frontend/components/ContactSupportSheet.svelte` — подпись кнопки `contact-support-telegram`: «Tg» → «Telegram»
2. `test/javascript/telegram_support_test.mjs` — контракт Патч 2 (Subtask 21)
3. `docs/operations/milestones/veha_2/requirements/customer_tasks/Доработка личного кабинета (ЛК) в PWA.md` — секции Патч 1/2 (синхрон с Google Doc)
4. `docs/operations/milestones/veha_2/artifacts/pwa_personal_account_lk/screenshots/patch2_2026-09-17_fig2_telegram_label.png` — рис.2

### Blast-radius (соседи, не менять)

- `SupportContactSheet.svelte` / `supportConfig.js` — гл. экран (уже «Telegram»; референс)
- `Profile.svelte` / `AccountSettings.svelte` — только хосты sheet; не трогать (TASK_94 / ЛК)
- Telegram URL / `openDeepLink` / email-кнопка / структура bottom sheet

## Не ломать

1. Механику «Написать нам» / deep link / URL бота (`shopSupportTelegramUrl` / `SUPPORT_TELEGRAM_URL`)
2. Email-сценарий и подпись «e mail» / email (без редизайна sheet)
3. `Profile.svelte` history repeat / TASK_94 (COMPONENT_MAP · Profile → ContactSupportSheet)
4. Header / Патч 1 (иконка «обратная связь») — вне scope этой итерации

## Проверка

```bash
node --test test/javascript/telegram_support_test.mjs
```

## DoD

- [x] Subtask 21 (patch v1): в bottom sheet ЛК варианты «email» и **«Telegram»** (не «Tg»)
- [x] URL / обработчик / email / структура sheet без изменений
- [x] Local PASS · затем `/review` при намерении
