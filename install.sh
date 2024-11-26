#!/usr/bin/env bash

# Script to install xpac

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

# Check if xpac is already installed
if [ -f "$BIN_INSTALL_DIR/xpac" ]; then
    echo "xpac is already installed in $BIN_INSTALL_DIR"
    echo "Reinstalling xpac"

    rm "$BIN_INSTALL_DIR/xpac"
    rm -rf "$DATA_INSTALL_DIR/xpac"
else
    echo "Installing xpac script in $BIN_INSTALL_DIR and data in $DATA_INSTALL_DIR"
fi

echo ""

# Check if the binary directory exists
if [ ! -d "$BIN_INSTALL_DIR" ]; then
    echo "Creating binary directory $BIN_INSTALL_DIR"
    mkdir -p "$BIN_INSTALL_DIR"
fi

# Check if the data directory exists
if [ ! -d "$DATA_INSTALL_DIR" ]; then
    echo "Creating data directory $DATA_INSTALL_DIR"
    mkdir -p "$DATA_INSTALL_DIR"
fi

# Copy the xpac.sh script and rename it to xpac (no .sh suffix)
echo "Copying xpac.sh to $BIN_INSTALL_DIR/xpac"
cp xpac.sh "$BIN_INSTALL_DIR/xpac"

# Ensure the 'internal_packages' directory exists in the correct location
INTERNAL_PACKAGES_DIR="$DATA_INSTALL_DIR/xpac/internal_packages"
if [ ! -d "$INTERNAL_PACKAGES_DIR" ]; then
    echo "Creating internal_packages directory in $INTERNAL_PACKAGES_DIR"
    mkdir -p "$INTERNAL_PACKAGES_DIR"
fi

# Check if the install path is in the PATH
if [[ ":$PATH:" != *":$BIN_INSTALL_DIR:"* ]]; then
    echo "$BIN_INSTALL_DIR is not in the PATH"

    rcfile=""
    if [ -f "$HOME/.bashrc" ]; then
        rcfile=".bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        rcfile=".bash_profile"
    elif [ -f "$HOME/.zshrc" ]; then
        rcfile=".zshrc"
    fi

    if [ -z "$rcfile" ]; then
        echo "No shell configuration file (.bashrc, .bash_profile, or .zshrc) found. PATH not updated."
    else
        echo "Adding $BIN_INSTALL_DIR to PATH in $HOME/$rcfile"
        echo "export PATH=\"$BIN_INSTALL_DIR:\$PATH\"" >>"$HOME/$rcfile"
        source "$HOME/$rcfile"
    fi
fi

# Make the xpac script executable
echo "Making xpac executable"
chmod +x "$BIN_INSTALL_DIR/xpac"

echo ""

echo "xpac successfully installed in $BIN_INSTALL_DIR"
echo "Run xpac --help to get started"
