#!/bin/bash

# Exit script if we encounter an error.
set -e

# Unique identifier, ideally a reverse-domain identifier.
# Should match the $identifier.service file for this runner.
identifier=codes.merritt.vscode_runner

# Name of this runner, should match the plasma-runner-$name.desktop file.
name=vscode_runner

# Ensure our working directory is the scripts directory.
cd "$(dirname "$0")"

# Check where to install.
if [[ -n "$XDG_DATA_HOME" ]]
then
    dataHome="$XDG_DATA_HOME"
else
    dataHome=~/.local/share
fi

# Make install directories in case they don't yet exist.
mkdir -p ~/.local/bin
mkdir -p "$dataHome"/krunner/dbusplugins/
mkdir -p "$dataHome"/dbus-1/services/

serviceFileName=$identifier.service
desktopFileName=plasma-runner-$name.desktop

# Install the runner's executable.
cp $name ~/.local/bin/$name

# Install the service file, adding the path to the runner's executable $name.
executableFullPath=$(readlink -m ~/.local/bin/$name)
cat $serviceFileName | sed "s|Exec=|Exec=$executableFullPath|" - > "$dataHome"/dbus-1/services/$serviceFileName

# Install the desktop file for KRunner to see the plugin.
cp $desktopFileName "$dataHome"/krunner/dbusplugins/$desktopFileName

# Close KRunner, it will start again when the hotkey is invoked.
kquitapp5 krunner
