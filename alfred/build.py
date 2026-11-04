#!/usr/bin/env python3
"""Builds "Desk Lock.alfredworkflow". Keyword `away` -> Sleep / Screen Saver -> desklock."""
import json
import plistlib
import zipfile
from pathlib import Path

KEYWORD = "away"
FILTER_UID = "D35C0001-0000-4000-8000-000000000001"
ACTION_UID = "D35C0001-0000-4000-8000-000000000002"

items = {
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
filter_script = "cat <<'EOF'\n" + json.dumps(items, indent=1) + "\nEOF\n"
action_script = '"$HOME/.local/bin/desklock" "$1"\n'

info = {
    "bundleid": "com.desklock.alfred",
    "category": "Tools",
    "createdby": "desk-lock",
    "description": "Sleep or screen-save all your Macs at once",
    "disabled": False,
    "name": "Desk Lock",
    "readme": "Requires desklock installed on this Mac (mac/install.sh).",
    "version": "1.0",
    "webaddress": "",
    "objects": [
        {
            "type": "alfred.workflow.input.scriptfilter",
            "uid": FILTER_UID,
            "version": 3,
            "config": {
                "alfredfiltersresults": True,
                "alfredfiltersresultsmatchmode": 0,
                "argumenttreatemptyqueryasnil": True,
                "argumenttrimmode": 0,
                "argumenttype": 1,
                "escaping": 102,
                "keyword": KEYWORD,
                "queuedelaycustom": 3,
                "queuedelayimmediatelyinitially": True,
                "queuedelaymode": 0,
                "queuemode": 1,
                "runningsubtext": "",
                "script": filter_script,
                "scriptargtype": 1,
                "scriptfile": "",
                "subtext": "Sleep or screen-save every Mac",
                "title": "Lock all Macs",
                "type": 0,
                "withspace": True,
            },
        },
        {
            "type": "alfred.workflow.action.script",
            "uid": ACTION_UID,
            "version": 2,
            "config": {
                "concurrently": False,
                "escaping": 102,
                "script": action_script,
                "scriptargtype": 1,
                "scriptfile": "",
                "type": 0,
            },
        },
    ],
    "connections": {
        FILTER_UID: [
            {
                "destinationuid": ACTION_UID,
                "modifiers": 0,
                "modifiersubtext": "",
                "vitoclose": False,
            }
        ]
    },
    "uidata": {
        FILTER_UID: {"xpos": 50, "ypos": 50},
        ACTION_UID: {"xpos": 300, "ypos": 50},
    },
}

out = Path(__file__).parent / "Desk Lock.alfredworkflow"
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("info.plist", plistlib.dumps(info))
print(f"wrote {out}")
