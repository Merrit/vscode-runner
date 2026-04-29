#!/bin/bash

# Unique identifier, ideally a reverse-domain identifier.
# Should match the $identifier.service file for this runner.
identifier=codes.merritt.vscode_runner

# Name of this runner, should match the plasma-runner-$name.desktop file.
name=vscode_runner

# Stop the runner process.
kill "$(pidof $name)" &> /dev/null

# Ensure our working directory is the scripts directory.
cd "$(dirname "$0")" || exit

# Check for install location.
if [[ -n "$XDG_DATA_HOME" ]]
then
    dataHome="$XDG_DATA_HOME"
else
    dataHome=~/.local/share
fi

# Remove the executable & plugin files.
rm ~/.local/bin/$name
rm "$dataHome"/krunner/dbusplugins/plasma-runner-$name.desktop
rm "$dataHome"/dbus-1/services/$identifier.service

# Remove any old version that may be in the deprecated kservices5 directory.
deprecatedDesktopFile="$dataHome"/kservices5/krunner/dbusplugins/plasma-runner-$name.desktop
if [[ -f "$deprecatedDesktopFile" ]]
then
    rm "$deprecatedDesktopFile"
fi

# Close KRunner, it will start again when the hotkey is invoked.
kquitapp5 krunner
