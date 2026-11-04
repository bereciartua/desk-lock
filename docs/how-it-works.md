# How it works

## The idea

Every Mac keeps one long-lived HTTP connection open to a private ntfy server, subscribed to the topic `desk`. Anything that can send an HTTP request (Alfred, a terminal, an iPhone Shortcut) posts the word `sleep` or `screensaver` to that topic. The server passes it to every connected Mac, and each one runs the matching command locally.

```
                    ┌──────────── ntfy (Proxmox LXC) ────────────┐
Alfred on any Mac ─▶│  topic "desk"   auth: deny-all, token only │──▶ Mac 1 listener ─▶ pmset displaysleepnow
iPhone Shortcut  ──▶│                                            │──▶ Mac 2 listener ─▶ open -a ScreenSaverEngine
                    └────────────────────────────────────────────┘──▶ Mac 3 listener ─▶ …
```

| Command | What each Mac runs | Effect |
|---|---|---|
| `sleep` | `pmset displaysleepnow` | Displays turn off; locked if a password is required immediately |
| `screensaver` | `open -a ScreenSaverEngine` | Screen saver starts; same locking rule |

The listener is `desklock listen`, kept alive by a launch agent (`com.desklock.listener`). Triggers go through `desklock sleep` / `desklock screensaver`, which publish to the server.

## Why not SSH?

The first version used SSH from every Mac to every other Mac. Each Mac needed Remote Login turned on, keys exchanged, and a list of the other Macs' addresses. Adding a Mac meant visiting every machine.

With a shared channel, Macs never need to know about each other. Adding a Mac means running one install script on it.

Alternatives considered:

| Option | Why not |
|---|---|
| ntfy.sh public server | Works, free, but depends on a third party; topic name is the only protection unless you pay for reserved topics. Self-hosting gives proper auth. |
| Tailscale + Tailscale SSH | Removes the address list (peers are discoverable) and key management, but the Tailscale SSH server doesn't run in the regular Mac app, only the command-line build. More moving parts. |
| LAN broadcast | No server, but only works on one network, and macOS's Local Network permission makes background scripts unreliable. |
| Shared file in iCloud Drive | Sync can take seconds to minutes. |
| Proximity lock (e.g. BLEUnlock) | Automatic, but Bluetooth signal is jumpy (false or late locks) and offers no Sleep/Screen saver choice. Could complement this as a fallback. |

## Behaviour and limits

- **The Mac you trigger from locks too.** It receives its own message like the others.
- **If the server can't be reached** (not on your LAN or Tailscale), the trigger still locks the Mac you're on and shows a notification saying the others weren't reached.
- **If `desklock` isn't installed or set up** on a Mac, the Alfred commands lock only that Mac and show a notification.
- **Closed laptops don't catch up.** A Mac that was asleep when you sent `sleep` won't lock itself when you open it: old messages aren't replayed. (ntfy only replays messages from the same clock second the listener connects in.)
- **Right after waking, a Mac may miss commands for up to ~90 s.** Its old connection is dead but it doesn't know yet. The server sends a keepalive every 20 s; if the listener receives nothing for 90 s it reconnects.
- **Latency** is well under a second on the LAN.
- **Locking depends on a macOS setting**: Lock Screen → "Require password after screen saver begins or display is turned off" → Immediately. Without it, the screens go dark but stay unlocked.

## Security

- The server refuses everyone by default (`auth-default-access: deny-all`). Each client needs a token or a username and password.
- The `desklock` user (used by the Macs) can only read and write the `desk` topic.
- The listener acts only on the exact words `sleep` and `screensaver`. Anything else is logged and ignored. Someone holding a token can, at worst, lock your screens.
- On each Mac the token is in `~/.config/desklock/auth-header` (readable only by you) and is passed to `curl` from that file, so it doesn't show up in the process list.
- The server is only reachable on your LAN and Tailscale.
- With iPhone push notifications on, your server sends ntfy.sh only a message ID and a hash of the topic URL, never the message text. See [iphone.md](iphone.md#push-notifications).

## What was tested

Tested against a real ntfy 2.37 server (Debian 12 container) running the setup script:

- Setup script runs cleanly and is safe to re-run.
- Anonymous publishing is refused (403); a wrong token gets a clear "token rejected" message (401).
- `sleep` and `screensaver` reach the listener; other text is ignored.
- Server unreachable → only the local Mac locks, with a notification.
- A message sent 2–3 s before a listener connects is not replayed.
- Server frozen to simulate a dead connection after wake → listener reconnected after ~94 s and handled the next command.
- Alfred: each command's script runs the right action, with and without `desklock` installed; importing and running in Alfred was confirmed by hand.
