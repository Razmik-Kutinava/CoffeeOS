# bin/acceptance — приёмка на Fly

Скрипты проверки фич заказчика на стенде (браузер MCP, смоук, скрины).

Префиксы в именах = номер задачи (B1.1, B1.4, B1.7, B1.9, B1.13, B2.1…).

## Как пользоваться

Обычно: сначала prep на Fly (`.rb`), потом MCP (`.mjs`).

```bash
ruby bin/acceptance/b21_acceptance_prep.rb
node bin/acceptance/b21_acceptance_fly.mjs
```

## Зачем отдельно

Чтобы корень `bin/` не был помойкой из сотен одноразовых прогонов.
