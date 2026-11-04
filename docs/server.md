# Server: ntfy on Proxmox

All commands on this page run **as root inside the ntfy LXC** (Proxmox web UI → the container → Console), unless noted.

## Install

1. Create a **Debian 12 or 13 LXC**. 1 core, 256 MB RAM and 2 GB disk is plenty.
2. Get `server/setup-ntfy.sh` into the container (see [Getting the script into the container](#getting-the-script-into-the-container)).
3. Run it with the URL you'll serve ntfy on:

   ```bash
   bash setup-ntfy.sh https://ntfy.yourdomain.com
   ```

4. Save the **token** it prints at the end (e.g. in your password manager). Every Mac uses it.

### What the script does

- Installs ntfy from the official apt repository (`archive.ntfy.sh`).
- Writes `/etc/ntfy/server.yml`:

  ```yaml
  base-url: "https://ntfy.yourdomain.com"
  listen-http: ":2586"
  behind-proxy: true
  auth-file: "/var/lib/ntfy/user.db"
  auth-default-access: "deny-all"      # nobody gets in without credentials
  keepalive-interval: "20s"            # lets Macs detect dead connections quickly
  upstream-base-url: "https://ntfy.sh" # iPhone push notifications (see iphone.md)
  ```

- Starts ntfy as a systemd service.
- Creates the user `desklock` with read-write access to the topic `desk` only, and prints a token for it.

Options, as environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `UPSTREAM` | `https://ntfy.sh` | Set empty (`UPSTREAM= bash setup-ntfy.sh …`) to turn off iPhone push relaying |
| `TOPIC` | `desk` | Topic the Macs use |
| `NTFY_USER` | `desklock` | User the token belongs to |

## Reverse proxy

Point `ntfy.yourdomain.com` at `http://<lxc-ip>:2586`. The Macs keep a connection open indefinitely, so **response buffering must be off**:

| Proxy | Config |
|---|---|
| Caddy | `reverse_proxy <lxc-ip>:2586` works as is |
| Traefik | Works as is |
| nginx | `proxy_buffering off; proxy_http_version 1.1; proxy_read_timeout 3m;` |
| Nginx Proxy Manager | Put the nginx lines in the host's *Advanced* tab |

Keep it reachable only on your LAN and Tailscale; it doesn't need to be on the internet.

## Updating the server

**Re-running `setup-ntfy.sh` is safe.** It:

- rewrites `/etc/ntfy/server.yml`, saving the old one as `server.yml.bak.<timestamp>`
- keeps all users, permissions and tokens (they live in `/var/lib/ntfy/user.db`)
- restarts ntfy
- prints a new token; old tokens keep working, so the Macs need no changes

Any manual edits to `server.yml` are replaced (they remain in the backup).

For a one-line change, editing the file directly is quicker. Example, adding iPhone push relaying to a server set up before it was in the script:

```bash
grep -q '^upstream-base-url' /etc/ntfy/server.yml || echo 'upstream-base-url: "https://ntfy.sh"' >> /etc/ntfy/server.yml; systemctl restart ntfy && systemctl is-active ntfy
```

Don't add a key that's already in the file: a duplicate key stops ntfy from starting.

Update ntfy itself with `apt update && apt upgrade`.

## Users, tokens and permissions

ntfy's command-line tool edits `/var/lib/ntfy/user.db`. Run it as the `ntfy` user so file ownership stays correct:

```bash
runuser -u ntfy -- ntfy user list                     # users and their permissions
runuser -u ntfy -- ntfy user add iphone               # asks for a password
runuser -u ntfy -- ntfy user change-pass iphone
runuser -u ntfy -- ntfy user remove iphone

runuser -u ntfy -- ntfy access iphone desk rw         # rw = read and send; ro = read only
runuser -u ntfy -- ntfy access --reset iphone desk    # remove that permission

runuser -u ntfy -- ntfy token add --label=mac desklock      # new token
runuser -u ntfy -- ntfy token list desklock
runuser -u ntfy -- ntfy token remove desklock tk_...        # revoke
```

Current setup:

| User | Access | Used by |
|---|---|---|
| `desklock` | `desk` rw | Macs (token) |
| `iphone` | `desk` rw | ntfy iPhone app (password), Shortcuts (token) |

If a Mac is lost, revoke its token and give the others a new one (`mac/install.sh --token …` on each), or create one token per Mac from the start with `--label`.

## Getting the script into the container

The repo is private, so `curl` from GitHub won't work without credentials. Options:

- **Paste it**: open the file on GitHub, copy, and in the container run `cat > setup-ntfy.sh`, paste, then Ctrl-D.
- **From a Mac with `gh` logged in**, download it, copy it to the Proxmox host, then push it into the container from the host shell:

  ```bash
  gh api repos/bereciartua/desk-lock/contents/server/setup-ntfy.sh -H "Accept: application/vnd.github.raw" > setup-ntfy.sh
  ```

  ```bash
  pct push <container-id> setup-ntfy.sh /root/setup-ntfy.sh    # on the Proxmox host
  ```

## Logs

```bash
journalctl -u ntfy -f          # live
systemctl status ntfy
```
