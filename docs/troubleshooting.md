# Troubleshooting

Start with these two on the Mac that isn't reacting:

```bash
~/.local/bin/desklock check
```

```bash
tail -20 ~/Library/Logs/desklock.log
```

## Other Macs don't react

| Symptom | Cause | Fix |
|---|---|---|
| `check` says "cannot reach" | Mac not on your LAN or Tailscale, or server down | Turn on Tailscale; on the server, `systemctl status ntfy` |
| `check` says "token was rejected" | Token revoked or mistyped | `./mac/install.sh --token tk_…` with a valid token |
| `check` is OK but nothing in the log | Listener not running | `launchctl kickstart -k gui/$(id -u)/com.desklock.listener` |
| Log shows `received 'sleep'` but screen stayed on | Unusual: `pmset` was blocked | Run `pmset displaysleepnow` by hand to see the error |
| Mac just woke up and missed it | Listener hadn't noticed its dead connection yet (up to ~90 s) | Expected; send again |
| Works on Wi-Fi at home, never on another network | Reverse proxy or DNS only on the LAN | Use Tailscale on that Mac |
| Log full of reconnects every ~90 s | Proxy buffering responses or cutting idle connections | Turn buffering off ([server.md](server.md#reverse-proxy)) |

## Screen goes dark but isn't locked

System Settings → Lock Screen → "Require password after screen saver begins or display is turned off" → **Immediately**. It's a per-Mac setting.

## Alfred

| Symptom | Fix |
|---|---|
| Only this Mac locked, with a "not installed" or "not set up" notification | Run `mac/install.sh` on this Mac |
| "Could not reach ntfy. Only this Mac was locked." | See "cannot reach" above |
| `sleep` put just this Mac to sleep | You picked macOS's built-in Sleep; use `sleep all` |
| Commands missing | Re-import `alfred/Desk Lock.alfredworkflow` |

## iPhone

| Symptom | Fix |
|---|---|
| App asks for username and password | Expected; sign in as `iphone` ([iphone.md](iphone.md)) |
| Notifications only while the app is open | `upstream-base-url` missing from `/etc/ntfy/server.yml` ([server.md](server.md#updating-the-server)) |
| Notification says only "New message" | Phone couldn't reach your server when it arrived; turn on Tailscale |
| Shortcut fails with 401/403 | Wrong token, or `iphone` lacks `rw` on `desk` (`runuser -u ntfy -- ntfy access iphone`) |
| Shortcut runs but Macs ignore it | Body must be exactly `sleep` or `screensaver`, and `topic` must be `desk` |

## Server

| Symptom | Fix |
|---|---|
| ntfy won't start after editing `server.yml` | Likely a duplicate key or YAML typo: `journalctl -u ntfy -n 30`; restore a `server.yml.bak.*` |
| `ntfy user …` commands fail with permission errors | Run them as the ntfy user: `runuser -u ntfy -- ntfy …` |
| Lost the token | Re-run `setup-ntfy.sh`, or `runuser -u ntfy -- ntfy token add desklock` |
