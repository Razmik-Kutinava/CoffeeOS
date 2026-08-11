# SMS.ru — секреты ENV (HTTP-шлюз)

Канон отправки в CoffeeOS: **HTTP** `Shop::SmsRuClient` → `sms/send` + flash_call.  
**Не** используем email2sms (`…@sms.ru`) и SMTP.

`.env*` в gitignore — этот runbook = committed шаблон. Локально правь **`.env`**, на Fly — **secrets**.

## Обязательные переменные

```env
# UUID api_id из ЛК SMS.ru (только ключ, без +телефонов и без @sms.ru)
SMS_RU_API_ID=00000000-0000-0000-0000-000000000000

# Буквенный отправитель, согласованный в ЛК «Отправители»
SMS_RU_FROM=CoffeeOS
```

Алиас (то же, что FROM): `SMS_RU_SENDER` — клиент читает, если `SMS_RU_FROM` пуст.

## Dev-only

```env
# true = не бить SMS.ru, код/текст в Rails.logger (для local без ключа)
# Для боевой отправки локально — не задавать или false
SHOP_OTP_LOG_FALLBACK=false
```

## Не класть в ENV

| Неправильно | Почему |
|-------------|--------|
| `api_id+7963…@sms.ru` | это адрес email2sms, не HTTP ключ |
| логин/пароль SMTP | не используем |
| номера получателей | приходят из OTP/профиля в рантайме |

## Webhook (#61)

В ЛК SMS.ru → оповещения / обработчик:

```
https://coffeeos.fly.dev/callbacks/sms_ru
```

Метод: **POST**. Ответ обработчика: тело **`100`**.  
Подпись: `SHA256(SMS_RU_API_ID + склейка data[…])` — ключ уже в Fly secrets.

## Fly

```bash
fly secrets set SMS_RU_API_ID="ВАШ_UUID" SMS_RU_FROM="ВАШ_ОТПРАВИТЕЛЬ" -a coffeeos
```

(только с явным апрувом владельца на secrets/prod)

## Проверка локально

1. В `.env` заданы `SMS_RU_API_ID` + `SMS_RU_FROM`, `SHOP_OTP_LOG_FALLBACK` не `true`
2. Перезапуск Rails / `bin/dev`
3. OTP flash_call или cascade «заказ готов» → в логах SMS.ru не `(fallback)`, либо в кабинете SMS.ru видно сообщение

Bridge: [`docs/integrations/sms-auth.md`](../../integrations/sms-auth.md)
