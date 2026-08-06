# Certificates for T-Bank API (НУЦ Минцифры / Russian Trusted CA)

Т-Банк перевёл `securepay.tinkoff.ru` на цепочку Russian Trusted Root/Sub CA.
Без них Ruby `Net::HTTP` на Fly даёт:

`SSL_connect ... certificate verify failed (self-signed certificate in certificate chain)`

Файлы (PEM):

- `russian_trusted_root_ca.crt`
- `russian_trusted_sub_ca.crt`

Источник: портал Госуслуг / gu-st.ru (инструкция банка: http://status.tbank.ru/api-setup/).

В образ ставятся через `Dockerfile` → `update-ca-certificates` + `SSL_CERT_FILE`.
