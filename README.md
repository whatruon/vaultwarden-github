# vaultwarden-github

Runs vaultwarden on a GitHub Actions runner, reachable over Tailscale. No dedicated server — just recurring jobs.

## How it works

- `.github/workflows/vaultwarden.yml` starts `vaultwarden/server:latest` in Docker on an `ubuntu-latest` runner.
- Tailscale joins the runner to your tailnet as hostname `vault` (`--ephemeral`, so the node auto-removes on disconnect), reachable at `vault.<tailnet>.ts.net`.
- The Tailscale TLS cert is cached in GitHub Actions cache and only renewed when it's missing or expiring within 30 days — avoids Let's Encrypt's duplicate-cert rate limit (5/week per domain).
- A loop checks the container every 60s and restarts it if it dies.
- GitHub-hosted jobs cap out at 6h, so a `schedule` cron fires a fresh run every 5h. `concurrency: cancel-in-progress: true` kills the old run once the new one starts — only one instance up at a time.

## Data

- Vaultwarden's database is external Postgres (Supabase) — survives every restart.
- Vaultwarden's local `/data` (attachments, RSA keys) is **not** persisted — it lives in the ephemeral runner and is wiped every ~5h restart. Fine for password data via sync; don't rely on file attachments/sends.

## Setup

Set repo secrets:

```
gh secret set TS_AUTHKEY -b"<tailscale auth key>"
gh secret set TS_API_KEY -b"<tailscale API access token>"
gh secret set TS_TAILNET -b"<tailnet name>"
gh secret set TS_CERT_DOMAIN -b"<vaultwarden.<tailnet>.ts.net>"
gh secret set VAULTWARDEN_DB_URL -b"<postgres connection string>"
```

Trigger manually via Actions tab (`workflow_dispatch`) or wait for the next scheduled run.

## Known limits

- No persistent `/data` volume — attachments/sends lost on restart.
- `vaultwarden/server:latest` is unpinned — can break on upstream image changes.
- Let's Encrypt allows only 5 certs/week for the same domain — the Actions cache avoids this, but if the cache is evicted (10 GB repo limit / 7-day no-access eviction) and a renewal is needed, the run may fail until the limit refills (1 per 34h).
- This is a workaround, not a real deployment. A small VPS with a persistent volume is more correct if uptime/data durability actually matter.
