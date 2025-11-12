#!/usr/bin/env bash
set -euxo pipefail
echo "=== CI MARKER: USING vercel_build.sh ==="

# Pin Flutter (or set FLUTTER_VERSION in Vercel env)
FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.3}"
FLUTTER_HOME="/vercel/flutter-${FLUTTER_VERSION}"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

echo "=== Flutter version ==="
flutter --version

echo "=== Enable web target ==="
flutter config --enable-web

echo "=== Pub get ==="
flutter pub get

echo "=== Build web (release) ==="
flutter build web --release

echo "=== build/web (top 50) ==="
ls -la build/web | head -50

echo "✔ Build complete -> build/web"






