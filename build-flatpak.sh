#!/bin/bash
set -e

echo "=== Building Spot-Free Linux Flatpak (Version 0.5.1 Beta) ==="

FLATPAK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${FLATPAK_DIR}/.." && pwd)"
BUILD_DIR="/tmp/spot-free-flatpak-build"
REPO_DIR="/tmp/spot-free-flatpak-repo"

rm -rf "${BUILD_DIR}" "${REPO_DIR}"

# Ensure the native Linux binary is built
if [ ! -f "${APP_DIR}/target/debug/spot-free" ]; then
    (cd "${APP_DIR}" && cargo build)
fi

echo "1. Initializing Flatpak build directory (org.freedesktop.Platform//26.08)..."
flatpak build-init "${BUILD_DIR}" com.github.spot_free.SpotFree org.freedesktop.Sdk org.freedesktop.Platform 26.08

mkdir -p \
    "${BUILD_DIR}/files/bin" \
    "${BUILD_DIR}/files/share/applications" \
    "${BUILD_DIR}/files/share/metainfo" \
    "${BUILD_DIR}/files/share/icons/hicolor/scalable/apps" \
    "${BUILD_DIR}/files/share/icons/hicolor/256x256/apps"

echo "2. Packaging Spot-Free binary, bundled yt-dlp, desktop entry, metainfo, and icons..."
strip --strip-all "${APP_DIR}/target/debug/spot-free" -o "${BUILD_DIR}/files/bin/spot-free"
chmod 755 "${BUILD_DIR}/files/bin/spot-free"

# Bundle standalone yt-dlp zipapp so audio extraction works inside the Flatpak sandbox
curl -L -s -o "${BUILD_DIR}/files/bin/yt-dlp" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
chmod 755 "${BUILD_DIR}/files/bin/yt-dlp"

install -Dm644 "${FLATPAK_DIR}/com.github.spot_free.SpotFree.desktop" \
    "${BUILD_DIR}/files/share/applications/com.github.spot_free.SpotFree.desktop"
install -Dm644 "${FLATPAK_DIR}/com.github.spot_free.SpotFree.metainfo.xml" \
    "${BUILD_DIR}/files/share/metainfo/com.github.spot_free.SpotFree.metainfo.xml"
install -Dm644 "${FLATPAK_DIR}/com.github.spot_free.SpotFree.svg" \
    "${BUILD_DIR}/files/share/icons/hicolor/scalable/apps/com.github.spot_free.SpotFree.svg"
install -Dm644 "${FLATPAK_DIR}/com.github.spot_free.SpotFree.png" \
    "${BUILD_DIR}/files/share/icons/hicolor/256x256/apps/com.github.spot_free.SpotFree.png"

echo "3. Finalizing Flatpak sandbox permissions..."
flatpak build-finish "${BUILD_DIR}" \
    --command=spot-free \
    --socket=fallback-x11 \
    --socket=wayland \
    --device=dri \
    --socket=pulseaudio \
    --share=network \
    --share=ipc \
    --filesystem=xdg-music \
    --filesystem=xdg-download \
    --filesystem=home \
    --talk-name=org.freedesktop.Notifications

echo "4. Exporting OSTree repository and creating installable .flatpak bundle..."
flatpak build-export "${REPO_DIR}" "${BUILD_DIR}"
flatpak build-bundle "${REPO_DIR}" "${FLATPAK_DIR}/Spot-Free.flatpak" com.github.spot_free.SpotFree
cp -f "${FLATPAK_DIR}/Spot-Free.flatpak" "${FLATPAK_DIR}/spot-free.flatpak"

rm -rf "${BUILD_DIR}" "${REPO_DIR}"

echo "=== Successfully created ${FLATPAK_DIR}/Spot-Free.flatpak! ==="
echo "To install:"
echo "  flatpak install --user -y \"${FLATPAK_DIR}/Spot-Free.flatpak\""
