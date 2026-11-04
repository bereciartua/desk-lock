# iPhone

The iPhone can do two things: **watch** the `desk` topic in the ntfy app, and **lock the Macs** through an iOS Shortcut (which also gives you Siri, Apple Watch, the Action Button and Control Center).

The phone must be able to reach your server: on your home network, or with Tailscale on.

## 1. A user for the phone

The ntfy app signs in with a username and password, not a token. In the container:

```bash
runuser -u ntfy -- ntfy user add iphone           # asks for a password
```

```bash
runuser -u ntfy -- ntfy access iphone desk rw     # rw = watch and send; ro = watch only
```

## 2. The ntfy app (watching)

1. Install **ntfy** from the App Store.
2. Add your server: `https://ntfy.yourdomain.com`.
3. Subscribe to `desk` and sign in as `iphone`.

Every lock command now shows up on the phone. If that's noise, mute the topic in the app.

The app **can't send** commands. Its "send test notification" option sends its own text, which the Macs ignore. Use a Shortcut (below) or the web page.

## Push notifications

iOS only delivers notifications to a closed app through Apple's push service, which your server can't reach directly. The server config includes:

```yaml
upstream-base-url: "https://ntfy.sh"
```

With it, for each message your server sends ntfy.sh only the **message ID and a SHA-256 hash of the topic URL**, never the text. ntfy.sh asks Apple to wake the app, and the app fetches the real message from your server. If the phone can't reach your server at that moment, the notification just says "New message".

Without this line, messages only appear while the app is open. `setup-ntfy.sh` adds it by default (`UPSTREAM=` turns it off).

## 3. Locking from the phone: Shortcuts

### Create a token for Shortcuts

Shortcuts has no username/password field, so give it a token:

```bash
runuser -u ntfy -- ntfy token add --label=iphone-shortcuts iphone
```

### Build the shortcut

In the Shortcuts app, tap **+** and add the action **Get Contents of URL**:

| Field | Value |
|---|---|
| URL | `https://ntfy.yourdomain.com` (the server only, without `/desk`) |
| Method | POST |
| Headers | `Authorization` = `Bearer tk_…` |
| Request Body | JSON, with Text fields `topic` = `desk` and `message` = `sleep` |

Tap the arrow on the action to see Method, Headers and Request Body.

Name it **Sleep All Macs**. Duplicate it, change `message` to `screensaver`, and name the copy **Screensaver All Macs**.

This uses ntfy's JSON publishing (POST to the server root with the topic in the body), which is easier in Shortcuts than sending a plain-text body.

### Where to put it

| Place | How |
|---|---|
| Siri | Say the shortcut's name: "Sleep All Macs" |
| Apple Watch | Shortcut details → *Show on Apple Watch* |
| Home screen | Shortcut → Share → *Add to Home Screen* |
| Action Button | Settings → Action Button → Shortcut |
| Control Center | Edit Control Center → add a control → Shortcut |

### Test it from a Mac

The same request from a terminal, to check the token before building the shortcut:

```bash
curl -H "Authorization: Bearer tk_…" -d '{"topic":"desk","message":"screensaver"}' https://ntfy.yourdomain.com
```

## Alternative: the web page

Your server has a web interface. Open `https://ntfy.yourdomain.com` in Safari, sign in as `iphone`, open `desk`, and publish `sleep` or `screensaver`. No setup, but more taps than a Shortcut.
