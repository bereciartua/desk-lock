#!/bin/bash
# Sets up desklock on this Mac. Run once per Mac:
#
#   ./install.sh --url https://ntfy.yourdomain.com --token tk_xxxxx [--topic desk]
#
# Re-running it is safe (updates the script and config, restarts the listener).
set -euo pipefail

URL="" TOKEN="" TOPIC="desk"
while [ $# -gt 0 ]; do
  case "$1" in
    --url)   URL="$2"; shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    --topic) TOPIC="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

CONF_DIR="$HOME/.config/desklock"
# Keep the existing config when re-running without arguments.
if [ -z "$URL" ] && [ -r "$CONF_DIR/config" ]; then
  # shellcheck source=/dev/null
  . "$CONF_DIR/config"; URL="$NTFY_URL"; TOPIC="${NTFY_TOPIC:-desk}"
fi
[ -n "$URL" ] || read -r -p "ntfy URL (e.g. https://ntfy.example.com): " URL
if [ -z "$TOKEN" ] && [ ! -r "$CONF_DIR/auth-header" ]; then
  read -r -s -p "Access token (tk_...): " TOKEN; echo
fi
URL="${URL%/}"

HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin/desklock"
LABEL="com.desklock.listener"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/desklock.log"

echo "==> Installing $BIN"
mkdir -p "$(dirname "$BIN")"
install -m 755 "$HERE/desklock" "$BIN"

echo "==> Writing config to $CONF_DIR"
mkdir -p "$CONF_DIR"
chmod 700 "$CONF_DIR"
printf 'NTFY_URL="%s"\nNTFY_TOPIC="%s"\n' "$URL" "$TOPIC" > "$CONF_DIR/config"
if [ -n "$TOKEN" ]; then
  (umask 077; printf 'Authorization: Bearer %s\n' "$TOKEN" > "$CONF_DIR/auth-header")
fi

echo "==> Checking connection"
"$BIN" check || echo "    (continuing; the listener retries until the server is reachable)"

echo "==> Installing launch agent $LABEL"
mkdir -p "$(dirname "$PLIST")" "$(dirname "$LOG")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string>
    <string>listen</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

cat <<EOF

Done. This Mac now responds to desk-lock commands.
  Log:        $LOG
  Test it:    $BIN screensaver
  Uninstall:  $HERE/uninstall.sh

Make sure System Settings > Lock Screen > "Require password after screen saver
begins or display is turned off" is set to "Immediately", or nothing gets locked.
EOF
