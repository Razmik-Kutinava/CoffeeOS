# Fly #38 — release BLOCKED billing (WSL `bin/fly_deploy.sh`)

**Дата:** 2026-08-03  
**Причина:** не код CoffeeOS. Build + push image **OK**; `create release` → **403 billing**.

## Что уже готово

| Шаг | Статус |
|-----|--------|
| `git push` develop | OK (`5786f901` / tip #38) |
| Docker build (WSL `bin/fly_deploy.sh`) | OK |
| Push image | OK → `registry.fly.io/coffeeos:deployment-01KZ3S4V3XCEY7W87WBP76XC7C` |
| Create release / machines | **FAIL 403** |
| Live | всё ещё **v419** |

Ошибка:
```text
failed to create release (status 403): We need your payment information to continue!
https://fly.io/dashboard/razmik-kutinava/billing
```

Ранее (Windows): `deployment-01KZ3QRBRX8E2VES9XFJSBGDJ4` — тот же billing gate.

## Что сделать тебе (1–2 мин)

1. Открыть https://fly.io/dashboard/razmik-kutinava/billing  
2. Добавить карту **или** купить credit (org `razmik-kutinava`)  
3. Снова релиз **без пересборки** (image уже в registry):

```bash
# из WSL, в репо:
fly deploy -a coffeeos --image registry.fly.io/coffeeos:deployment-01KZ3S4V3XCEY7W87WBP76XC7C
```

или полный скрипт снова:
```bash
bin/fly_deploy.sh
```

4. Проверка: `curl -s -o /dev/null -w "%{http_code}\n" https://coffeeos.fly.dev/up` → `200`  
5. Написать агенту «деплой ок» → MCP #38.

## Не чинить в коде

- Dockerfile / assets / unused CSS `.cancel-btn` — **не** причина 403  
- Depot vs `--depot=false` — у тебя build уже прошёл  
- Пока billing не ок, любой `fly deploy` / `machine update` будет 403
