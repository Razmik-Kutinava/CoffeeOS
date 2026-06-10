# Firebase Push (B1.1) — настройка

## Переменные `.env` / Fly secrets

| Переменная | Откуда |
|------------|--------|
| `FIREBASE_API_KEY` | Firebase → Project settings → Web app → firebaseConfig |
| `FIREBASE_AUTH_DOMAIN` | то же |
| `FIREBASE_PROJECT_ID` | `coffeeos-fa701` |
| `FIREBASE_STORAGE_BUCKET` | то же |
| `FIREBASE_MESSAGING_SENDER_ID` | то же (`486831309396`) |
| `FIREBASE_APP_ID` | то же |
| `FIREBASE_VAPID_KEY` | Cloud Messaging → Web Push certificates → Key pair |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Service accounts → Generate new private key (весь JSON одной строкой) |

**Не коммитить** JSON и ключи в git.

## Fly

```bash
fly secrets set \
  FIREBASE_API_KEY=... \
  FIREBASE_AUTH_DOMAIN=coffeeos-fa701.firebaseapp.com \
  FIREBASE_PROJECT_ID=coffeeos-fa701 \
  FIREBASE_STORAGE_BUCKET=coffeeos-fa701.firebasestorage.app \
  FIREBASE_MESSAGING_SENDER_ID=486831309396 \
  FIREBASE_APP_ID=1:486831309396:web:... \
  FIREBASE_VAPID_KEY=... \
  -a coffeeos
```

`FIREBASE_SERVICE_ACCOUNT_JSON` — длинная строка; удобнее положить в `.env` локально и на Fly через `fly secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'`.

## Проверка

1. Витрина → заказ → **«Разрешить уведомления»**
2. Бариста меняет статус → push в шторке
3. `ruby bin/b11_order_status_fly_smoke.rb` — чек `push_register`
4. SQL: `SELECT status, title FROM push_notifications ORDER BY created_at DESC LIMIT 5;`
