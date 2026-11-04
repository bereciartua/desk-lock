#!/usr/bin/env bash
# Installs a private ntfy server for desk-lock.
# Run as root inside a fresh Debian 12/13 (or Ubuntu) LXC on Proxmox:
#
#   bash setup-ntfy.sh https://ntfy.yourdomain.com
#
# Prints an access token at the end. Use it with mac/install.sh on every Mac.
# Safe to re-run: rewrites server.yml (keeping a backup), keeps existing users
# and permissions, and prints a new token (old tokens keep working).
#
# Options (environment variables):
#   UPSTREAM=""   don't relay iPhone push notifications through ntfy.sh
set -euo pipefail

BASE_URL="${1:-}"
TOPIC="${TOPIC:-desk}"
NTFY_USER="${NTFY_USER:-desklock}"
UPSTREAM="${UPSTREAM-https://ntfy.sh}"

if [[ -z "$BASE_URL" ]]; then
  echo "usage: $0 https://ntfy.yourdomain.com" >&2
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
  echo "Run this as root." >&2
  exit 1
fi

echo "==> Installing ntfy from the official apt repository"
apt-get update -qq
apt-get install -y -qq curl ca-certificates >/dev/null
mkdir -p /etc/apt/keyrings
curl -fsSL -o /etc/apt/keyrings/ntfy.gpg https://archive.ntfy.sh/apt/keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ntfy.gpg] https://archive.ntfy.sh/apt stable main" \
  > /etc/apt/sources.list.d/ntfy.list
apt-get update -qq
apt-get install -y -qq ntfy >/dev/null

echo "==> Writing /etc/ntfy/server.yml"
if [[ -s /etc/ntfy/server.yml ]] && grep -qv '^\s*\(#\|$\)' /etc/ntfy/server.yml; then
  cp /etc/ntfy/server.yml "/etc/ntfy/server.yml.bak.$(date +%s)"
fi
cat > /etc/ntfy/server.yml <<EOF
# Managed by desk-lock setup-ntfy.sh
base-url: "$BASE_URL"
listen-http: ":2586"
behind-proxy: true

# Nobody can read or publish without a token.
auth-file: "/var/lib/ntfy/user.db"
auth-default-access: "deny-all"

# Frequent keepalives let the Macs notice a dead connection (e.g. after waking) quickly.
keepalive-interval: "20s"
EOF
if [[ -n "$UPSTREAM" ]]; then
  cat >> /etc/ntfy/server.yml <<EOF

# Lets the ntfy iPhone app get push notifications while it's closed.
# Only the message ID and a hash of the topic URL go to $UPSTREAM, never the
# message itself; the phone then fetches the message from this server.
upstream-base-url: "$UPSTREAM"
EOF
fi

# The package normally creates the ntfy user; make sure it exists anyway.
groupadd -f ntfy
id ntfy >/dev/null 2>&1 || useradd --system --no-create-home -g ntfy ntfy
mkdir -p /var/lib/ntfy
chown -R ntfy:ntfy /var/lib/ntfy
chmod 700 /var/lib/ntfy

echo "==> Starting ntfy"
systemctl enable ntfy >/dev/null 2>&1 || true
systemctl restart ntfy

# Wait for the server to create its auth database, so it stays owned by the ntfy user.
for _ in $(seq 1 30); do
  [[ -f /var/lib/ntfy/user.db ]] && break
  sleep 0.5
done
if [[ ! -f /var/lib/ntfy/user.db ]]; then
  echo "ntfy did not start. Check: journalctl -u ntfy" >&2
  exit 1
fi

as_ntfy() { runuser -u ntfy -- "$@"; }

echo "==> Creating user '$NTFY_USER' with access to topic '$TOPIC'"
if ! as_ntfy ntfy user list 2>&1 | grep -q "user $NTFY_USER "; then
  # The password is never used: the Macs authenticate with a token.
  NTFY_PASSWORD="$(head -c 24 /dev/urandom | base64)" as_ntfy ntfy user add "$NTFY_USER" >/dev/null
fi
as_ntfy ntfy access "$NTFY_USER" "$TOPIC" rw >/dev/null

TOKEN="$(as_ntfy ntfy token add --label="desk-lock" "$NTFY_USER" | grep -o 'tk_[A-Za-z0-9]*' | head -1)"
if [[ -z "$TOKEN" ]]; then
  echo "Could not create a token. Try: runuser -u ntfy -- ntfy token add $NTFY_USER" >&2
  exit 1
fi

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
cat <<EOF

Done. ntfy is listening on http://${IP:-<this-container>}:2586

Next:
  1. Point your reverse proxy at http://${IP:-<this-container>}:2586 for $BASE_URL
     (disable response buffering; see README).
  2. On each Mac run:

     ./install.sh --url $BASE_URL --token $TOKEN

Token (keep it private; the same token works on every Mac):
  $TOKEN
EOF
