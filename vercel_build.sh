#!/usr/bin/env bash
set -euxo pipefail
echo "=== CI MARKER: USING vercel_build.sh ==="

# Use Flutter 3.35.7 (bundles Dart >= 3.9)
FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.7}"
FLUTTER_HOME="/vercel/flutter-${FLUTTER_VERSION}"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="/vercel/.pub-cache"
mkdir -p "$PUB_CACHE"

echo "=== Flutter version ==="
flutter --version

echo "=== Precache web artifacts ==="
flutter precache --web

echo "=== Enable web target ==="
flutter config --enable-web

echo "=== Pub get ==="
flutter pub get

echo "=== Build web (release) ==="
flutter build web --release

echo "=== build/web (top 50) ==="
ls -la build/web | head -50
echo "✔ Build complete -> build/web"
