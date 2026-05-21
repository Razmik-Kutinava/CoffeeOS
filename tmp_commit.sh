#!/bin/bash
cd /mnt/c/Tools/workarea/CoffeeOS

# Commit 1: role rename + RLS
git commit -m "fix: rename office_manager to general_manager, fix RLS policies"

# Stage audit log
git add app/models/admin_audit_log.rb app/controllers/barista/orders_controller.rb test/controllers/barista/orders_controller_test.rb

# Commit 2: audit log
git commit -m "feat: AdminAuditLog model and order cancel logging"

# Stage onboarding fix
git add app/controllers/platform/tenants_controller.rb app/services/platform/tenant_onboarding/ test/controllers/platform/ test/services/platform/

# Commit 3: onboarding atomicity
git commit -m "fix: wrap Provision.call in rescue for atomic tenant onboarding"

# Stage migrations
git add db/migrate/ db/cache_migrate/ db/cache_schema.rb

# Commit 4: migrations
git commit -m "chore: add migrations for audit logs, billing, loyalty, kitchen, solid cache"

# Stage docs
git add docs/ .cursor/CURSOR_RULES_REPORT.txt

# Commit 5: docs
git commit -m "docs: update qa_scenarios, product docs, agents rules"

# Stage remaining
git add .dockerignore .gitignore app/controllers/auth/ app/controllers/shop/ app/jobs/ config/initializers/rack_attack.rb lib/tasks/ test/integration/shop_tenant_subdomain_test.rb

# Commit 6: remaining
git commit -m "chore: update gitignore, rack_attack, shop api, telegram job, shop catalog task"

# Push
git push origin develop

echo "DONE"
