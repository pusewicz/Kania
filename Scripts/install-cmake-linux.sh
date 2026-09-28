#!/usr/bin/env bash
# Installs a CMake new enough for Cute Framework (>= 4.2) into /opt/cmake on Linux.
# Prints the bin directory to add to PATH. Usage: eval "$(Scripts/install-cmake-linux.sh)" or
# PATH="$(Scripts/install-cmake-linux.sh):$PATH".
set -euo pipefail
VERSION="${CMAKE_VERSION:-4.4.3}"
ARCH="$(uname -m)"
case "$ARCH" in aarch64|arm64) ARCH=aarch64 ;; x86_64|amd64) ARCH=x86_64 ;; esac
DEST="${CMAKE_PREFIX:-/opt/cmake}"
if [ ! -x "$DEST/bin/cmake" ]; then
  mkdir -p "$DEST"
  curl -fsSL "https://github.com/Kitware/CMake/releases/download/v$VERSION/cmake-$VERSION-linux-$ARCH.tar.gz" \
    | tar -xz --strip-components=1 -C "$DEST"
fi
echo "$DEST/bin"
