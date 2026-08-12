# vaultwarden-github

Runs vaultwarden on a GitHub Actions runner, reachable over Tailscale. No dedicated server — just recurring jobs.

## How it works

- `.github/workflows/vaultwarden.yml` starts `vaultwarden/server:latest` in Docker on an `ubuntu-latest` runner.
- Tailscale joins the runner to your tailnet (`--ephemeral`, so the node auto-removes on disconnect).
- A loop checks the container every 60s and restarts it if it dies.
- GitHub-hosted jobs cap out at 6h, so a `schedule` cron fires a fresh run every 5h. `concurrency: cancel-in-progress: true` kills the old run once the new one starts — only one instance up at a time.

## Data

- Vaultwarden's database is external Postgres (Supabase) — survives every restart.
- Vaultwarden's local `/data` (attachments, RSA keys) is **not** persisted — it lives in the ephemeral runner and is wiped every ~5h restart. Fine for password data via sync; don't rely on file attachments/sends.

## Setup

Set repo secrets:

```
gh secret set TS_AUTHKEY -b"<tailscale auth key>"
gh secret set VAULTWARDEN_DB_URL -b"<postgres connection string>"
```

Trigger manually via Actions tab (`workflow_dispatch`) or wait for the next scheduled run.

## Known limits

- No persistent `/data` volume — attachments/sends lost on restart.
- `vaultwarden/server:latest` is unpinned — can break on upstream image changes.
- This is a workaround, not a real deployment. A small VPS with a persistent volume is more correct if uptime/data durability actually matter.
