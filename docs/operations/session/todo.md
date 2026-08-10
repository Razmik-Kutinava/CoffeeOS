# todo — Group 3: шторка / статусы / повторы (2026-08-10)

**Намерение:** ебашь Группа 3 — compact/multi status · Cable · Quick Repeat · нет слоя поверх слоя

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Group 3 code: ready in sheet · Cable dedupe · hide status on pay-stack | Local PASS · MCP surface (Fly = old FE) | **deploy под апрув** · Group 4 notify · хвосты backlog |

## Файлы
- `orderStatusSheet.js` ✅ ready ≠ terminal; `activeOrderIdsKey`
- `OrderStatusSheet.svelte` ✅ resubscribe dedupe
- `orders_controller#active` ✅ accepted|preparing|ready
- `CartSheet.svelte` ✅ `{#if !payStackActive}` status

## Не ломать — ок
- hide «повторить» при live accepted|preparing|ready
- peek/expanded/hidden thresholds
- Cable fast-path + poll 8s

## Проверка
```bash
# Rails 45/0 · JS 42/0 (status/sheet/cta/frequent)
```

## Чеклист
- [x] ready остаётся в шторке (контракт API+FE)
- [x] Cable: poll не tear-down при том же id-наборе
- [x] pay-stack: статус не в 15vh peek
- [x] Local PASS
- [~] MCP Point A: «повторить» на каталоге PASS; pay-stack/ready — **после deploy**
- [ ] deploy — ждать апрув владельца
