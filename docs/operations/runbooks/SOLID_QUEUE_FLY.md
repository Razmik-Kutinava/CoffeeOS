# Solid Queue on Fly — CoffeeOS (TASK_93-J)

How callback/cascade/push jobs actually run in production.

## Two supported layouts

| Layout | How | When |
|--------|-----|------|
| **A. Puma plugin (current)** | `config/puma.rb`: `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]` · Fly/Kamal env `SOLID_QUEUE_IN_PUMA=true` (`config/deploy.yml`) | Single web machine; jobs share the web process |
| **B. Dedicated worker** | Separate Fly/Kamal process: `bin/jobs` / `solid_queue` always-on | Scale queue independently; web can set `SOLID_QUEUE_IN_PUMA` off |

Pick **one** always-on runner. Do **not** rely on a stopped worker with `SOLID_QUEUE_IN_PUMA` unset.

## Env checklist

- [ ] `SOLID_QUEUE_IN_PUMA=true` on **web** **or** a separate worker process is running
- [ ] Queue DB / `config.solid_queue.connects_to` reachable (see `config/environments/production.rb`)
- [ ] After deploy: Solid Queue heartbeats / `solid_queue_processes` not empty

## What breaks if neither runs

| Job / path | Effect |
|------------|--------|
| `Shop::OrderReadyCascadeJob` (`perform_later`) | Ready → SMS cascade **never** fires |
| `Shop::ReadyPushJob` / `SendPushNotificationJob` | FCM / wallet-ready path delayed forever |
| `Shop::AppleWallet::PassUpdateJob` | Wallet APNs updates stuck |
| Recurring / stuck-payment jobs (TASK_93-F) | Same queue — silent stall |

## Critical-path contracts (TASK_93-J R8)

| Path | Strategy |
|------|----------|
| **T‑Bank `notify`** | `perform_now` **primary** (request must finish payment update even if queue is down) |
| **Cascade SMS / ReadyPush / PassUpdate** | `perform_later` only — **requires** layout A or B above. No dual `perform_now` for SMS (avoids duplicate SMS under load) |

## Ops notes

- Local / test: `:test` / `:async` adapters — this runbook is for **Fly production-like**.
- Enabling a separate Fly `worker` process = **TASK_93-L** (deploy апрув), not block J DoD.
- If web autoscales to zero with only layout A — jobs die with the machine; prefer B for always-on SMS.

## Related

- `config/puma.rb` — Solid Queue plugin gate
- `config/deploy.yml` — `SOLID_QUEUE_IN_PUMA: true`
- Guest ready cascade: `Shop::OrderReadyCascadeJob` · grace + `SMS_GRACE_JOB_BUFFER`
