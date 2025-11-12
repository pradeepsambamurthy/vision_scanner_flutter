#!/usr/bin/env bash
set -euxo pipefail
echo "=== CI MARKER: USING vercel_build.sh ==="

FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.7}"
FLUTTER_HOME="/vercel/flutter-${FLUTTER_VERSION}"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="/vercel/.pub-cache"
mkdir -p "$PUB_CACHE"

flutter --version
flutter precache --web
flutter config --enable-web
flutter pub get
flutter build web --release --pwa-strategy=none

ls -la build/web | head -50
echo "✔ Build complete -> build/web"
