# bin/fly-tools — инструменты Fly / оплаты

Диагностика прода/стенда и вспомогательные утилиты:

- `usercards_*` — разбор сохранения карт / оплаты
- `fetch_fly_otp.rb` — достать OTP с Fly
- `fly_firebase_secrets.sh` / `minify_firebase_env.rb` — секреты Firebase push
- `generate_*` — иконки PWA / звук бариста
- `shop_checkout_otp_fly_multitenant.rb` — OTP чекаута на нескольких точках

```bash
ruby bin/fly-tools/fetch_fly_otp.rb email@example.com
bash bin/fly-tools/fly_firebase_secrets.sh
```
