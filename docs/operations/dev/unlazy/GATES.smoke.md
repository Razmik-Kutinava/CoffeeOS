# Gates: CoffeeOS unlazy install smoke

Scope: Prove vendor gate-check runs and install verifier prints success marker.

- [x] G1: install verifier prints success marker
  CHECK: node scripts/verify-install.mjs
  EXPECT: unlazy coffeeos install ok
  EVIDENCE: automatic-evidence=v1; definition-sha256=7d711ed7adf83633732be1fbacb8ce6e5b89c549f122e42926fd08a72baf9601; exit=0; EXPECT=matched; output-sha256=eb3ecf7bf93449e355c80354ec636bc46d26ddf57eec24accbfd467b63d82087; output-bytes=27; shell=C:\Windows\system32\cmd.exe; cwd=C:\Tools\workarea\CoffeeOS\docs\operations\dev\unlazy; path=54c8ad8163c5/77 entries
