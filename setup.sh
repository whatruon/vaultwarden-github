#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null; then
  echo "gh CLI not found. Install: https://cli.github.com" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Not logged into gh. Logging in..."
  gh auth login
fi

read_secret() {
  local prompt="$1"
  local value
  read -r -s -p "$prompt: " value
  echo >&2
  echo "$value"
}

TS_AUTHKEY=$(read_secret "Tailscale reusable auth key")
TS_API_KEY=$(read_secret "Tailscale API access token")
TS_TAILNET=$(read_secret "Tailscale tailnet name")
TS_CERT_DOMAIN=$(read_secret "Tailscale cert domain (e.g. vaultwarden.<tailnet>.ts.net)")
VAULTWARDEN_DB_URL=$(read_secret "Vaultwarden postgres DATABASE_URL")

gh secret set TS_AUTHKEY -b"$TS_AUTHKEY"
gh secret set TS_API_KEY -b"$TS_API_KEY"
gh secret set TS_TAILNET -b"$TS_TAILNET"
gh secret set TS_CERT_DOMAIN -b"$TS_CERT_DOMAIN"
gh secret set VAULTWARDEN_DB_URL -b"$VAULTWARDEN_DB_URL"

echo "Secrets set. Running workflow..."
gh workflow run vaultwarden.yml
