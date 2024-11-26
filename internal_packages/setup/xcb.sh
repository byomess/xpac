#!/bin/bash

REPO_URL=https://github.com/byomess/xcb
INSTALLATION_SCRIPT_URL=$REPO_URL/raw/main/install.sh

echo "Remote installation script URL: $INSTALLATION_SCRIPT_URL"
echo "Attempting to fetch remote installation script..."

script=$(curl -sSL $INSTALLATION_SCRIPT_URL)

echo "Remote installation script fetched successfully"

if [ -z "$script" ]; then
	echo "Failed to fetch the installation script from $REPO_URL"
	echo "Attempting to install xcb using the local installation script..."
else
	echo "Executing remote installation script..."
	echo "$script" | bash -s "$@"
	exit 0
fi

# Local installation script --------------------------------------------

INSTALL_PATH="${1:-$HOME/.local}"

APP_HOME_DIR="$INSTALL_PATH/share"
APP_BIN_DIR="$INSTALL_PATH/bin"

APP_HOME="$APP_HOME_DIR/xcb"
APP_BIN="$APP_BIN_DIR/xcb"

if [ -d "$APP_HOME" ] || [ -f "$APP_BIN" ]; then
	echo "It seems that xcb is already installed at $APP_HOME"
	echo -n "Do you want to reinstall it? (y/n): "

	response=""

	read -r -n 1 response </dev/tty

	if [ "$response" != "y" ]; then
		exit 0
	else
		echo ""
		echo "Removing existing installation..."
		rm -rf $APP_HOME
		rm -f $APP_BIN
		echo "Done removing existing installation"
	fi
fi

mkdir -p $APP_HOME_DIR
mkdir -p $APP_BIN_DIR

temp_dir=$(mktemp -d)

echo "Cloning xcb from $REPO_URL to $temp_dir..."
git clone $REPO_URL $temp_dir --quiet

echo "Moving xcb files to $APP_HOME..."
mkdir -p $APP_HOME
cp -r $temp_dir/* $APP_HOME

echo "Creating symlink of $APP_HOME/xcb.sh at $APP_BIN..."
ln -s $APP_HOME/xcb.sh $APP_BIN

echo "Making xcb executable..."
chmod +x $APP_BIN

echo "Cleaning up..."
rm -rf $temp_dir

echo "Successfully installed xcb at $APP_HOME"

exit 0
