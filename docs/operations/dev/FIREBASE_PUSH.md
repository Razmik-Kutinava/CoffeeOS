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
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Service accounts → Generate new private key → файл `config/secrets/firebase-service-account.json` (не в git) |

**Не коммитить** JSON и ключи в git. См. `config/secrets/README.md`.

## Локально

```bash
# JSON в .env одной строкой
ruby bin/fly-tools/minify_firebase_env.rb
```

## Fly

```bash
# из корня репо (WSL, fly в PATH)
bash bin/fly-tools/fly_firebase_secrets.sh
fly deploy -a coffeeos
```

Скрипт читает `config/secrets/firebase-service-account.json` и выставляет все 8 `FIREBASE_*` secrets.

## Проверка

1. Витрина → заказ → **«Разрешить уведомления»**
2. Бариста меняет статус → push в шторке
3. `ruby bin/acceptance/b11_order_status_fly_smoke.rb` — чек `push_register`
4. SQL: `SELECT status, title FROM push_notifications ORDER BY created_at DESC LIMIT 5;`
