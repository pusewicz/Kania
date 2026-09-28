#!/usr/bin/env bash
# Builds Cute Framework as a static library for one target triple and collects the
# libraries, public headers and CMake's sample link line into Vendor/prebuilt/<triple>/.
# Usage: Scripts/build-cf.sh [triple]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRIPLE="${1:-${KANIA_TRIPLE:-}}"
if [ -z "$TRIPLE" ]; then
  case "$(uname -s)" in
    Darwin) TRIPLE="$(uname -m | sed 's/^aarch64$/arm64/')-apple-macosx" ;;
    Linux) TRIPLE="$(uname -m)-unknown-linux-gnu" ;;
    MINGW*|MSYS*|CYGWIN*) TRIPLE="x86_64-unknown-windows-msvc" ;;
    *) echo "unknown platform $(uname -s)" >&2; exit 1 ;;
  esac
fi
SRC="$ROOT/Vendor/cute_framework"
BUILD="$ROOT/Vendor/build/$TRIPLE"
OUT="$ROOT/Vendor/prebuilt/$TRIPLE"
[ -f "$SRC/CMakeLists.txt" ] || { echo "submodule missing: run git submodule update --init" >&2; exit 1; }

if [ "$(uname -s)" = Darwin ] && [ -z "${SDKROOT:-}" ]; then
  export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
fi

# CF must be built with MSVC on Windows to match the CRT and linker the Swift toolchain uses.
COMPILER_ARGS=()
case "$TRIPLE" in *windows-msvc) COMPILER_ARGS=(-DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl) ;; esac

PLATFORM_ARGS=()
[ "$(uname -s)" = Darwin ] && PLATFORM_ARGS=(-DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}")

echo "== configuring CF for $TRIPLE"
cmake -S "$SRC" -B "$BUILD" -G Ninja \
  ${COMPILER_ARGS[@]+"${COMPILER_ARGS[@]}"} \
  ${PLATFORM_ARGS[@]+"${PLATFORM_ARGS[@]}"} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCF_FRAMEWORK_STATIC=ON \
  -DCF_FRAMEWORK_BUILD_TESTS=OFF \
  -DCF_FRAMEWORK_BUILD_SAMPLES=ON \
  -DCF_BUILD_DOCSPARSER=OFF \
  -DCF_CUTE_SHADERC=OFF \
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
  ${CF_CMAKE_ARGS:-}

echo "== building libcute"
cmake --build "$BUILD" --target cute ${CF_EXTRA_TARGETS:-} --parallel

echo "== collecting into $OUT"
rm -rf "$OUT"
mkdir -p "$OUT/include/cute" "$OUT/lib"
cp "$SRC"/include/*.h "$OUT/include/"
find "$BUILD" -name 'cute_version.h' -exec cp {} "$OUT/include/" \; 2>/dev/null || true
# CF's public headers also include libraries/cute/*.h and the fetched Box2D/Box3D headers.
cp "$SRC"/libraries/cute/*.h "$OUT/include/cute/"
for dep in box2d box3d; do
  src_dir="$(find "$BUILD/_deps" -maxdepth 4 -type d -path "*include/$dep" | head -1)"
  if [ -n "$src_dir" ]; then mkdir -p "$OUT/include/$dep"; cp "$src_dir"/*.h "$OUT/include/$dep/"; fi
done
find "$BUILD" \( -name '*.a' -o -name '*.lib' \) -not -path '*CMakeFiles*' -exec cp {} "$OUT/lib/" \;
# Normalise "-static" suffixes (SDL3-static.lib, libphysfs-static.a) to one name per library.
for f in "$OUT"/lib/*-static.*; do
  [ -e "$f" ] || continue
  mv "$f" "$(echo "$f" | sed 's/-static\././')"
done

# Record the link line CMake uses for a CF sample, so Package.swift's platform libraries
# and frameworks can be checked against it.
grep -A10 -E '^build (samples/)?basicsprite(\.exe)?:' "$BUILD/build.ninja" \
  | grep -E 'LINK_LIBRARIES|LINK_FLAGS' > "$OUT/link.txt" || true
git -C "$SRC" rev-parse HEAD > "$OUT/cf-commit.txt"
echo "== done"; ls "$OUT/lib"; echo "-- link.txt:"; cat "$OUT/link.txt"
