# Gates: TASK_100 — точные сообщения при ошибке оплаты и отдельный CTA

Scope: payment error в `PaymentMethodsSheet` классифицируется по Матрице TASK_100 (1051 / 1014 / 119·2200 / карточный fallback / общий fallback) и отдаёт отдельные `message` + `CTA` (тексты через `paymentMethodI18n.js`); HTTP 422 / payment token / repeat-order / SBP / открытие шторки без изменений.

- [x] G1: Матрица + защитные тесты (Gherkin Subtask 1–6, §7 п.1–5)
  CHECK: node --test test/javascript/payment_error_matrix_test.mjs
  EXPECT: # fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=0692447280ad1437226206bed80ad20499db061a13b874c0637feedd8d123237; exit=0; EXPECT=matched; output-sha256=d8c97b1568e40474d9bddbdffc118ae665304ea80f6f2508edf28a60d04d1515; output-bytes=6978; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: статический оракул — 5 сообщений + 3 CTA Матрицы только в `paymentMethodI18n.js`, нет хардкода в `shopPayFsm.js` / `Checkout.svelte` / `PaymentMethodsSheet.svelte`, старый общий текст удалён (§9, DoD 2, 9)
  CHECK: node -e "const fs=require('fs');const r=p=>fs.readFileSync(p,'utf8');const i=r('app/frontend/lib/paymentMethodI18n.js');const others=['app/frontend/lib/shopPayFsm.js','app/frontend/routes/Checkout.svelte','app/frontend/components/PaymentMethodsSheet.svelte'].map(r).join('\n');const T=['Недостаточно средств на карте','Срок действия карты истёк','Слишком много попыток оплаты. Попробуйте позже','Не удалось списать деньги. Обратитесь в банк — этой картой нельзя оплатить заказ.','Не удалось выполнить оплату. Попробуйте ещё раз','Изменить карту','Попробовать позже','Повторить оплату'];const inI=T.every(t=>i.includes(t));const noHard=T.every(t=>!others.includes(t));const oldGone=!others.includes('или карта заблокирована банком');console.log('inI18n='+inI+' noHardcode='+noHard+' oldGone='+oldGone);const ok=inI&&noHard&&oldGone;console.log(ok?'I18N_OK':'I18N_BAD');process.exit(ok?0:1)"
  EXPECT: I18N_OK
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=2b000ddca1011d01447432df3b8e222025a4684e2ae1771dfe14650ddb0a656e; exit=0; EXPECT=matched; output-sha256=c768596191af5a6c3c3d70786e340457ea4fe1c86d93846f8fc81a5aa30d5a96; output-bytes=49; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: регрессия JS зоны — payment error / repeat invalid token / inline pay / widget pay FSM / i18n промо
  CHECK: node --test test/javascript/payment_error_user_messages_test.mjs test/javascript/repeat_invalid_token_payment_test.mjs test/javascript/widget_repeat_pay_flow_patch1_test.mjs test/javascript/shop_inline_pay_button_fsm_test.mjs test/javascript/open_repeat_payment_sheet_test.mjs test/javascript/shop_widget_pay_fsm_test.mjs test/javascript/payment_method_promo_11rub_i18n_test.mjs test/javascript/shop_sbp_autopay_checkout_ui_test.mjs
  EXPECT: # fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=6d421bced9754e333e6e3dd63c49d9df2de6e8efe9d1a1a8018efecc8eaac6af; exit=0; EXPECT=matched; output-sha256=bd6438da8e981fafd30c35349fa4ff4ef3cfc0fe3aa8b34c1930cd587531c707; output-bytes=20629; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: регрессия Rails — source-тесты FSM/шторки + backend ErrorCode (HTTP-контракт не меняется)
  CHECK: ruby bin/rails test test/integration/shop/shop_pay_fsm_3ds_test.rb test/integration/shop/inline_pay_button_patch1_test.rb test/services/shop/tbank_payment_error_test.rb test/integration/shop/api/payment_status_error_code_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=4a4939f4376b59f23df96b3bf2e560a1fcdb72c4a496ab76179ecddf33d7dab3; exit=0; EXPECT=matched; output-sha256=71e55658c64d397f77e4b98274d648ad0d6fcd74817d50560c66d89e8b400e11; output-bytes=1625; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: сборка фронта
  CHECK: npm run vite:build
  EXPECT: built in
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=f7e7622df49ec841733ad3773c617530864e0ea56f57087c6b0303b7181c2140; exit=0; EXPECT=matched; output-sha256=b5bd68c89fe87a5f4837ef9132e14a44e9ea6bd088c62ed67c3367c7fde8769f; output-bytes=16597; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: классификация остальных `error_code` из `CLIENT_ERROR_CODES` (1005, 1013, 1041, 1053, 1054, 1057, 1061, 1062, 1078) — каждый: «карточная» / «общая» / `[ОТКРЫТЫЙ ВОПРОС]` с источником (код / backend message / доки Т-Банка); 0 открытых вопросов = готово к Build (§10)
  EVIDENCE: manual 2026-10-05 — todo.md § «Классификация error_code»: все 9 → карточный fallback (1005/1041/1054/1057/1062 — комментарии `shopWidgetPayFsm.js`; 1013/1053/1061/1078 — `INVALID_REBILL_CODES` + решение владельца) · 3DS abort → общий · NET/BANK без изменений · `[ОТКРЫТЫЙ ВОПРОС]` = 0

- [ ] G7: hot-path Fly MCP Point A — checkout / `PaymentMethodsSheet` без 5xx, бандл с новыми текстами
  EVIDENCE: pending — после deploy по апруву; tenant `2fdee1ac-4674-41ee-b89e-87b45643f789`

<!--
CoffeeOS TASK_100 unlazy (2026-10-05, ledger до /spec):
- Baseline: G3 68/68 pass (7 файлов). G1 — файла нет (создаётся на RED). G2 — I18N_BAD ожидаемо (старый текст в shopPayFsm.js).
- Факт кода: shopPayFsm.js CLIENT_ERROR_CODES = 12 кодов (вкл. 1051/1014/119/2200) → один PAY_FSM.CLIENT_ERROR + длинный текст; regex по message тоже → CLIENT_ERROR; дефолт → BANK_ERROR («Сбой банка: позже»). resolvePayFsmCtaAction(CLIENT_ERROR) = open_new_card; auto-open = false (§7 п.5 уже соблюдён).
- payment_error_user_messages_test.mjs и shop_pay_fsm_3ds_test.rb фиксируют старый длинный текст → обновляются на RED (ТЗ §4 п.6 разрешает).
- Backend Shop::TbankPaymentError::FRIENDLY_MESSAGES: «Карта просрочена» / «…Выберите другую карту или подождите» — ≠ Матрице; ТЗ запрещает менять HTTP-контракт → frontend маппит по error_code, backend message не трогаем (уточнить на /spec).
- Вопросы на /spec: CTA «Попробовать позже» — какое действие (закрыть / ничего)? NET_ERROR («Нет связи») и BANK_ERROR (5xx) — вне Матрицы, оставить как есть? Regex-классификация по message = «подтверждённая карточная семантика»?
- inline pay (shopInlinePayFsm.js, «Недостаточно средств») — другой поток, вне scope §2.
- package.json: нет lint/typecheck/test скриптов → канон node --test + vite:build; tsc не применим.
- G6/G7 manual; deploy — только апрув.
-->
