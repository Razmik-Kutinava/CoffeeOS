# Локальные секреты (не в git)

| Файл | Назначение |
|------|------------|
| `firebase-service-account.json` | Firebase Admin SDK для FCM HTTP v1 |

Скачать: Firebase Console → Project settings → Service accounts → Generate new private key.

В `.env`: `ruby bin/minify_firebase_env.rb` (JSON одной строкой).

На Fly: `bash bin/fly_firebase_secrets.sh` — см. `docs/operations/dev/FIREBASE_PUSH.md`.
