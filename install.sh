#!/bin/bash
#
# Quick install script for mt7925-bt-fix
# Run: curl -sSL https://raw.githubusercontent.com/rorar/mt7925-bt-fix/main/install.sh | bash
#

set -e

REPO_URL="https://github.com/rorar/mt7925-bt-fix"
INSTALL_DIR="/opt/mt7925-bt-fix"
BIN_PATH="/usr/local/bin/mt7925-bt-fix"

echo "MT7925 Bluetooth Fix Installer"
echo "==============================="
echo ""

# Check if we're running as root
if [[ $EUID -ne 0 ]]; then
	echo "This installer needs root privileges."
	echo "Please run: sudo bash $0"
	exit 1
fi

# Check for required commands
for cmd in git modprobe systemctl; do
	if ! command -v $cmd &>/dev/null; then
		echo "Error: '$cmd' is required but not installed."
		exit 1
	fi
done

# Clone or update repo
if [[ -d "$INSTALL_DIR" ]]; then
	echo "Updating existing installation..."
	cd "$INSTALL_DIR"
	git pull
else
	echo "Cloning repository..."
	git clone "$REPO_URL" "$INSTALL_DIR"
	cd "$INSTALL_DIR"
fi

# Make script executable
chmod +x mt7925-bt-fix.sh

# Run the install command
echo ""
echo "Running the fix installer..."
echo ""
./mt7925-bt-fix.sh install

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Reboot your system"
echo "  2. Check status: sudo $BIN_PATH status"
echo ""
