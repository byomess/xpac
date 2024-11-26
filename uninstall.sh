#!/usr/bin/env bash

# Uninstall script for xpac

USER_SPACE_BIN_INSTALL_DIR="$HOME/.local/bin"
ROOT_SPACE_BIN_INSTALL_DIR="/usr/local/bin"
USER_SPACE_DATA_INSTALL_DIR="$HOME/.local/share"
ROOT_SPACE_DATA_INSTALL_DIR="/usr/local/share"

BIN_INSTALL_DIR=""
DATA_INSTALL_DIR=""

# Check if the script is running as root
RUNNING_AS_ROOT=false

if [ "$EUID" -eq 0 ]; then
    RUNNING_AS_ROOT=true
fi

# Set install directories based on user/root
if [ "$RUNNING_AS_ROOT" = true ]; then
    BIN_INSTALL_DIR="$ROOT_SPACE_BIN_INSTALL_DIR"
    DATA_INSTALL_DIR="$ROOT_SPACE_DATA_INSTALL_DIR"
else
    BIN_INSTALL_DIR="$USER_SPACE_BIN_INSTALL_DIR"
    DATA_INSTALL_DIR="$USER_SPACE_DATA_INSTALL_DIR"
fi

# Remove the xpac script
if [ -f "$BIN_INSTALL_DIR/xpac" ]; then
    echo "Removing xpac script from $BIN_INSTALL_DIR"
    rm "$BIN_INSTALL_DIR/xpac"
else
    echo "xpac script not found in $BIN_INSTALL_DIR"
fi

# Remove the xpac data directory
if [ -d "$DATA_INSTALL_DIR/xpac" ]; then
    echo "Removing xpac data from $DATA_INSTALL_DIR"
    rm -rf "$DATA_INSTALL_DIR/xpac"
else
    echo "xpac data not found in $DATA_INSTALL_DIR"
fi

# Check if the PATH was modified, and remove xpac from the PATH in rcfile if necessary
rcfile=""
if [ -f "$HOME/.bashrc" ]; then
    rcfile="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    rcfile="$HOME/.bash_profile"
elif [ -f "$HOME/.zshrc" ]; then
    rcfile="$HOME/.zshrc"
fi

if [ -n "$rcfile" ]; then
    # Check if PATH modification exists in the rcfile
    if grep -q "export PATH=\"$BIN_INSTALL_DIR:\$PATH\"" "$rcfile"; then
        echo "Removing $BIN_INSTALL_DIR from PATH in $rcfile"
        # Remove the line adding BIN_INSTALL_DIR to PATH
        sed -i "/export PATH=\"$BIN_INSTALL_DIR:\$PATH\"/d" "$rcfile"
        source "$rcfile"
    else
        echo "No PATH modification found in $rcfile"
    fi
else
    echo "No shell configuration file found to check for PATH modification."
fi

echo "xpac uninstalled successfully."
