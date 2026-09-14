# Gates: <TASK_id or feature name>

Scope: <one sentence — observable deliverable for this CoffeeOS step>

- [ ] G1: unit/integration test for the change is green
  CHECK: bin/rails test path/to/test_file.rb
  EXPECT: 0 failures, 0 errors
  EVIDENCE: pending

- [ ] G2: zone regression from coffeeos-dev-gates / todo «Проверка»
  CHECK: bin/rails test path/to/zone_or_file.rb
  EXPECT: 0 failures, 0 errors
  EVIDENCE: pending

- [ ] G3: hot-path Fly MCP Point A (or explicit skip)
  EVIDENCE: pending

<!--
CoffeeOS notes:
- Replace placeholders. Prefer targeted test files (Windows: full shop suite hangs).
- Hot-path G3: manual — paste MCP artifact path + PASS/skip+reason into EVIDENCE.
- Non-hot-path: drop G3 or ABANDON: G3 not hot-path this step.
- Portable checks: repository Node scripts; declare --shell if needed.
- Commit-ops / SBR still apply. Checker proves oracles only.

ABANDON: G<n> <reason>
-->
