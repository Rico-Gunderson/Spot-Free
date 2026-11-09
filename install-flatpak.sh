#!/bin/bash
set -e

FLATPAK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="${FLATPAK_DIR}/Spot-Free.flatpak"

if [ ! -f "${BUNDLE}" ]; then
    "${FLATPAK_DIR}/build-flatpak.sh"
fi

echo "Installing Spot-Free (Version 0.5.1 Beta) Flatpak for current user..."
flatpak install --user -y --reinstall "${BUNDLE}"
echo "Spot-Free Flatpak installed! Run with: flatpak run com.github.spot_free.SpotFree"
