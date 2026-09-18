# Gates: TASK_93-B / #93 тАФ Checkout identity (phone vs email)

Scope: UI ┬л╨╝╨╛╨╢╨╜╨╛ ╨┐╨╗╨░╤В╨╕╤В╤М┬╗ тЙб ╨▒╤Н╨║╨╡╨╜╨┤ ╨┐╤А╨╕╨╜╨╕╨╝╨░╨╡╤В ╨╖╨░╨║╨░╨╖/╨╛╨┐╨╗╨░╤В╤Г ╨▒╨╡╨╖ 422 email ╨┐╤А╨╕ `phone_verified` (╨║╨░╨╜╨╛╨╜ phone-first R1тАУR5); ╨╛╨┤╨╕╨╜ identity ╨╜╨░ orders / new_card / one_click / SBP create. Deploy = TASK_93-L (╨╜╨╡ DoD ╨▒╨╗╨╛╨║╨░ B).

- [ ] G1: T-B2a..f тАФ OrderCreator + RecurrentOrderCreator (phone-only / email-only / neither)
  CHECK: ruby bin/rails test test/services/shop/order_creator_test.rb test/services/shop/recurrent_order_creator_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED тАФ `recurrent_order_creator_test.rb` ╨╛╤В╤Б╤Г╤В╤Б╤В╨▓╤Г╨╡╤В (InvalidTestError); T-B2a ╨╡╤Й╤С ╨╜╨╡ ╨╜╨░╨┐╨╕╤Б╨░╨╜; ╤Б╨╛╨╖╨┤╨░╤В╤М ╨╜╨░ `/sbr` RED

- [ ] G2: T-B5a..e + T-B4a тАФ integration checkout_identity (orders / cards / one_click ownership)
  CHECK: ruby bin/rails test test/integration/shop/api/checkout_identity_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: unmet pre-RED тАФ ╤Д╨░╨╣╨╗╨░ ╨╜╨╡╤В (InvalidTestError); ╤Б╨╛╨╖╨┤╨░╤В╤М ╨╜╨░ RED; phone тЖТ 2xx ╨▒╨╡╨╖ ┬л╨Я╨╛╨┤╤В╨▓╨╡╤А╨┤╨╕╤В╨╡ email┬╗; no identity тЖТ 422; ╤З╤Г╨╢╨░╤П ╨║╨░╤А╤В╨░ тЖТ ownership 422

- [x] G3: ╨╖╨╛╨╜╨░ shop pay-paths (╨в╨Ч ┬з8 + new_card)
  CHECK: ruby bin/rails test test/integration/shop/api/email_otp_checkout_test.rb test/integration/shop/shop_one_click_payment_step4_test.rb test/integration/shop/shop_new_card_payment_step2_test.rb
  EXPECT: 0 failures, 0 errors
  CWD: C:/Tools/workarea/CoffeeOS
  EVIDENCE: automatic-evidence=v1; definition-sha256=fbf78ac6552223e6ed94b6318bf8756327834caeeb578a41eae0ab122d3ecb9c; exit=0; EXPECT=matched; output-sha256=ece15702826475523ee350cb7709330b105562f54f2b8e67897a039046c63b65; output-bytes=1629; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS; path=54c8ad8163c5/77 entries тАФ baseline PASS ╨┤╨╛ ╨╕╨╖╨╝╨╡╨╜╨╡╨╜╨╕╨╣ B

- [ ] G4: T-B3 UI identityReady тЙб R1тАУR3 (phone-first, ╨╜╨╡ ╤В╤А╨╡╨▒╤Г╨╡╤В emailVerified ╨┤╨╗╤П Pay)
  EVIDENCE: pending тАФ manual/REVIEW: grep `identityReady` ╨▓ Checkout.svelte тЙб phoneVerified \|\| emailVerified (╨╕╨╗╨╕ phone-first derived); ╨▒╨╡╨╖ ╤Д╨╡╨╣╨║╨╛╨▓╨╛╨│╨╛ emailVerified; ╤Ж╨╕╤В╨░╤В╨░ ╨▓ GREEN-╨╛╤В╤З╤С╤В╨╡; JS unit ╨╡╤Б╨╗╨╕ ╨┐╨╛╤П╨▓╨╕╤В╤Б╤П runner

- [ ] G5: hot-path Fly MCP Point A тАФ phone Callcheck тЖТ Pay тЖТ order ╨▒╨╡╨╖ 422 email
  EVIDENCE: abandoned тАФ not DoD for TASK_93-B; reopen in TASK_93-L after deploy ╨░╨┐╤А╤Г╨▓; artifact `artifacts/critical_path_hardening/mcp/`; PASS = Point A tenant `2fdee1ac-4674-41ee-b89e-87b45643f789` ┬╖ phone_verified session тЖТ POST /orders 2xx ┬╖ Pay path ╨▒╨╡╨╖ ┬л╨Я╨╛╨┤╤В╨▓╨╡╤А╨┤╨╕╤В╨╡ email┬╗

ABANDON: G5 Fly MCP Point A is TASK_93-L DoD, not block B; Local G1тАУG3 + REVIEW G4 close B

<!--
CoffeeOS TASK_93-B unlazy (post-intake / pre-SPEC):
- ╨Ъ╨░╨╜╨╛╨╜ ╨в╨Ч: customer_tasks/TASK-93-B-Checkout-identity.md ┬з7тАУ9
- ╨Ч╨╡╤А╨║╨░╨╗╨╛: artifacts/critical_path_hardening/GATES.md
- ╨С╨╗╨╛╨║ A ledger: artifacts/critical_path_hardening/GATES-block-A.md
- Close B: G1тАУG3 met via --approve/--reverify after GREEN + /regress; G4 evidence ╨▓ REVIEW; G5 abandoned until L
- ╨Э╨╡ ╨│╨╕╨▒╤А╨╕╨┤: phone-first only (╨╜╨╡ email-gate)
- 2026-09-18 --approve: G3 met; G1/G2 unmet (missing test files); G4 manual; G5 abandoned
-->
