# Macs

## Install (once per Mac)

Get the repo onto the Mac (`gh repo clone bereciartua/desk-lock`, or copy the `mac/` folder over), then:

```bash
./mac/install.sh --url https://ntfy.yourdomain.com --token tk_xxxxxxxx
```

The token is the one `setup-ntfy.sh` printed. Without `--url` or `--token`, the script asks for them. Re-running it is safe: it updates the command and config and restarts the listener. Running it with no arguments keeps the existing URL and token (handy after pulling an updated `desklock`).

Then, **on each Mac**: System Settings → Lock Screen → "Require password after screen saver begins or display is turned off" → **Immediately**. Without this, the screens go dark but nothing is locked.

Check it works:

```bash
~/.local/bin/desklock check
```

```bash
~/.local/bin/desklock screensaver
```

## What gets installed

| Path | What |
|---|---|
| `~/.local/bin/desklock` | The command |
| `~/.config/desklock/config` | Server URL and topic |
| `~/.config/desklock/auth-header` | The token, readable only by you |
| `~/Library/LaunchAgents/com.desklock.listener.plist` | Keeps `desklock listen` running, restarts it if it stops |
| `~/Library/Logs/desklock.log` | Listener log |

Nothing needs admin rights, and SSH/Remote Login stays off.

## The `desklock` command

| Command | Does |
|---|---|
| `desklock sleep` | Turn off the displays on every Mac |
| `desklock screensaver` | Start the screen saver on every Mac |
| `desklock check` | Test the server connection and token |
| `desklock listen` | Wait for commands (the launch agent runs this; you don't need to) |

If the server can't be reached, or the Mac isn't set up yet, `sleep` and `screensaver` lock only this Mac and show a notification.

## Adding a new Mac

1. Install as above, with the same URL and token.
2. Import the Alfred workflow if your Alfred preferences don't sync.
3. Set the Lock Screen option.

Nothing changes on the other Macs or the server.

## Managing the listener

```bash
tail -f ~/Library/Logs/desklock.log                                   # watch it
launchctl print gui/$(id -u)/com.desklock.listener | grep state       # running?
launchctl kickstart -k gui/$(id -u)/com.desklock.listener             # restart it
```

## Changing the token or URL

```bash
./mac/install.sh --url https://ntfy.yourdomain.com --token tk_new
```

## Uninstall

```bash
./mac/uninstall.sh
```

Removes the launch agent, the command and the config. The log stays in `~/Library/Logs/desklock.log`.
