# Gates: TASK_101 — сумма заказа в блоке способов оплаты

Scope: в `PaymentMethodsSheet` над первой сохранённой картой / первым способом оплаты — строка «Итого 3 245 ₽» справа из серверного `total` (`/shop/api/cart` → `cartTotal`), обновляется при +/−/удалении, видна в error state, скрыта при пустом/незагруженном total; оплата / `TbankAdapter` / цены / карты / СБП / кнопка / тексты ошибок не меняются.

- [x] G1: JS-тест строки «Итого» (Subtask 4–8, 10: над картами и без карт, формат `3 245 ₽`, обновление, error state, нет `0 ₽`)
  CHECK: node --test test/javascript/payment_methods_order_total_test.mjs
  EXPECT: # fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=8e9602a1c9374cd4848358309de7e85f6a1c7c947f2459c24d068c49a22bcb0b; exit=0; EXPECT=matched; output-sha256=08ef2f168c23fca3c8be625160937b1db48e41244c50c32815b290fd754b30f3; output-bytes=2928; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G2: Rails — контракт `total` в `/shop/api/cart` (модификаторы, количества) + `total` ↔ `Amount` в копейках (Subtask 1–3, 9)
  CHECK: ruby bin/rails test test/integration/shop/api/cart_total_amount_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=9a81f910e23ba3525fe576d4805afc89102cd2e74451c0b5a886186618c87803; exit=0; EXPECT=matched; output-sha256=8889f05a67f5c2c19aafdb1d9fba0c190c38880da355ad8a6cd10c2d6e3e88ed; output-bytes=1609; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G3: запрещённый backend-scope не тронут — оплата / TbankAdapter / расчёт корзины и заказа (относительно intake `a8992dc9`; фронт FSM/кнопка — территория TASK_100, проверка на REVIEW по диффу TASK_101)
  CHECK: git diff --quiet a8992dc9 -- app/services/payments app/services/shop/cart_service.rb app/services/shop/order_creator.rb app/controllers/shop/api/payments_controller.rb && echo SCOPE_OK
  EXPECT: SCOPE_OK
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=3f4faf653adad97a91a6e7947eae7fc9567b43a68af67430194ff57c80faabc2; exit=0; EXPECT=matched; output-sha256=40a4106b2e3dbb15f63084e736486692c3250c2fe55c5bd05c50ca1c64b6d03e; output-bytes=10; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G4: регрессия JS зоны — шторка способов оплаты / СБП / fallback / матрица ошибок TASK_100 / промо
  CHECK: node --test test/javascript/shop_sbp_autopay_checkout_ui_test.mjs test/javascript/widget_repeat_pay_flow_fallback_ui_test.mjs test/javascript/payment_error_matrix_test.mjs test/javascript/payment_method_promo_11rub_i18n_test.mjs
  EXPECT: # fail 0
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=9a0bd4a69b92fbc0c97af2e3e5a0343d483c5c25e6fb6f361cc527338abf03c3; exit=0; EXPECT=matched; output-sha256=a07021cb6dbe1cc69b84e9b0750544eddd41a8c4370a53ab14231e0eba8e3661; output-bytes=12582; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G5: регрессия Rails — сохранённые карты / СБП UI / checkout UI / корзина (модификаторы, persistence)
  CHECK: ruby bin/rails test test/integration/shop/shop_saved_cards_step3_test.rb test/integration/shop/sbp_payment_ui_test.rb test/integration/shop/checkout_ui_cleanup_test.rb test/integration/shop/shop_checkout_cart_sheet_ux_test.rb test/integration/shop/api/cart_persistence_test.rb test/integration/shop/b113_s4_cart_modifiers_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=7e4a821736674b49713217233a9f6e804183a82b37b6b72f592c5ed3fd97223f; exit=0; EXPECT=matched; output-sha256=f57e783b284539f4c46b1c4c2e9e01d68c0735b933f31ceb013cfc7e07abe862; output-bytes=1659; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G6: сборка фронта (замена typecheck/lint из §5 — в `package.json` их нет)
  CHECK: npm run vite:build
  EXPECT: built in
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=f7e7622df49ec841733ad3773c617530864e0ea56f57087c6b0303b7181c2140; exit=0; EXPECT=matched; output-sha256=fbcd5671060bcc46b630fbd2c7a91a2c4d7b23079d4a2b902a9a0160b74e1761; output-bytes=16597; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries

- [x] G7: решение по промо-скидке — `cart.total` (без промо) vs `Amount` = `order.final_amount` (subtotal − `promo_discount`): что показывать в «Итого» при промо; 0 `[ОТКРЫТЫЙ ВОПРОС]` = готово к Build (Subtask 3, 9, DoD 4)
  EVIDENCE: manual 2026-10-05 — /spec: `promo_discount` всегда 0 (BUG-004); реальное расхождение только `GrowthPromo` (акция привязки + галочка → `final_amount` = 11 ₽). Решение владельца: «Итого» = всегда серверный `total` корзины; `total` = `Amount/100` проверяется без акции (G2). `[ОТКРЫТЫЙ ВОПРОС]` = 0 · todo.md § «Решение владельца»

- [ ] G8: manual — viewport ~360 px без overflow, Telegram/Instagram In-App Browser, Fly MCP Point A checkout без 5xx (Subtask 11–12)
  EVIDENCE: pending — 360 px локально на GREEN; In-App + Fly после deploy по апруву; tenant `2fdee1ac-4674-41ee-b89e-87b45643f789`

<!--
CoffeeOS TASK_101 unlazy (2026-10-05, ledger до /spec):
- Факт: `/shop/api/cart` уже отдаёт `total` (cart_controller show/add/update/destroy; CartService `total = Σ line_total`, unit_price с модификаторами) → backend-контракт, скорее всего, не меняем; shop-api.md не трогаем.
- Фронт: `cartSheetStore.cartTotal` ← `data.total` (applyCartData); optimisticBump/Remove временно пересчитывают Σ line_total до ответа сервера → после ответа applyCartData. Checkout.svelte уже передаёт `cartTotalRub` в PaymentMethodsSheet (сейчас только для промо-nudge).
- Amount: TbankAdapter `amount_kopecks = (order.final_amount * 100).to_i`; OrderCreator `final_amount = subtotal − promo_discount` → при промо cart.total ≠ Amount. Это G7 (вопрос на /spec), не баг.
- Utility денег с пробелом-разделителем тысяч нет (orderCancelFlow `Math.round` + ` ₽`, promoNudgeInsteadOf — String(round)) → новый общий formatter или расширить существующий — решить на /spec.
- Пересечение: PaymentMethodsSheet.svelte меняет TASK_100 (GREEN efb05433, до /review) — G4 держит его матрицу зелёной.
- G1/G2 файлов нет — создаются на RED.
- Baseline (--approve 2026-10-05 на `a8992dc9`): G3 SCOPE_OK · G4 45/0 (первый прогон в чекере exit=1 без падающего теста, повтор и ручной прогон 45/0 — флак, следить) · G5 0F/0E · G6 vite build OK.
-->
