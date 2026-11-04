#!/usr/bin/env python3
"""Builds "Desk Lock.alfredworkflow".

Commands:
  away                       -> pick Sleep / Screen saver
  Sleep on All Computers     -> one step (type "sleep all")
  Screensaver on All Computers -> one step (type "screensaver all")
"""
import json
import plistlib
import zipfile
from pathlib import Path

AWAY_KEYWORD = "away"
SLEEP_KEYWORD = "sleep all computers"
SAVER_KEYWORD = "screensaver all computers"

# Fixed UIDs so re-importing replaces the workflow instead of duplicating objects.
AWAY_FILTER = "D35C0001-0000-4000-8000-000000000001"
AWAY_ACTION = "D35C0001-0000-4000-8000-000000000002"
SLEEP_KW = "D35C0001-0000-4000-8000-000000000003"
SLEEP_ACTION = "D35C0001-0000-4000-8000-000000000004"
SAVER_KW = "D35C0001-0000-4000-8000-000000000005"
SAVER_ACTION = "D35C0001-0000-4000-8000-000000000006"

away_items = {
    "items": [
        {
            "uid": "sleep",
            "title": "Sleep displays on all Macs",
            "subtitle": "Turns off every screen (locks if a password is required)",
            "arg": "sleep",
            "match": "sleep displays lock",
        },
        {
            "uid": "screensaver",
            "title": "Start screen saver on all Macs",
            "subtitle": "Starts the screen saver everywhere",
            "arg": "screensaver",
            "match": "screensaver screen saver",
        },
    ]
}
away_filter_script = "cat <<'EOF'\n" + json.dumps(away_items, indent=1) + "\nEOF\n"


def run_script(command: str) -> str:
    """Bash for a Run Script action. `command` is `"$1"` or a literal sleep/screensaver."""
    return f"""cmd={command}
if [ -x "$HOME/.local/bin/desklock" ]; then
  exec "$HOME/.local/bin/desklock" "$cmd"
fi
# desklock not installed on this Mac yet: lock just this one.
osascript -e 'display notification "desklock is not installed (run mac/install.sh). Only this Mac was locked." with title "Desk Lock"'
case "$cmd" in
  sleep) pmset displaysleepnow ;;
  screensaver) open -a ScreenSaverEngine ;;
esac
"""


def script_action(uid: str, command: str) -> dict:
    return {
        "type": "alfred.workflow.action.script",
        "uid": uid,
        "version": 2,
        "config": {
            "concurrently": False,
            "escaping": 102,
            "script": run_script(command),
            "scriptargtype": 1,
            "scriptfile": "",
            "type": 0,
        },
    }


def keyword_input(uid: str, keyword: str, title: str, subtitle: str) -> dict:
    return {
        "type": "alfred.workflow.input.keyword",
        "uid": uid,
        "version": 1,
        "config": {
            "argumenttype": 2,  # no argument: runs as soon as you press Enter
            "keyword": keyword,
            "subtext": subtitle,
            "text": title,
            "withspace": False,
        },
    }


def link(dest: str) -> list:
    return [{"destinationuid": dest, "modifiers": 0, "modifiersubtext": "", "vitoclose": False}]


info = {
    "bundleid": "com.desklock.alfred",
    "category": "Tools",
    "createdby": "desk-lock",
    "description": "Sleep or screen-save all your Macs at once",
    "disabled": False,
    "name": "Desk Lock",
    "readme": (
        "away: pick Sleep or Screen saver.\n"
        "sleep all: Sleep on All Computers.\n"
        "screensaver all: Screensaver on All Computers.\n\n"
        "Requires desklock on this Mac (mac/install.sh). Without it, only this Mac is locked."
    ),
    "version": "1.1",
    "webaddress": "https://github.com/bereciartua/desk-lock",
    "objects": [
        {
            "type": "alfred.workflow.input.scriptfilter",
            "uid": AWAY_FILTER,
            "version": 3,
            "config": {
                "alfredfiltersresults": True,
                "alfredfiltersresultsmatchmode": 0,
                "argumenttreatemptyqueryasnil": True,
                "argumenttrimmode": 0,
                "argumenttype": 1,
                "escaping": 102,
                "keyword": AWAY_KEYWORD,
                "queuedelaycustom": 3,
                "queuedelayimmediatelyinitially": True,
                "queuedelaymode": 0,
                "queuemode": 1,
                "runningsubtext": "",
                "script": away_filter_script,
                "scriptargtype": 1,
                "scriptfile": "",
                "subtext": "Sleep or screen-save every Mac",
                "title": "Lock all Macs",
                "type": 0,
                "withspace": True,
            },
        },
        script_action(AWAY_ACTION, '"$1"'),
        keyword_input(SLEEP_KW, SLEEP_KEYWORD, "Sleep on All Computers",
                      "Turns off every Mac's screen"),
        script_action(SLEEP_ACTION, "sleep"),
        keyword_input(SAVER_KW, SAVER_KEYWORD, "Screensaver on All Computers",
                      "Starts the screen saver on every Mac"),
        script_action(SAVER_ACTION, "screensaver"),
    ],
    "connections": {
        AWAY_FILTER: link(AWAY_ACTION),
        SLEEP_KW: link(SLEEP_ACTION),
        SAVER_KW: link(SAVER_ACTION),
    },
    "uidata": {
        AWAY_FILTER: {"xpos": 50, "ypos": 50},
        AWAY_ACTION: {"xpos": 300, "ypos": 50},
        SLEEP_KW: {"xpos": 50, "ypos": 200},
        SLEEP_ACTION: {"xpos": 300, "ypos": 200},
        SAVER_KW: {"xpos": 50, "ypos": 350},
        SAVER_ACTION: {"xpos": 300, "ypos": 350},
    },
}

out = Path(__file__).parent / "Desk Lock.alfredworkflow"
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("info.plist", plistlib.dumps(info))
print(f"wrote {out}")
