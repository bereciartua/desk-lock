# desk-lock

Lock every Mac at once from Alfred. Type `away`, pick **Sleep** or **Screen saver**, and every Mac reacts.

```
Alfred (any Mac) ──publish "sleep"──▶ ntfy on Proxmox ──▶ listener on every Mac ──▶ pmset displaysleepnow
```

There's no SSH and no address lists. Each Mac only knows the ntfy URL and a token, so adding a Mac means running one script on it.

## 1. Server (once): ntfy in a Proxmox LXC

1. Create a small **Debian 12 or 13 LXC**: 1 core, 256 MB RAM, 2 GB disk is plenty.
2. Copy `server/setup-ntfy.sh` into it and run it as root, with the URL you'll serve it on:

   ```bash
   bash setup-ntfy.sh https://ntfy.yourdomain.com
   ```

   It installs ntfy from the official apt repo, turns on auth (nobody gets in without a token), creates a `desklock` user allowed only on the `desk` topic, and **prints a token**. Running it again is safe; each run prints a new valid token.

3. **Reverse proxy**: point `ntfy.yourdomain.com` at `http://<lxc-ip>:2586`. The connection stays open, so response buffering must be off:

   - **Caddy**: `reverse_proxy <lxc-ip>:2586` works as is.
   - **Traefik**: works as is.
   - **nginx**: add `proxy_buffering off; proxy_http_version 1.1; proxy_read_timeout 3m;`
   - **Nginx Proxy Manager**: put those three lines under the host's *Advanced* tab.

   It only needs to be reachable on your LAN and Tailscale. Don't expose it to the internet.

## 2. Each Mac (once per Mac)

Copy the `mac/` folder over (AirDrop, iCloud Drive, whatever) and run:

```bash
./install.sh --url https://ntfy.yourdomain.com --token tk_xxxxxxxx
```

That installs:
- `~/.local/bin/desklock`, the command
- `~/.config/desklock/`, the URL and token (token file is readable only by you)
- a launch agent `com.desklock.listener` that keeps the listener running, logging to `~/Library/Logs/desklock.log`

Then, on each Mac: **System Settings → Lock Screen → "Require password after screen saver begins or display is turned off" → Immediately.** Without it, sleeping the displays doesn't lock anything.

Test from a terminal: `~/.local/bin/desklock check`, then `~/.local/bin/desklock screensaver`.

## 3. Alfred

Double-click `alfred/Desk Lock.alfredworkflow` to import it. Keyword: `away`. If your Alfred preferences sync between Macs, you only import it once. The workflow contains no secrets; it calls `desklock`, which reads the token from that Mac's config.

To change the keyword or add a hotkey, edit it in Alfred, or change `KEYWORD` in `alfred/build.py` and run `python3 alfred/build.py`.

## Behaviour worth knowing

- **The Mac you trigger from locks too**: it receives its own message, so there's no special case.
- **If the server can't be reached** (off your network and Tailscale), the trigger still locks the Mac you're on and shows a notification saying the others weren't reached.
- **Closed laptops don't catch up.** A Mac that was asleep when you sent `sleep` won't lock itself when you open it, because old messages aren't replayed.
- **Right after waking, a Mac may miss commands for up to ~90 s**, until the listener notices its old connection died and reconnects. Server keepalives every 20 s are what make that detection possible.
- **Only the words `sleep` and `screensaver` do anything.** Any other message is logged and ignored, so even someone holding the token can only lock your screens.

## Uninstall (per Mac)

```bash
./uninstall.sh
```

Revoke a token on the server: `runuser -u ntfy -- ntfy token remove desklock tk_...`
