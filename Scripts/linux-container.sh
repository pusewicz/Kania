#!/usr/bin/env bash
# Builds Kania with CMake inside the official Swift Linux image (native architecture), then runs
# the tests, HelloTriangle and the benchmark matrix under Xvfb with Mesa's lavapipe Vulkan driver.
# Writes Results/linux-<arch>.md and build/linux-<arch>/hello.png.
# Usage: Scripts/linux-container.sh [bench.rb options...]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${SWIFT_IMAGE:-swift:6.4-noble}"

# In a git worktree, .git is a file pointing into the main repository's .git directory. Mount that
# directory at its own path too, so git still finds the repository inside the container.
MOUNTS=(-v "$ROOT:/work")
GIT_COMMON="$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir)"
case "$GIT_COMMON" in "$ROOT"/*) ;; *) MOUNTS+=(-v "$GIT_COMMON:$GIT_COMMON") ;; esac

# --init: without an init process, xvfb-run ends up as PID 1 and hangs waiting for Xvfb to start.
docker run --rm --init "${MOUNTS[@]}" -w /work "$IMAGE" bash -c '
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null
  apt-get install -y -qq --no-install-recommends ninja-build ruby git curl ca-certificates xvfb xauth \
    libgl1-mesa-dri libvulkan1 mesa-vulkan-drivers pkg-config \
    libasound2-dev libpulse-dev libaudio-dev libjack-dev libsndio-dev libx11-dev libxext-dev libxrandr-dev \
    libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev libxkbcommon-dev libdrm-dev libgbm-dev \
    libgl1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev libdbus-1-dev libibus-1.0-dev libudev-dev \
    libpipewire-0.3-dev libwayland-dev libdecor-0-dev liburing-dev libxinerama-dev libssl-dev >/dev/null
  git config --global --add safe.directory "*"
  export PATH="$(bash Scripts/install-cmake-linux.sh):$PATH"
  swift --version
  build="build/linux-$(uname -m)"
  cmake --preset release -B "$build"
  cmake --build "$build"
  bin="$build/bin"
  export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
  xvfb-run -a -s "-screen 0 1280x960x24" sh -c "ctest --test-dir \"$build\" --output-on-failure &&
    \"$bin/HelloTriangle\" --frames 30 --screenshot \"$build/hello.png\" &&
    ruby Scripts/bench.rb --label linux-$(uname -m) --bin \"$bin\" --output Results/linux-$(uname -m).md \"\$@\"" \
    sh "$@"
' bash "$@"
