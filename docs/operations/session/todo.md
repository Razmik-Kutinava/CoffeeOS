# todo — Group 4: уведомления (2026-08-10)

**Намерение:** ебашь Группа 4 — OS-detect · Wallet/WebPush · FCM · каскад ready→SMS

| last_done | current_state | next_step |
|-----------|---------------|-----------|
| Group 4: SMS idempotency · grace 15s · push LS · CTA #37 labels | Local PASS | **deploy под апрув** · backlog хвосты |

## Файлы
- `order_ready_paid_notifier.rb` ✅ skip if sms already sent
- `order_ready_cascade_job.rb` ✅ `SMS_GRACE = 15s`
- `guest_order_broadcaster.rb` ✅ `set(wait: SMS_GRACE)`
- `orderStatusNotifyActions.js` ✅ pushRegisteredStorageKey
- `firebasePush.js` ✅ LS on register
- `orderStatusCtaMachine.js` ✅ лейблы #37

## Не ломать — ок
- SMS только если WS offline (presence)
- Telegram не возвращали
- ReadyPushClaim для FCM

## Проверка
```bash
# Rails notify 39/0 · JS 42/0
```

## Чеклист
- [x] SMS идемпотентен
- [x] hasPushSubscription = permission + FCM LS
- [x] cascade grace 15s + re-check presence
- [x] Local PASS
- [ ] deploy — только под апрув
- [ ] MCP live push/SMS на Fly — после deploy + SMS_RU
