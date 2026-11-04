#!/bin/bash
# Removes desklock from this Mac.
LABEL="com.desklock.listener"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist" "$HOME/.local/bin/desklock"
rm -rf "$HOME/.config/desklock"
echo "desklock removed. (Log left at ~/Library/Logs/desklock.log)"
