# /review — PHASE 3 REVIEW

**Канон (не дублировать):** [`spec-build-review.mdc`](../rules/workflow/spec-build-review.mdc) § PHASE 3.

Порядок: local → `bugbot`+`security-review` → Entire → push/CI (логи, чин, снова push) → **CI green → стоп**. Deploy — апрув владельца.

## Обязательно в конце (копипаст)

`Next: deploy — только по апруву владельца`

Дыры до push: `Next: /sbr`
