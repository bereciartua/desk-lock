# desk-lock

Lock every Mac at once when you leave your desk: from Alfred on any Mac, or from your iPhone, Watch or Siri.

```
Alfred / iPhone ──"sleep"──▶ ntfy on Proxmox ──▶ listener on every Mac ──▶ pmset displaysleepnow
```

Each Mac runs a small listener connected to a private [ntfy](https://ntfy.sh) server on your Proxmox box. Sending `sleep` or `screensaver` to that server makes every Mac react within a second. There's no SSH and no list of addresses: a new Mac only needs the server URL and a token.

## Quick start

| Step | Where | What | Details |
|---|---|---|---|
| 1 | Proxmox | Create a Debian LXC and run `server/setup-ntfy.sh https://ntfy.yourdomain.com`; it prints a token | [docs/server.md](docs/server.md) |
| 2 | Reverse proxy | Point the domain at `<lxc-ip>:2586` with response buffering off | [docs/server.md](docs/server.md#reverse-proxy) |
| 3 | Each Mac | `mac/install.sh --url https://ntfy.yourdomain.com --token tk_…`, and set Lock Screen to require a password **immediately** | [docs/mac.md](docs/mac.md) |
| 4 | Alfred | Double-click `alfred/Desk Lock.alfredworkflow` | [docs/alfred.md](docs/alfred.md) |
| 5 | iPhone (optional) | ntfy app to watch; a Shortcut to lock | [docs/iphone.md](docs/iphone.md) |

## Using it

| From | Do | Result |
|---|---|---|
| Alfred | `sleep all` ⏎ | **Sleep on All Computers** |
| Alfred | `screensaver all` ⏎ | **Screensaver on All Computers** |
| Alfred | `away` ⏎, then pick | Choose Sleep or Screen saver |
| Terminal | `~/.local/bin/desklock sleep` | Same as above |
| iPhone | "Sleep All Macs" Shortcut, Siri or Watch | Same as above |

## Docs

- [How it works](docs/how-it-works.md): architecture, why ntfy instead of SSH, behaviour and limits, security
- [Server](docs/server.md): Proxmox LXC, reverse proxy, updating, users and tokens
- [Macs](docs/mac.md): install, what gets installed, the `desklock` command, adding a Mac, uninstall
- [Alfred](docs/alfred.md): commands, customizing, rebuilding the workflow
- [iPhone](docs/iphone.md): ntfy app, push notifications, locking from Shortcuts, Siri and Watch
- [Troubleshooting](docs/troubleshooting.md)

## Repository layout

```
server/setup-ntfy.sh        installs and configures ntfy in a Debian LXC (safe to re-run)
mac/install.sh              sets up a Mac: command, config, launch agent
mac/desklock                the command: sleep | screensaver | listen | check
mac/uninstall.sh            removes everything from a Mac
alfred/Desk Lock.alfredworkflow   the Alfred workflow (built by build.py)
alfred/build.py             generates the workflow
docs/                       documentation
```

The repo is private and contains no secrets. Tokens and passwords live only on the server and in each Mac's `~/.config/desklock/`.
