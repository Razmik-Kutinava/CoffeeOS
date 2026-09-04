# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  # npm audit API can Net::ReadTimeout; retry then soft-skip transport only (real vulns still fail)
  step "Security: Importmap vulnerability audit", <<~SH.chomp
    set +e
    for i in 1 2 3; do
      out="$(bin/importmap audit 2>&1)"
      ec=$?
      printf '%s\\n' "$out"
      if [ "$ec" -eq 0 ]; then exit 0; fi
      if printf '%s' "$out" | grep -qE 'Net::ReadTimeout|Net::OpenTimeout|Unexpected transport error|SocketError'; then
        if [ "$i" -lt 3 ]; then
          echo "importmap audit transport error (attempt ${i}/3); retrying..."
          sleep $((i * 15))
          continue
        fi
        echo "npm audit API unreachable after 3 attempts; skipping (transport, not a vuln finding)"
        exit 0
      fi
      echo "importmap audit failed (non-transport)"
      exit "$ec"
    done
    exit 1
  SH
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: Rails", "bin/rails test"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: Run system tests
  # step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
